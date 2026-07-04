<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('client_samples', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained();
            $table->foreignId('product_item_id')->nullable()->constrained()->nullOnDelete();
            $table->string('sample_code', 20);
            $table->unsignedTinyInteger('attempt')->default(1);
            $table->enum('sample_type', ['Pre-production Sample', 'Material Swatch', '3D Printed Mockup', 'Other'])->default('Pre-production Sample');
            $table->enum('origin', ['China', 'In-Stock'])->default('China');
            $table->string('supplier_name')->nullable();
            $table->enum('status', ['Waiting from China', 'Received from China', 'Sent to Client', 'Delivered to Client', 'Approved', 'Rejected'])->default('Waiting from China');
            $table->date('sent_date')->nullable();
            $table->string('china_tracking', 100)->nullable();
            $table->string('local_courier', 100)->nullable();
            $table->string('local_tracking', 100)->nullable();
            $table->text('feedback')->nullable();
            $table->timestamps();

            $table->index('status');
        });

        Schema::create('artwork_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained();
            $table->foreignId('product_item_id')->nullable()->constrained()->nullOnDelete();
            $table->string('artwork_code', 20);
            $table->unsignedTinyInteger('attempt')->default(1);
            $table->string('version', 50);
            $table->enum('source', ['In-house Designer', 'Freelance', 'Customer Provided', 'Supplier'])->default('In-house Designer');
            $table->enum('status', ['Awaiting Approval', 'Reviewing', 'Need Revision', 'Rejected', 'Approved by Client', 'Approved by Supplier'])->default('Awaiting Approval');
            $table->string('file_name')->nullable();
            $table->string('file_path', 500)->nullable();
            $table->text('feedback')->nullable();
            $table->timestamps();

            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('artwork_logs');
        Schema::dropIfExists('client_samples');
    }
};
