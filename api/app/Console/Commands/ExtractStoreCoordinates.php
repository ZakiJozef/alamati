<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use App\Models\Store;

class ExtractStoreCoordinates extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'stores:extract-coordinates 
                            {--dry-run : Show what would be updated without making changes}
                            {--force : Update even if coordinates already exist}
                            {--follow-redirects : Follow short URL redirects (slower but more accurate)}';

    /**
     * The console command description.
     */
    protected $description = 'Extract latitude and longitude from Google Maps URLs for all stores';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $dryRun = $this->option('dry-run');
        $force = $this->option('force');
        $followRedirects = $this->option('follow-redirects');

        $query = Store::whereNotNull('map_url')
            ->where('map_url', '!=', '');

        if (!$force) {
            $query->where(function ($q) {
                $q->whereNull('lat')
                    ->orWhereNull('lng');
            });
        }

        $stores = $query->get();

        if ($stores->isEmpty()) {
            $this->info('No stores found needing coordinate extraction.');
            return 0;
        }

        $this->info("Found {$stores->count()} stores to process...");

        if ($dryRun) {
            $this->warn('DRY RUN MODE - No changes will be made');
        }

        if ($followRedirects) {
            $this->info('Following short URL redirects (this may take a while)...');
        }

        $updated = 0;
        $failed = 0;
        $expanded = 0;

        $this->newLine();
        $progressBar = $this->output->createProgressBar($stores->count());
        $progressBar->start();

        $failedStoresList = [];

        foreach ($stores as $store) {
            $url = $store->map_url;
            $coords = $this->parseCoordinatesFromUrl($url);

            // If initial parse failed and we should follow redirects, try expanding the URL
            if ($coords === null && $followRedirects && $this->isShortUrl($url)) {
                $expandedUrl = $this->expandShortUrl($url);
                if ($expandedUrl && $expandedUrl !== $url) {
                    $coords = $this->parseCoordinatesFromUrl($expandedUrl);
                    if ($coords) {
                        $expanded++;
                    }
                }
            }

            if ($coords) {
                if ($dryRun) {
                    $this->newLine();
                    $this->line("  [{$store->id}] {$store->name}: {$coords['lat']}, {$coords['lng']}");
                } else {
                    $store->lat = $coords['lat'];
                    $store->lng = $coords['lng'];
                    $store->save();
                }
                $updated++;
            } else {
                $failed++;
                $failedStoresList[] = $store;
            }

            $progressBar->advance();
        }

        $progressBar->finish();
        $this->newLine(2);

        $this->info("Results:");
        $this->line("  ✓ Updated: {$updated}");
        if ($followRedirects) {
            $this->line("  ↗ Expanded from short URLs: {$expanded}");
        }
        $this->line("  ✗ Failed to parse: {$failed}");

        if ($failed > 0 && count($failedStoresList) > 0) {
            $this->newLine();
            $this->warn("Stores with unparseable URLs:");

            foreach (array_slice($failedStoresList, 0, 10) as $store) {
                $this->line("  [{$store->id}] {$store->name}");
                $this->line("      URL: " . substr($store->map_url, 0, 80) . (strlen($store->map_url) > 80 ? '...' : ''));
            }

            if (count($failedStoresList) > 10) {
                $this->line("  ... and " . (count($failedStoresList) - 10) . " more");
            }
        }

        return 0;
    }

    /**
     * Check if URL is a short URL that needs expanding
     */
    private function isShortUrl(string $url): bool
    {
        return str_contains($url, 'goo.gl') ||
            str_contains($url, 'maps.app.goo.gl') ||
            str_contains($url, 'g.co') ||
            str_contains($url, 'bit.ly');
    }

    /**
     * Expand a short URL by following redirects
     */
    private function expandShortUrl(string $url): ?string
    {
        try {
            // Use cURL to follow redirects and get the final URL
            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
            curl_setopt($ch, CURLOPT_MAXREDIRS, 5);
            curl_setopt($ch, CURLOPT_TIMEOUT, 10);
            curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

            curl_exec($ch);
            $finalUrl = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode >= 200 && $httpCode < 400 && $finalUrl) {
                return $finalUrl;
            }
        } catch (\Exception $e) {
            // Silently fail and return null
        }

        return null;
    }

    /**
     * Parse coordinates from various Google Maps URL formats
     */
    private function parseCoordinatesFromUrl(string $url): ?array
    {
        // Pattern 1: /@lat,lng,zoom format (most common in full URLs)
        if (preg_match('/@(-?\d+\.?\d*),(-?\d+\.?\d*)/', $url, $matches)) {
            return [
                'lat' => (float) $matches[1],
                'lng' => (float) $matches[2],
            ];
        }

        // Pattern 2: !3d and !4d format (embedded in data parameter)
        if (preg_match('/!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)/', $url, $matches)) {
            return [
                'lat' => (float) $matches[1],
                'lng' => (float) $matches[2],
            ];
        }

        // Pattern 3: ll= or q= parameter format
        if (preg_match('/[?&](?:ll|q)=(-?\d+\.?\d*),(-?\d+\.?\d*)/', $url, $matches)) {
            return [
                'lat' => (float) $matches[1],
                'lng' => (float) $matches[2],
            ];
        }

        // Pattern 4: /place/ followed by coordinates
        if (preg_match('/\/place\/(-?\d+\.?\d*),(-?\d+\.?\d*)/', $url, $matches)) {
            return [
                'lat' => (float) $matches[1],
                'lng' => (float) $matches[2],
            ];
        }

        // Pattern 5: center= parameter
        if (preg_match('/center=(-?\d+\.?\d*),(-?\d+\.?\d*)/', $url, $matches)) {
            return [
                'lat' => (float) $matches[1],
                'lng' => (float) $matches[2],
            ];
        }

        // Pattern 6: destination= parameter in direction URLs (URL encoded)
        // Example: destination=36.7%2C3.2167 or destination=36.7,3.2167
        $decodedUrl = urldecode($url);
        if (preg_match('/destination=(-?\d+\.?\d*)[,\s](-?\d+\.?\d*)/', $decodedUrl, $matches)) {
            return [
                'lat' => (float) $matches[1],
                'lng' => (float) $matches[2],
            ];
        }

        // Pattern 7: daddr= parameter (old direction format)
        if (preg_match('/daddr=(-?\d+\.?\d*),(-?\d+\.?\d*)/', $decodedUrl, $matches)) {
            return [
                'lat' => (float) $matches[1],
                'lng' => (float) $matches[2],
            ];
        }

        return null;
    }
}
