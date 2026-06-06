<?php
/**
 * TEMPORARY TEST SCRIPT - DELETE AFTER USE!
 * Tests actual token validation
 */

$secret = $_GET['key'] ?? '';
if ($secret !== 'test3alamati2026') {
    http_response_code(403);
    die('Access denied. Add ?key=test3alamati2026 to URL');
}

require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "<pre style='font-family: monospace; background: #1e1e1e; color: #00ff00; padding: 20px;'>";
echo "=== SANCTUM TOKEN VALIDATION TEST ===\n\n";

// Test token provided in URL
$testToken = $_GET['token'] ?? null;

if (!$testToken) {
    // Create a fresh token
    echo "No token provided, creating a fresh one...\n\n";

    $user = \App\Models\User::where('email', 'user@example.com')->first();
    if ($user) {
        $newToken = $user->createToken('test_token')->plainTextToken;
        echo "Created token: $newToken\n\n";
        echo "Now test with: ?key=test3alamati2026&token=YOUR_TOKEN\n";
        echo "Or use this token directly.\n\n";

        // Also test internally
        $testToken = $newToken;
    } else {
        echo "ERROR: User not found!\n";
        die("</pre>");
    }
}

echo "Testing token: " . substr($testToken, 0, 30) . "...\n\n";

// Parse the token
$parts = explode('|', $testToken, 2);
if (count($parts) !== 2) {
    echo "ERROR: Invalid token format! Expected 'id|token'\n";
    die("</pre>");
}

$tokenId = $parts[0];
$plainTextToken = $parts[1];

echo "1. Token ID: $tokenId\n";
echo "2. Plain text token (first 20): " . substr($plainTextToken, 0, 20) . "...\n";

// Find the token in database
$dbToken = DB::table('personal_access_tokens')->where('id', $tokenId)->first();

if (!$dbToken) {
    echo "\nERROR: Token ID $tokenId not found in database!\n";
    die("</pre>");
}

echo "3. Found in database: YES\n";
echo "4. Stored hash (first 20): " . substr($dbToken->token, 0, 20) . "...\n";

// Hash the plain text token
$hashedToken = hash('sha256', $plainTextToken);
echo "5. Computed hash (first 20): " . substr($hashedToken, 0, 20) . "...\n";

// Compare
$matches = hash_equals($dbToken->token, $hashedToken);
echo "6. Hash matches: " . ($matches ? "YES ✓" : "NO ✗") . "\n";

if (!$matches) {
    echo "\n!!! TOKEN HASH MISMATCH !!!\n";
    echo "This usually means the token was corrupted in transit.\n";
    echo "Stored hash:   $dbToken->token\n";
    echo "Computed hash: $hashedToken\n";
}

// Try to authenticate with Laravel's Sanctum
echo "\n7. Testing Sanctum validation...\n";
try {
    $personalAccessToken = \Laravel\Sanctum\PersonalAccessToken::findToken($testToken);
    if ($personalAccessToken) {
        echo "   Sanctum found token: YES ✓\n";
        echo "   Token owner: " . $personalAccessToken->tokenable->email . "\n";

        // Set the user
        $user = $personalAccessToken->tokenable;
        Auth::login($user);
        echo "   User authenticated: " . (Auth::check() ? "YES ✓" : "NO ✗") . "\n";
    } else {
        echo "   Sanctum found token: NO ✗\n";
    }
} catch (Exception $e) {
    echo "   ERROR: " . $e->getMessage() . "\n";
}

echo "\n=== TEST COMPLETE ===\n";
echo "\n⚠️  DELETE THIS FILE NOW!\n";
echo "</pre>";
