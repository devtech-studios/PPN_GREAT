<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('containers', function (Blueprint $table) {
            $table->id();
            $table->string('container_code', 30)->unique();
            $table->string('container_no')->nullable();
            $table->string('vessel_name')->nullable();
            $table->string('port_origin')->nullable();
            $table->string('port_destination')->nullable();
            $table->enum('status', ['Factory to Port', 'Sailing', 'Port to Warehouse', 'Delivered'])->default('Factory to Port');
            $table->date('factory_departure')->nullable();
            $table->string('domestic_tracking', 100)->nullable();
            $table->date('port_arrival_china')->nullable();
            $table->date('etd')->nullable();
            $table->date('eta')->nullable();
            $table->date('actual_arrival')->nullable();
            $table->boolean('customs_cleared')->default(false);
            $table->date('customs_date')->nullable();
            $table->date('warehouse_arrival')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index('status');
        });

        Schema::create('container_projects', function (Blueprint $table) {
            $table->id();
            $table->foreignId('container_id')->constrained()->cascadeOnDelete();
            $table->foreignId('project_id')->constrained();
            $table->timestamps();

            $table->unique(['container_id', 'project_id']);
        });

        Schema::create('warehouses', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('location')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('stock_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('warehouse_id')->constrained();
            $table->foreignId('product_item_id')->constrained();
            $table->foreignId('project_id')->constrained();
            $table->integer('qty_in_stock')->default(0);
            $table->integer('qty_reserved')->default(0);
            $table->string('location_in_warehouse', 100)->nullable();
            $table->timestamp('last_received_at')->nullable();
            $table->timestamps();
        });

        Schema::create('stock_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('stock_item_id')->constrained();
            $table->enum('movement_type', ['IN', 'OUT', 'ADJUST']);
            $table->integer('qty');
            $table->string('reference_type', 50)->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index('movement_type');
        });

        Schema::create('dispatch_rounds', function (Blueprint $table) {
            $table->id();
            $table->string('dispatch_code', 20)->unique();
            $table->date('dispatch_date');
            $table->string('driver_name')->nullable();
            $table->string('vehicle_plate', 50)->nullable();
            $table->enum('status', ['Scheduled', 'In Transit', 'Delivered'])->default('Scheduled');
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index('status');
        });

        Schema::create('delivery_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('dispatch_round_id')->constrained()->cascadeOnDelete();
            $table->foreignId('project_id')->constrained();
            $table->foreignId('product_item_id')->nullable()->constrained()->nullOnDelete();
            $table->string('customer_name')->nullable();
            $table->text('delivery_address')->nullable();
            $table->unsignedInteger('qty_to_deliver')->default(0);
            $table->foreignId('warehouse_id')->nullable()->constrained()->nullOnDelete();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_items');
        Schema::dropIfExists('dispatch_rounds');
        Schema::dropIfExists('stock_movements');
        Schema::dropIfExists('stock_items');
        Schema::dropIfExists('warehouses');
        Schema::dropIfExists('container_projects');
        Schema::dropIfExists('containers');
    }
};
