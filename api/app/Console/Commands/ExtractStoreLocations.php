<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Store;
use App\Models\Wilaya;
use App\Models\Commune;

class ExtractStoreLocations extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'stores:extract-locations 
                            {--dry-run : Show what would be updated without making changes}
                            {--force : Update even if wilaya/commune already set}';

    /**
     * The console command description.
     */
    protected $description = 'Extract wilaya and commune from Google Maps URLs and match to database records';

    private $wilayas;
    private $communes;

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $dryRun = $this->option('dry-run');
        $force = $this->option('force');

        // Load all wilayas and communes into memory for faster matching
        $this->wilayas = Wilaya::all();
        $this->communes = Commune::with('wilaya')->get();

        $this->info("Loaded {$this->wilayas->count()} wilayas and {$this->communes->count()} communes");

        $query = Store::whereNotNull('map_url')
            ->where('map_url', '!=', '');

        if (!$force) {
            $query->where(function ($q) {
                $q->whereNull('wilaya_id')
                    ->orWhereNull('commune_id');
            });
        }

        $stores = $query->get();

        if ($stores->isEmpty()) {
            $this->info('No stores found needing location extraction.');
            return 0;
        }

        $this->info("Found {$stores->count()} stores to process...");

        if ($dryRun) {
            $this->warn('DRY RUN MODE - No changes will be made');
        }

        $wilayaUpdated = 0;
        $communeUpdated = 0;
        $failed = 0;

        $this->newLine();
        $progressBar = $this->output->createProgressBar($stores->count());
        $progressBar->start();

        $failedStoresList = [];

        foreach ($stores as $store) {
            $url = urldecode($store->map_url);
            $locationNames = $this->extractLocationNamesFromUrl($url);

            $matchedWilaya = null;
            $matchedCommune = null;

            // Try to find wilaya from URL
            if (!empty($locationNames)) {
                foreach ($locationNames as $name) {
                    // Try to match wilaya
                    if (!$matchedWilaya) {
                        $matchedWilaya = $this->findWilaya($name);
                    }

                    // Try to match commune
                    if (!$matchedCommune) {
                        $matchedCommune = $this->findCommune($name, $matchedWilaya);
                    }
                }
            }

            // If we found a commune but not wilaya, get wilaya from commune
            if ($matchedCommune && !$matchedWilaya) {
                $matchedWilaya = $matchedCommune->wilaya;
            }

            $updated = false;

            if ($matchedWilaya && ($force || !$store->wilaya_id)) {
                if ($dryRun) {
                    $this->newLine();
                    $this->line("  [{$store->id}] {$store->name} -> Wilaya: {$matchedWilaya->name}");
                } else {
                    $store->wilaya_id = $matchedWilaya->id;
                    $store->state = $matchedWilaya->name;
                    $updated = true;
                }
                $wilayaUpdated++;
            }

            if ($matchedCommune && ($force || !$store->commune_id)) {
                if ($dryRun) {
                    $this->line("  [{$store->id}] {$store->name} -> Commune: {$matchedCommune->name}");
                } else {
                    $store->commune_id = $matchedCommune->id;
                    $store->city = $matchedCommune->name;
                    $updated = true;
                }
                $communeUpdated++;
            }

            if ($updated && !$dryRun) {
                $store->save();
            }

            if (!$matchedWilaya && !$matchedCommune) {
                $failed++;
                $failedStoresList[] = $store;
            }

            $progressBar->advance();
        }

        $progressBar->finish();
        $this->newLine(2);

        $this->info("Results:");
        $this->line("  ✓ Wilayas matched: {$wilayaUpdated}");
        $this->line("  ✓ Communes matched: {$communeUpdated}");
        $this->line("  ✗ No location found: {$failed}");

        if ($failed > 0 && count($failedStoresList) > 0) {
            $this->newLine();
            $this->warn("Stores with no location match:");

            foreach (array_slice($failedStoresList, 0, 10) as $store) {
                $this->line("  [{$store->id}] {$store->name}");
                $this->line("      URL: " . substr($store->map_url, 0, 100) . (strlen($store->map_url) > 100 ? '...' : ''));
            }

            if (count($failedStoresList) > 10) {
                $this->line("  ... and " . (count($failedStoresList) - 10) . " more");
            }
        }

        return 0;
    }

    /**
     * Extract possible location names from Google Maps URL
     */
    private function extractLocationNamesFromUrl(string $url): array
    {
        $names = [];

        // Pattern 1: /place/Name+With+Plus+Signs/@...
        if (preg_match('/\/place\/([^\/\@]+)/', $url, $matches)) {
            $placeName = str_replace(['+', '%20'], ' ', $matches[1]);
            $names[] = $placeName;

            // Split by comma to get individual parts
            $parts = explode(',', $placeName);
            foreach ($parts as $part) {
                $names[] = trim($part);
            }
        }

        // Pattern 2: Extract from URL path segments
        if (preg_match_all('/\/([A-Za-z\x{0600}-\x{06FF}\s\-]+)(?:\/|$)/u', $url, $matches)) {
            foreach ($matches[1] as $match) {
                if (strlen($match) > 2 && $match !== 'maps' && $match !== 'place' && $match !== 'dir') {
                    $names[] = trim($match);
                }
            }
        }

        // Pattern 3: Extract from data parameter (sometimes contains place name)
        if (preg_match('/!2s([^!]+)/', $url, $matches)) {
            $names[] = urldecode($matches[1]);
        }

        // Clean and normalize names
        $cleanedNames = [];
        foreach ($names as $name) {
            $cleaned = $this->normalizeName($name);
            if (strlen($cleaned) > 2) {
                $cleanedNames[] = $cleaned;
            }
        }

        return array_unique($cleanedNames);
    }

    /**
     * Normalize a name for matching
     */
    private function normalizeName(string $name): string
    {
        // Remove common prefixes/suffixes
        $name = preg_replace('/^(wilaya\s+de\s+|commune\s+de\s+|daira\s+de\s+)/i', '', $name);

        // Remove numbers and special characters but keep Arabic
        $name = preg_replace('/[0-9\+\%\@\#\$\&\*\(\)\[\]\{\}]/u', '', $name);

        // Trim and normalize whitespace
        $name = preg_replace('/\s+/', ' ', trim($name));

        return $name;
    }

    /**
     * Find a wilaya by name (French or Arabic)
     */
    private function findWilaya(string $name): ?Wilaya
    {
        $normalizedName = strtolower($this->normalizeName($name));

        foreach ($this->wilayas as $wilaya) {
            $wilayaName = strtolower($wilaya->name);
            $wilayaArName = $wilaya->ar_name ?? '';

            // Exact match
            if ($wilayaName === $normalizedName || $wilayaArName === $name) {
                return $wilaya;
            }

            // Contains match (for multi-word names)
            if (
                strlen($normalizedName) > 3 && (
                    str_contains($normalizedName, $wilayaName) ||
                    str_contains($wilayaName, $normalizedName)
                )
            ) {
                return $wilaya;
            }

            // Common transliterations
            $variations = $this->getNameVariations($wilayaName);
            foreach ($variations as $variation) {
                if (str_contains($normalizedName, $variation) || str_contains($variation, $normalizedName)) {
                    return $wilaya;
                }
            }
        }

        return null;
    }

    /**
     * Find a commune by name, optionally filtered by wilaya
     */
    private function findCommune(string $name, ?Wilaya $wilaya = null): ?Commune
    {
        $normalizedName = strtolower($this->normalizeName($name));

        $communes = $wilaya ? $this->communes->where('wilaya_id', $wilaya->id) : $this->communes;

        foreach ($communes as $commune) {
            $communeName = strtolower($commune->name);
            $communeArName = $commune->ar_name ?? '';

            // Exact match
            if ($communeName === $normalizedName || $communeArName === $name) {
                return $commune;
            }

            // Contains match
            if (
                strlen($normalizedName) > 3 && (
                    str_contains($normalizedName, $communeName) ||
                    str_contains($communeName, $normalizedName)
                )
            ) {
                return $commune;
            }

            // Variations
            $variations = $this->getNameVariations($communeName);
            foreach ($variations as $variation) {
                if (str_contains($normalizedName, $variation) || str_contains($variation, $normalizedName)) {
                    return $commune;
                }
            }
        }

        return null;
    }

    /**
     * Get common variations of Algerian place names
     */
    private function getNameVariations(string $name): array
    {
        $variations = [$name];

        // Common French/Arabic transliteration variations
        $replacements = [
            'ou' => 'u',
            'ch' => 'sh',
            'el ' => 'al ',
            'el-' => 'al-',
            'oued' => 'wadi',
            'ain' => 'ayn',
            'bou' => 'bu',
            'dj' => 'j',
        ];

        foreach ($replacements as $from => $to) {
            if (str_contains($name, $from)) {
                $variations[] = str_replace($from, $to, $name);
            }
            if (str_contains($name, $to)) {
                $variations[] = str_replace($to, $from, $name);
            }
        }

        // Without hyphens/spaces
        $variations[] = str_replace(['-', ' '], '', $name);
        $variations[] = str_replace('-', ' ', $name);
        $variations[] = str_replace(' ', '-', $name);

        return array_unique($variations);
    }
}
