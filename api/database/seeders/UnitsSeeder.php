<?php

namespace Database\Seeders;

use App\Models\Unit;
use Illuminate\Database\Seeder;

class UnitsSeeder extends Seeder
{
    /**
     * Seed the units table with default price units.
     */
    public function run(): void
    {
        $units = [
            ['name' => 'Piece', 'symbol' => 'pcs', 'sort_order' => 1],
            ['name' => 'Hour', 'symbol' => 'hr', 'sort_order' => 2],
            ['name' => 'Day', 'symbol' => 'day', 'sort_order' => 3],
            ['name' => 'Week', 'symbol' => 'week', 'sort_order' => 4],
            ['name' => 'Month', 'symbol' => 'month', 'sort_order' => 5],
            ['name' => 'Meter', 'symbol' => 'm', 'sort_order' => 6],
            ['name' => 'Square Meter', 'symbol' => 'm²', 'sort_order' => 7],
            ['name' => 'Kilogram', 'symbol' => 'kg', 'sort_order' => 8],
            ['name' => 'Session', 'symbol' => 'session', 'sort_order' => 9],
            ['name' => 'Project', 'symbol' => 'project', 'sort_order' => 10],
            ['name' => 'Visit', 'symbol' => 'visit', 'sort_order' => 11],
            ['name' => 'Consultation', 'symbol' => 'consult', 'sort_order' => 12],
        ];

        foreach ($units as $unit) {
            Unit::updateOrCreate(
                ['symbol' => $unit['symbol']],
                $unit
            );
        }
    }
}
