<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Just set profile_pic to NULL so Flutter uses the built-in fallback
$updated = DB::update("
    UPDATE users 
    SET profile_pic = NULL
    WHERE profile_pic LIKE '%dicebear%' OR profile_pic LIKE '%ui-avatars%'
");

echo "Cleared $updated user avatar(s) - app will use built-in fallback\n";
