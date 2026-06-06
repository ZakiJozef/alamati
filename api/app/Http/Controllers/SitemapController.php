<?php

namespace App\Http\Controllers;

use App\Models\Store;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Response;

class SitemapController extends Controller
{
    public function index()
    {
        $stores = Store::where('is_open', true) // Optional: filter active stores
            ->orderBy('updated_at', 'desc')
            ->get();

        $products = \App\Models\Product::where('is_active', true)
            ->with('store')
            ->orderBy('updated_at', 'desc')
            ->get();

        $content = view('sitemap', compact('stores', 'products'))->render();

        // Optional: Write to static file for frontend
        $outputPath = env('SITEMAP_OUTPUT_PATH');
        if ($outputPath) {
            try {
                // Use base_path() to ensure we start from the project root
                // standard path: ../3alamati.com/sitemap.xml
                $fullPath = base_path($outputPath);
                file_put_contents($fullPath, $content);
            } catch (\Exception $e) {
                // Log error but don't fail the request
                \Log::error('Failed to write sitemap: ' . $e->getMessage());
            }
        }

        return Response::make($content, 200, [
            'Content-Type' => 'text/xml',
            'Cache-Control' => 'public, max-age=3600',
        ]);
    }
}
