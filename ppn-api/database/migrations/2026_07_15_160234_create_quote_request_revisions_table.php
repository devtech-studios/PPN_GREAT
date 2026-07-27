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
        Schema::create('quote_request_revisions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('quote_request_id')->constrained('quote_requests')->cascadeOnDelete();
            $table->string('actor'); // 'supplier' or 'buyer'
            $table->decimal('quoted_price', 12, 2)->nullable();
            $table->string('currency', 10)->default('USD');
            $table->string('lead_time', 100)->nullable();
            $table->integer('moq')->nullable();
            $table->decimal('sample_price', 12, 2)->default(0.00);
            $table->string('sample_lead_time', 100)->nullable();
            $table->string('sample_condition', 100)->nullable();
            $table->text('remark')->nullable();
            $table->text('buyer_note')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('quote_request_revisions');
    }
};
