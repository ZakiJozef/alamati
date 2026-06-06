<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\LauncherController;
use App\Models\Store;
use App\Http\Controllers\SitemapController;

Route::get('/', function () {
    return view('welcome');
});

// Store page with Open Graph meta tags for social sharing
Route::get('/store/{slug}', function ($slug) {
    $store = Store::where('slug', $slug)->first();

    if (!$store) {
        // Try to find by ID if not found by slug
        if (is_numeric($slug)) {
            $store = Store::find($slug);
        }
    }

    if (!$store) {
        abort(404);
    }

    return view('store', compact('store'));
});

// Store products page with Open Graph meta tags for social sharing
Route::get('/store/{slug}/products', function ($slug) {
    $store = Store::where('slug', $slug)->first();

    if (!$store) {
        if (is_numeric($slug)) {
            $store = Store::find($slug);
        }
    }

    if (!$store) {
        abort(404);
    }

    return view('store-products', compact('store'));
});

Route::get('/sitemap.xml', [SitemapController::class, 'index']);

// Server Launcher Dashboard
Route::prefix('launcher')->group(function () {
    Route::get('/', [LauncherController::class, 'index']);
    Route::get('/network', [LauncherController::class, 'getNetworkInfo']);
    Route::get('/status', [LauncherController::class, 'getServerStatus']);
    Route::get('/constants', [LauncherController::class, 'getConstants']);
    Route::get('/scan-ports', [LauncherController::class, 'scanPorts']);
    Route::get('/flutter-devices', [LauncherController::class, 'getFlutterDevices']);
    Route::get('/adb-devices', [LauncherController::class, 'getAdbDevices']);
    Route::post('/start', [LauncherController::class, 'startServer']);
    Route::post('/stop', [LauncherController::class, 'stopServer']);
    Route::post('/kill-port', [LauncherController::class, 'killPort']);
    Route::post('/kill-process', [LauncherController::class, 'killProcess']);
    Route::post('/update-constants', [LauncherController::class, 'updateConstants']);
    Route::post('/adb-connect', [LauncherController::class, 'connectAdbDevice']);
    Route::post('/adb-disconnect', [LauncherController::class, 'disconnectAdbDevice']);
    Route::post('/flutter-launch', [LauncherController::class, 'launchFlutter']);
});

