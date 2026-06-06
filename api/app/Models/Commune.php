<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Commune extends Model
{
    protected $fillable = ['wilaya_id', 'name', 'ar_name', 'post_code'];

    public function wilaya()
    {
        return $this->belongsTo(Wilaya::class);
    }
}
