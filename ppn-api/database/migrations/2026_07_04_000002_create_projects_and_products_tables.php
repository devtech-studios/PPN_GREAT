<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('projects', function (Blueprint $table) {
            $table->id();
            $table->string('project_code', 20)->unique();
            $table->foreignId('customer_id')->constrained();
            $table->foreignId('contact_person_id')->nullable()->constrained('contact_persons')->nullOnDelete();
            $table->enum('status', ['Inquiry','Sample','Production','Shipping','Distributing','Delivered','Cancelled'])->default('Inquiry');
            $table->unsignedTinyInteger('step')->default(0);
            $table->unsignedTinyInteger('priority')->default(0);
            $table->boolean('is_repeat_order')->default(false);
            $table->date('target_date')->nullable();
            $table->decimal('order_value', 14, 2)->default(0);
            $table->text('usage_location')->nullable();
            $table->enum('credit_term', ['Advance','15 Days','30 Days','45 Days','60 Days'])->default('30 Days');
            $table->boolean('deposit_paid')->default(false);
            $table->boolean('balance_paid')->default(false);
            $table->boolean('ocpb_passed')->default(false);
            $table->boolean('shipping_mark_ready')->default(false);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index('status');
            $table->index('customer_id');
        });

        Schema::create('product_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->unsignedInteger('qty')->default(0);
            $table->text('specs')->nullable();
            $table->date('target_date')->nullable();
            $table->timestamps();
        });

        Schema::create('product_variations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_item_id')->constrained()->cascadeOnDelete();
            $table->string('variation_name');
            $table->timestamps();
        });

        Schema::create('product_files', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_item_id')->constrained()->cascadeOnDelete();
            $table->enum('file_type', ['reference', 'artwork'])->default('reference');
            $table->string('file_name');
            $table->string('file_path', 500);
            $table->timestamps();
        });

        Schema::create('additional_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained()->cascadeOnDelete();
            $table->text('description');
            $table->decimal('cost', 12, 2)->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('additional_requests');
        Schema::dropIfExists('product_files');
        Schema::dropIfExists('product_variations');
        Schema::dropIfExists('product_items');
        Schema::dropIfExists('projects');
    }
};
