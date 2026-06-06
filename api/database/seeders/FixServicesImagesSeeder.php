<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Product;
use Illuminate\Support\Facades\DB;

class FixServicesImagesSeeder extends Seeder
{
    /**
     * Fix double-encoded images field in services.
     */
    public function run(): void
    {
        // Get all services
        $services = Product::where('type', 'service')->get();

        foreach ($services as $service) {
            // Get raw images value from database
            $raw = DB::table('products')->where('id', $service->id)->value('images');

            if (is_string($raw)) {
                // Decode once to get the actual array
                $decoded = json_decode($raw, true);

                // If it's still a string, decode again (double-encoded)
                if (is_string($decoded)) {
                    $decoded = json_decode($decoded, true);
                }

                if (is_array($decoded)) {
                    DB::table('products')
                        ->where('id', $service->id)
                        ->update(['images' => json_encode($decoded)]);
                }
            }
        }

        $this->command->info('Fixed images for ' . $services->count() . ' services!');
    }
}
