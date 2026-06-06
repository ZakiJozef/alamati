<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Connection extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'connected_user_id',
        'status',
    ];

    /**
     * Get the user who sent the connection request.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the connected user.
     */
    public function connectedUser()
    {
        return $this->belongsTo(User::class, 'connected_user_id');
    }
}
