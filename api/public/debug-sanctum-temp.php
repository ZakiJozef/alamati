<?php
/**
 * TEMPORARY DEBUG SCRIPT - DELETE AFTER USE!
 * Diagnoses Sanctum token issues
 */

$secret = $_GET['key'] ?? '';
if ($secret !== 'debug3alamati2026') {
    http_response_code(403);
    die('Access denied. Add ?key=debug3alamati2026 to URL');
}

require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "<pre style='font-family: monospace; background: #1e1e1e; color: #00ff00; padding: 20px;'>";
echo "=== SANCTUM TOKEN DEBUG ===\n\n";

// 1. Check if table exists
echo "1. Checking personal_access_tokens table...\n";
try {
    $hasTable = Schema::hasTable('personal_access_tokens');
    echo "   Table exists: " . ($hasTable ? "YES" : "NO") . "\n";

    if ($hasTable) {
        $columns = Schema::getColumnListing('personal_access_tokens');
        echo "   Columns: " . implode(', ', $columns) . "\n";

        $tokenCount = DB::table('personal_access_tokens')->count();
        echo "   Token count: $tokenCount\n";

        // Show last 3 tokens
        $tokens = DB::table('personal_access_tokens')
            ->select('id', 'tokenable_id', 'name', 'created_at')
            ->orderByDesc('id')
            ->limit(3)
            ->get();
        echo "   Last 3 tokens:\n";
        foreach ($tokens as $t) {
            echo "     - ID: {$t->id}, User: {$t->tokenable_id}, Name: {$t->name}, Created: {$t->created_at}\n";
        }
    }
} catch (Exception $e) {
    echo "   ERROR: " . $e->getMessage() . "\n";
}

// 2. Check Sanctum config
echo "\n2. Checking Sanctum configuration...\n";
try {
    $guard = config('sanctum.guard', 'not set');
    $expiration = config('sanctum.expiration', 'not set');
    $stateful = config('sanctum.stateful', []);
    echo "   Guard: $guard\n";
    echo "   Expiration: " . ($expiration ?: 'null (no expiration)') . "\n";
    echo "   Stateful domains: " . (is_array($stateful) ? implode(', ', $stateful) : $stateful) . "\n";
} catch (Exception $e) {
    echo "   ERROR: " . $e->getMessage() . "\n";
}

// 3. Check auth config
echo "\n3. Checking auth configuration...\n";
try {
    $guards = config('auth.guards');
    echo "   Guards: " . json_encode(array_keys($guards)) . "\n";

    $providers = config('auth.providers');
    echo "   Providers: " . json_encode(array_keys($providers)) . "\n";
} catch (Exception $e) {
    echo "   ERROR: " . $e->getMessage() . "\n";
}

// 4. Test token validation manually
echo "\n4. Testing token manually...\n";
try {
    // Get the most recent token
    $latestToken = DB::table('personal_access_tokens')
        ->orderByDesc('id')
        ->first();

    if ($latestToken) {
        echo "   Latest token ID: {$latestToken->id}\n";
        echo "   Token belongs to user ID: {$latestToken->tokenable_id}\n";
        echo "   Token hash (first 20 chars): " . substr($latestToken->token, 0, 20) . "...\n";

        // Check if user exists
        $user = DB::table('users')->where('id', $latestToken->tokenable_id)->first();
        echo "   User exists: " . ($user ? "YES ({$user->email})" : "NO") . "\n";
    } else {
        echo "   No tokens found!\n";
    }
} catch (Exception $e) {
    echo "   ERROR: " . $e->getMessage() . "\n";
}

// 5. Check APP_KEY
echo "\n5. Checking environment...\n";
try {
    $appKey = config('app.key');
    echo "   APP_KEY set: " . ($appKey ? "YES (length: " . strlen($appKey) . ")" : "NO") . "\n";
    echo "   APP_ENV: " . config('app.env') . "\n";
    echo "   APP_DEBUG: " . (config('app.debug') ? 'true' : 'false') . "\n";
} catch (Exception $e) {
    echo "   ERROR: " . $e->getMessage() . "\n";
}

echo "\n=== DEBUG COMPLETE ===\n";
echo "\n⚠️  DELETE THIS FILE NOW!\n";
echo "</pre>";
