<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PortfolioItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'store_id',
        'title',
        'description',
        'image',
        'images',
    ];

    protected $casts = [
        'images' => 'array',
    ];

    /**
     * Get the store that owns this portfolio item.
     */
    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    /**
     * Get all images (combined legacy single image + new images array).
     */
    public function getAllImagesAttribute(): array
    {
        $allImages = [];

        // Add legacy single image if exists
        if ($this->image) {
            $allImages[] = $this->image;
        }

        // Add new images array
        if ($this->images && is_array($this->images)) {
            $allImages = array_merge($allImages, $this->images);
        }

        return array_unique($allImages);
    }

    protected $appends = ['all_images'];
}
