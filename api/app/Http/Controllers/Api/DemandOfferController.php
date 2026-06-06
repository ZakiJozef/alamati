<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Demand;
use App\Models\DemandOffer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DemandOfferController extends Controller
{
    /**
     * Create an offer on a demand
     */
    public function store(Request $request, $demandId)
    {
        $demand = Demand::findOrFail($demandId);

        // Prevent users from making offers on their own demands
        if ($demand->user_id === Auth::id()) {
            return response()->json(['error' => 'You cannot make an offer on your own demand'], 400);
        }

        // Check if demand is still open
        if ($demand->status !== 'open') {
            return response()->json(['error' => 'This demand is no longer accepting offers'], 400);
        }

        // Check if user already made an offer
        $existingOffer = DemandOffer::where('demand_id', $demandId)
            ->where('user_id', Auth::id())
            ->first();

        if ($existingOffer) {
            return response()->json(['error' => 'You have already made an offer on this demand'], 400);
        }

        $request->validate([
            'message' => 'required|string',
            'proposed_price' => 'nullable|numeric|min:0',
            'store_id' => 'nullable|exists:stores,id',
        ]);

        $offer = DemandOffer::create([
            'demand_id' => $demandId,
            'user_id' => Auth::id(),
            'store_id' => $request->store_id,
            'message' => $request->message,
            'proposed_price' => $request->proposed_price,
            'status' => 'pending',
        ]);

        return response()->json(
            $offer->load(['user:id,username,profile_pic', 'store:id,name,profile_image']),
            201
        );
    }

    /**
     * Get offers for a demand
     */
    public function index($demandId)
    {
        $offers = DemandOffer::with(['user:id,username,profile_pic', 'store:id,name,profile_image'])
            ->where('demand_id', $demandId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($offers);
    }

    /**
     * Update an offer (only by owner, only when pending)
     */
    public function update(Request $request, $offerId)
    {
        $offer = DemandOffer::where('user_id', Auth::id())->findOrFail($offerId);

        // Can only edit pending offers
        if ($offer->status !== 'pending') {
            return response()->json(['error' => 'Cannot edit an offer that has already been accepted or rejected'], 400);
        }

        $request->validate([
            'message' => 'sometimes|string',
            'proposed_price' => 'nullable|numeric|min:0',
        ]);

        $offer->update($request->only(['message', 'proposed_price']));

        return response()->json($offer->load(['user:id,username,profile_pic', 'store:id,name,profile_image']));
    }

    /**
     * Delete an offer (only by owner, only when pending)
     */
    public function destroy($offerId)
    {
        $offer = DemandOffer::where('user_id', Auth::id())->findOrFail($offerId);

        // Can only delete pending offers
        if ($offer->status !== 'pending') {
            return response()->json(['error' => 'Cannot delete an offer that has already been accepted or rejected'], 400);
        }

        $offer->delete();

        return response()->json(['message' => 'Offer deleted successfully']);
    }


    /**
     * Accept an offer (demand owner only)
     */
    public function accept($offerId)
    {
        $offer = DemandOffer::with('demand')->findOrFail($offerId);

        // Check if current user owns the demand
        if ($offer->demand->user_id !== Auth::id()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $offer->update(['status' => 'accepted']);

        // Change demand status to in_process when an offer is accepted
        $offer->demand->update(['status' => 'in_process']);

        return response()->json($offer->load(['user:id,username,profile_pic', 'store:id,name,profile_image']));
    }

    /**
     * Reject an offer (demand owner only)
     */
    public function reject($offerId)
    {
        $offer = DemandOffer::with('demand')->findOrFail($offerId);

        // Check if current user owns the demand
        if ($offer->demand->user_id !== Auth::id()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $offer->update(['status' => 'rejected']);

        return response()->json($offer->load(['user:id,username,profile_pic', 'store:id,name,profile_image']));
    }

    /**
     * Get user's submitted offers
     */
    public function myOffers()
    {
        $offers = DemandOffer::with(['demand', 'store:id,name,profile_image'])
            ->where('user_id', Auth::id())
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($offers);
    }
}
