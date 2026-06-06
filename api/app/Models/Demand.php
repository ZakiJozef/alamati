<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Demand extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'phone',
        'wilaya_id',
        'commune_id',
        'wilaya',
        'commune',
        'latitude',
        'longitude',
        'images',
        'service_category',
        'service_type',
        'service_category_id',
        'status',
        'is_anonymous',
        'expires_at',
    ];

    protected $casts = [
        'images' => 'array',
        'latitude' => 'float',
        'longitude' => 'float',
        'is_anonymous' => 'boolean',
        'expires_at' => 'datetime',
        'wilaya_id' => 'integer',
        'commune_id' => 'integer',
        'service_category_id' => 'integer',
    ];

    protected $appends = ['offers_count', 'time_ago', 'wilaya_name', 'commune_name'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function offers()
    {
        return $this->hasMany(DemandOffer::class);
    }

    public function wilayaRelation()
    {
        return $this->belongsTo(Wilaya::class, 'wilaya_id');
    }

    public function communeRelation()
    {
        return $this->belongsTo(Commune::class, 'commune_id');
    }

    public function getWilayaNameAttribute()
    {
        return $this->wilayaRelation?->name ?? $this->wilaya;
    }

    public function getCommuneNameAttribute()
    {
        return $this->communeRelation?->name ?? $this->commune;
    }

    public function getOffersCountAttribute()
    {
        return $this->offers()->count();
    }

    public function getTimeAgoAttribute()
    {
        return $this->created_at->diffForHumans();
    }

    public function scopeOpen($query)
    {
        return $query->where('status', 'open');
    }

    public function scopeByCategory($query, $category)
    {
        if ($category) {
            return $query->where('service_category', $category);
        }
        return $query;
    }

    public function scopeByWilaya($query, $wilayaId)
    {
        if ($wilayaId) {
            return $query->where('wilaya_id', $wilayaId);
        }
        return $query;
    }
}

