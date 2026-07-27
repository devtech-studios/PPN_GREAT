<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database with complete mock data.
     */
    public function run(): void
    {
        $this->call([
            DummyDataSeeder::class,
            GuangzhouSupplierSeeder::class,
        ]);
    }
}
