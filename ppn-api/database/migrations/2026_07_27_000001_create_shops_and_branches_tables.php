<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. ตารางร้านค้า (Shops / Tenants)
        Schema::create('shops', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->unique()->nullable();
            $table->unsignedBigInteger('owner_user_id')->default(1);
            $table->enum('status', ['active', 'suspended', 'closed'])->default('active');
            $table->timestamps();
        });

        // 2. ตารางสาขา (Branches)
        Schema::create('branches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->string('code');
            $table->string('name');
            $table->text('address')->nullable();
            $table->string('phone')->nullable();
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->timestamps();

            $table->unique(['shop_id', 'code']);
        });

        // 3. ตารางผูกสิทธิ์สมาชิกร้านค้า (User Shop Permissions)
        Schema::create('user_shop_permissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->enum('role', ['super_admin', 'shop_owner', 'shop_manager', 'auditor'])->default('shop_owner');
            $table->timestamps();

            $table->unique(['user_id', 'shop_id']);
        });

        // 4. ตารางผูกสิทธิ์สมาชิกสาขา (User Branch Permissions)
        Schema::create('user_branch_permissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->foreignId('branch_id')->constrained('branches')->onDelete('cascade');
            $table->enum('role', ['branch_manager', 'sales', 'purchasing', 'finance', 'warehouse', 'employee'])->default('branch_manager');
            $table->timestamps();

            $table->unique(['user_id', 'branch_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_branch_permissions');
        Schema::dropIfExists('user_shop_permissions');
        Schema::dropIfExists('branches');
        Schema::dropIfExists('shops');
    }
};
