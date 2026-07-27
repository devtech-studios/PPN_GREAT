<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Helper สำหรับรันคำสั่ง Artisan ผ่านเว็บบราวเซอร์ในโฮสติ้งที่ไม่มีสิทธิ์ SSH
Route::get('/run-artisan', function (\Illuminate\Http\Request $request) {
    if ($request->query('key') !== 'ppn_secret_deploy') {
        return response('Unauthorized access key', 403);
    }
    
    $command = $request->query('command', 'migrate');
    try {
        if ($command === 'migrate-seed') {
            \Illuminate\Support\Facades\Artisan::call('migrate:fresh', ['--seed' => true, '--force' => true]);
            return 'Database reset and seeded successfully!<br><pre>' . \Illuminate\Support\Facades\Artisan::output() . '</pre>';
        }
        
        if ($command === 'storage-link') {
            \Illuminate\Support\Facades\Artisan::call('storage:link');
            return 'Storage symlink created successfully!<br><pre>' . \Illuminate\Support\Facades\Artisan::output() . '</pre>';
        }
        
        \Illuminate\Support\Facades\Artisan::call($command, ['--force' => true]);
        return 'Executed command: ' . $command . '<br><pre>' . \Illuminate\Support\Facades\Artisan::output() . '</pre>';
    } catch (\Exception $e) {
        return 'Command failed: ' . $e->getMessage();
    }
});
