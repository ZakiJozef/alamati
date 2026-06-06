<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Wilaya;
use App\Models\Commune;

class LocationController extends Controller
{
    public function wilayas()
    {
        return Wilaya::orderBy('id')->get();
    }

    public function communes(Wilaya $wilaya)
    {
        return $wilaya->communes()->orderBy('name')->get();
    }
}
