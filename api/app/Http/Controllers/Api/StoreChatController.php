<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageSent;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Store;
use App\Models\StoreEmployee;
use Illuminate\Http\Request;

class StoreChatController extends Controller
{
    /**
     * Check if user has access to store chat.
     */
    private function checkStoreAccess(Request $request, Store $store, string $permission = 'chat.read'): bool
    {
        $user = $request->user();

        // Store owner has full access
        if ($store->owner_id === $user->id) {
            return true;
        }

        // Check if user is an employee with the required permission
        $employee = StoreEmployee::where('store_id', $store->id)
            ->where('user_id', $user->id)
            ->first();

        if ($employee && $employee->hasPermission($permission)) {
            return true;
        }

        return false;
    }

    /**
     * Get store's conversations.
     */
    public function conversations(Request $request, Store $store)
    {
        if (!$this->checkStoreAccess($request, $store, 'chat.read')) {
            return response()->json(['message' => 'Access denied'], 403);
        }

        // Get all conversations involving this store
        $conversations = Conversation::where('store_id', $store->id)
            ->with(['user1:id,username,profile_pic,pseudoname', 'user2:id,username,profile_pic,pseudoname', 'lastMessage'])
            ->orderBy('updated_at', 'desc')
            ->get()
            ->map(function ($conversation) use ($store) {
                // Find the customer (the user who is NOT the store owner)
                $customer = $conversation->user1_id === $store->owner_id
                    ? $conversation->user2
                    : $conversation->user1;

                // Count unread messages sent by the customer to the store
                $unreadCount = Message::where('store_id', $store->id)
                    ->where('sender_id', $customer->id)
                    ->where('is_read', false)
                    ->count();

                return [
                    'id' => $conversation->id,
                    'customer_id' => $customer->id,
                    'customer_username' => $customer->username,
                    'customer_profile_pic' => $customer->profile_pic,
                    'customer_pseudoname' => $customer->pseudoname,
                    'last_message_content' => $conversation->lastMessage?->content,
                    'last_message_time' => $conversation->lastMessage?->created_at,
                    'last_message_sender_as_store' => $conversation->lastMessage?->sender_as_store ?? false,
                    'unread_count' => $unreadCount,
                    'updated_at' => $conversation->updated_at,
                ];
            });

        return response()->json($conversations);
    }

    /**
     * Get messages with a customer.
     */
    public function messages(Request $request, Store $store, $customerId)
    {
        if (!$this->checkStoreAccess($request, $store, 'chat.read')) {
            return response()->json(['message' => 'Access denied'], 403);
        }

        $limit = $request->input('limit', 50);
        $before = $request->input('before');

        // Get messages between store (owner) and customer for this store context
        $query = Message::where('store_id', $store->id)
            ->where(function ($q) use ($store, $customerId) {
                $q->where(function ($inner) use ($store, $customerId) {
                    $inner->where('sender_id', $store->owner_id)
                        ->where('receiver_id', $customerId);
                })->orWhere(function ($inner) use ($store, $customerId) {
                    $inner->where('sender_id', $customerId)
                        ->where('receiver_id', $store->owner_id);
                });
            })
            ->with(['sender:id,username,profile_pic', 'store:id,name,profile_image']);

        if ($before) {
            $query->where('id', '<', $before);
        }

        $messages = $query->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get()
            ->reverse()
            ->values()
            ->map(function ($message) use ($store) {
                return [
                    'id' => $message->id,
                    'sender_id' => $message->sender_id,
                    'receiver_id' => $message->receiver_id,
                    'store_id' => $message->store_id,
                    'content' => $message->content,
                    'is_read' => $message->is_read,
                    'sender_as_store' => $message->sender_as_store,
                    'created_at' => $message->created_at,
                    // If sent as store, show store info, otherwise show sender info
                    'display_name' => $message->sender_as_store
                        ? $store->name
                        : $message->sender->username,
                    'display_image' => $message->sender_as_store
                        ? $store->profile_image
                        : $message->sender->profile_pic,
                ];
            });

        return response()->json($messages);
    }

    /**
     * Send a message as the store.
     */
    public function sendMessage(Request $request, Store $store)
    {
        if (!$this->checkStoreAccess($request, $store, 'chat.reply')) {
            return response()->json(['message' => 'Access denied'], 403);
        }

        $validated = $request->validate([
            'receiver_id' => 'required|integer|exists:users,id',
            'content' => 'required|string|max:5000',
        ]);

        $userId = $request->user()->id;

        // Create the message (sender is the actual user, but marked as store)
        $message = Message::create([
            'sender_id' => $userId,
            'receiver_id' => $validated['receiver_id'],
            'store_id' => $store->id,
            'content' => $validated['content'],
            'is_read' => false,
            'sender_as_store' => true,
        ]);

        // Update or create conversation
        $user1 = min($store->owner_id, $validated['receiver_id']);
        $user2 = max($store->owner_id, $validated['receiver_id']);

        Conversation::updateOrCreate(
            ['user1_id' => $user1, 'user2_id' => $user2, 'store_id' => $store->id],
            ['last_message_id' => $message->id]
        );

        // Load relationships for response
        $message->load(['sender:id,username,profile_pic', 'store:id,name,profile_image']);

        // Broadcast the message
        broadcast(new MessageSent($message))->toOthers();

        return response()->json([
            'id' => $message->id,
            'sender_id' => $message->sender_id,
            'receiver_id' => $message->receiver_id,
            'store_id' => $message->store_id,
            'content' => $message->content,
            'is_read' => $message->is_read,
            'sender_as_store' => $message->sender_as_store,
            'created_at' => $message->created_at,
            'display_name' => $store->name,
            'display_image' => $store->profile_image,
        ], 201);
    }

    /**
     * Mark messages from a customer as read.
     */
    public function markRead(Request $request, Store $store, $customerId)
    {
        if (!$this->checkStoreAccess($request, $store, 'chat.read')) {
            return response()->json(['message' => 'Access denied'], 403);
        }

        Message::where('store_id', $store->id)
            ->where('sender_id', $customerId)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json(['success' => true]);
    }

    /**
     * Get unread message count for a store.
     */
    public function unreadCount(Request $request, Store $store)
    {
        if (!$this->checkStoreAccess($request, $store, 'chat.read')) {
            return response()->json(['message' => 'Access denied'], 403);
        }

        $count = Message::where('store_id', $store->id)
            ->where('receiver_id', $store->owner_id)
            ->where('is_read', false)
            ->count();

        return response()->json(['unread' => $count]);
    }
}
