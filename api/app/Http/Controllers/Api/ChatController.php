<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageSent;
use App\Events\MessagesRead;
use App\Events\UserTyping;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChatController extends Controller
{
    /**
     * Get user's conversations.
     */
    public function conversations(Request $request)
    {
        $userId = $request->user()->id;

        $conversations = Conversation::where('user1_id', $userId)
            ->orWhere('user2_id', $userId)
            ->with(['user1:id,username,profile_pic,pseudoname', 'user2:id,username,profile_pic,pseudoname', 'store:id,name,profile_image', 'lastMessage'])
            ->orderBy('updated_at', 'desc')
            ->get()
            ->map(function ($conversation) use ($userId) {
                $otherUser = $conversation->user1_id === $userId
                    ? $conversation->user2
                    : $conversation->user1;

                // Count unread messages
                $unreadCount = Message::where('sender_id', $otherUser->id)
                    ->where('receiver_id', $userId)
                    ->where('is_read', false)
                    ->count();

                return [
                    'id' => $conversation->id,
                    'other_user_id' => $otherUser->id,
                    'other_username' => $otherUser->username,
                    'other_profile_pic' => $otherUser->profile_pic,
                    'other_pseudoname' => $otherUser->pseudoname,
                    'store_name' => $conversation->store?->name,
                    'store_image' => $conversation->store?->profile_image,
                    'last_message_content' => $conversation->lastMessage?->content,
                    'last_message_time' => $conversation->lastMessage?->created_at,
                    'unread_count' => $unreadCount,
                    'updated_at' => $conversation->updated_at,
                ];
            });

        return response()->json($conversations);
    }

    /**
     * Get messages with another user.
     */
    public function messages(Request $request, $otherUserId)
    {
        $userId = $request->user()->id;
        $limit = $request->input('limit', 50);
        $before = $request->input('before');

        $query = Message::where(function ($q) use ($userId, $otherUserId) {
            $q->where('sender_id', $userId)->where('receiver_id', $otherUserId);
        })
            ->orWhere(function ($q) use ($userId, $otherUserId) {
                $q->where('sender_id', $otherUserId)->where('receiver_id', $userId);
            })
            ->with('sender:id,username,profile_pic');

        if ($before) {
            $query->where('id', '<', $before);
        }

        $messages = $query->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get()
            ->reverse()
            ->values()
            ->map(function ($message) {
                return [
                    'id' => $message->id,
                    'sender_id' => $message->sender_id,
                    'receiver_id' => $message->receiver_id,
                    'store_id' => $message->store_id,
                    'content' => $message->content,
                    'is_read' => $message->is_read,
                    'created_at' => $message->created_at,
                    'sender_username' => $message->sender->username,
                    'sender_profile_pic' => $message->sender->profile_pic,
                ];
            });

        // Mark messages as read
        Message::where('sender_id', $otherUserId)
            ->where('receiver_id', $userId)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json($messages);
    }

    /**
     * Send a message.
     */
    public function sendMessage(Request $request)
    {
        $validated = $request->validate([
            'receiver_id' => 'required|integer|exists:users,id',
            'content' => 'required|string|max:5000',
            'store_id' => 'nullable|integer|exists:stores,id',
        ]);

        $userId = $request->user()->id;

        // Create the message
        $message = Message::create([
            'sender_id' => $userId,
            'receiver_id' => $validated['receiver_id'],
            'store_id' => $validated['store_id'] ?? null,
            'content' => $validated['content'],
            'is_read' => false,
        ]);

        // Update or create conversation
        $user1 = min($userId, $validated['receiver_id']);
        $user2 = max($userId, $validated['receiver_id']);

        Conversation::updateOrCreate(
            ['user1_id' => $user1, 'user2_id' => $user2],
            [
                'store_id' => $validated['store_id'] ?? null,
                'last_message_id' => $message->id,
            ]
        );

        // Load sender info for broadcast
        $message->load('sender:id,username,profile_pic,pseudoname');

        // Broadcast the message
        broadcast(new MessageSent($message))->toOthers();

        return response()->json([
            'id' => $message->id,
            'sender_id' => $message->sender_id,
            'receiver_id' => $message->receiver_id,
            'store_id' => $message->store_id,
            'content' => $message->content,
            'is_read' => $message->is_read,
            'created_at' => $message->created_at,
            'sender_username' => $message->sender->username,
            'sender_profile_pic' => $message->sender->profile_pic,
        ], 201);
    }

    /**
     * Get unread message count.
     */
    public function unreadCount(Request $request)
    {
        $count = Message::where('receiver_id', $request->user()->id)
            ->where('is_read', false)
            ->count();

        return response()->json(['unread' => $count]);
    }

    /**
     * Mark messages from a user as read.
     */
    public function markRead(Request $request, $otherUserId)
    {
        $userId = $request->user()->id;

        Message::where('sender_id', $otherUserId)
            ->where('receiver_id', $userId)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        // Broadcast read receipt
        broadcast(new MessagesRead($userId, (int) $otherUserId));

        return response()->json(['success' => true]);
    }

    /**
     * Send typing indicator.
     */
    public function typing(Request $request)
    {
        $validated = $request->validate([
            'receiver_id' => 'required|integer|exists:users,id',
            'is_typing' => 'required|boolean',
        ]);

        $user = $request->user();

        broadcast(new UserTyping(
            $user->id,
            $user->username,
            $validated['receiver_id'],
            $validated['is_typing']
        ));

        return response()->json(['success' => true]);
    }
}
