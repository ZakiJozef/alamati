<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'sender_id',
        'receiver_id',
        'store_id',
        'content',
        'is_read',
        'sender_as_store',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'sender_as_store' => 'boolean',
    ];

    /**
     * Get the sender.
     */
    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    /**
     * Get the receiver.
     */
    public function receiver()
    {
        return $this->belongsTo(User::class, 'receiver_id');
    }

    /**
     * Get the store (if applicable).
     */
    public function store()
    {
        return $this->belongsTo(Store::class);
    }
}
