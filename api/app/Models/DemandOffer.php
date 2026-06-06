<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DemandOffer extends Model
{
    use HasFactory;

    protected $fillable = [
        'demand_id',
        'user_id',
        'store_id',
        'message',
        'proposed_price',
        'status',
    ];

    protected $casts = [
        'proposed_price' => 'float',
    ];

    protected $appends = ['time_ago'];

    public function demand()
    {
        return $this->belongsTo(Demand::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function getTimeAgoAttribute()
    {
        return $this->created_at->diffForHumans();
    }
}
