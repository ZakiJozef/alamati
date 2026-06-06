<?php
/**
 * TEMPORARY ADMIN SCRIPT - DELETE AFTER USE!
 * 
 * This script:
 * 1. Updates existing ui-avatars.com URLs to DiceBear
 * 2. Clears Laravel caches
 * 
 * Upload to: /home/bc2024bc/api.3alamati.com/public/fix-avatars-temp.php
 * Access via: https://api.3alamati.com/fix-avatars-temp.php
 * DELETE IMMEDIATELY AFTER RUNNING!
 */

// Security check - remove this line after verifying it works
$secret = $_GET['key'] ?? '';
if ($secret !== 'fix3alamati2026') {
    http_response_code(403);
    die('Access denied. Add ?key=fix3alamati2026 to URL');
}

require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "<pre style='font-family: monospace; background: #1e1e1e; color: #00ff00; padding: 20px;'>";
echo "=== 3ALAMATI DATABASE & CACHE FIX ===\n\n";

// 1. Fix avatar URLs in users table
echo "1. Updating avatar URLs...\n";
try {
    $updated = DB::update("
        UPDATE users 
        SET profile_pic = REPLACE(
            REPLACE(profile_pic, 'https://ui-avatars.com/api/?name=', 'https://api.dicebear.com/7.x/initials/svg?seed='),
            '&background=', '&backgroundColor='
        )
        WHERE profile_pic LIKE '%ui-avatars.com%'
    ");
    echo "   ✓ Updated $updated user avatar(s)\n\n";
} catch (Exception $e) {
    echo "   ✗ Error: " . $e->getMessage() . "\n\n";
}

// 2. Clear all caches
echo "2. Clearing caches...\n";

try {
    Artisan::call('config:clear');
    echo "   ✓ Config cache cleared\n";
} catch (Exception $e) {
    echo "   ✗ Config clear failed: " . $e->getMessage() . "\n";
}

try {
    Artisan::call('cache:clear');
    echo "   ✓ Application cache cleared\n";
} catch (Exception $e) {
    echo "   ✗ Cache clear failed: " . $e->getMessage() . "\n";
}

try {
    Artisan::call('route:clear');
    echo "   ✓ Route cache cleared\n";
} catch (Exception $e) {
    echo "   ✗ Route clear failed: " . $e->getMessage() . "\n";
}

try {
    Artisan::call('view:clear');
    echo "   ✓ View cache cleared\n";
} catch (Exception $e) {
    echo "   ✗ View clear failed: " . $e->getMessage() . "\n";
}

echo "\n=== COMPLETE ===\n";
echo "\n⚠️  DELETE THIS FILE NOW!\n";
echo "   File location: " . __FILE__ . "\n";
echo "</pre>";
