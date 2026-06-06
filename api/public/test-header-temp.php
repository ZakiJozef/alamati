<?php
/**
 * TEMPORARY - Tests if Authorization header is received
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Authorization, Content-Type');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$authHeader = null;

// Check multiple sources for Authorization header
$sources = [];

// 1. Standard header
if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
    $sources[] = 'HTTP_AUTHORIZATION';
}

// 2. Apache mod_rewrite environment variable
if (!$authHeader && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
    $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    $sources[] = 'REDIRECT_HTTP_AUTHORIZATION';
}

// 3. getallheaders() function
if (!$authHeader && function_exists('getallheaders')) {
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        $sources[] = 'getallheaders()';
    }
}

// 4. apache_request_headers() function
if (!$authHeader && function_exists('apache_request_headers')) {
    $headers = apache_request_headers();
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        $sources[] = 'apache_request_headers()';
    }
}

echo json_encode([
    'authorization_header' => $authHeader,
    'header_source' => $sources,
    'header_found' => $authHeader !== null,
    'all_headers' => function_exists('getallheaders') ? getallheaders() : 'getallheaders() not available',
    'relevant_server_vars' => [
        'HTTP_AUTHORIZATION' => $_SERVER['HTTP_AUTHORIZATION'] ?? 'not set',
        'REDIRECT_HTTP_AUTHORIZATION' => $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? 'not set',
        'PHP_AUTH_TYPE' => $_SERVER['PHP_AUTH_TYPE'] ?? 'not set',
        'PHP_AUTH_USER' => $_SERVER['PHP_AUTH_USER'] ?? 'not set',
    ],
], JSON_PRETTY_PRINT);
