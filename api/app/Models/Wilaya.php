<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Wilaya extends Model
{
    protected $fillable = ['name', 'ar_name', 'code'];

    public function communes()
    {
        return $this->hasMany(Commune::class);
    }
}
