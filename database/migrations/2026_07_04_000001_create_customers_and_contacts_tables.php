<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('type', ['Enterprise', 'Mid-Market', 'SME'])->default('SME');
            $table->enum('status', ['Active', 'Inactive'])->default('Active');
            $table->string('tax_id', 20)->nullable();
            $table->string('branch', 100)->nullable();
            $table->string('industry', 100)->nullable();
            $table->enum('lead_source', ['Facebook Ads','Google Search','Referral','Exhibition','Direct Contact','Other'])->nullable();
            $table->text('internal_note')->nullable();
            $table->text('billing_address')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index('status');
            $table->index('type');
        });

        Schema::create('contact_persons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('role', 100)->nullable();
            $table->string('phone', 50)->nullable();
            $table->string('email')->nullable();
            $table->string('line_id', 100)->nullable();
            $table->string('other_chat')->nullable();
            $table->boolean('is_primary')->default(false);
            $table->timestamps();
        });

        Schema::create('shipping_addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->string('label');
            $table->text('address');
            $table->boolean('is_default')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shipping_addresses');
        Schema::dropIfExists('contact_persons');
        Schema::dropIfExists('customers');
    }
};
