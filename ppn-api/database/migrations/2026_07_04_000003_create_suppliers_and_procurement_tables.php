<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('suppliers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('category', 100)->nullable();
            $table->string('contact_person')->nullable();
            $table->string('phone', 100)->nullable();
            $table->string('wechat', 100)->nullable();
            $table->string('email')->nullable();
            $table->string('location')->nullable();
            $table->decimal('rating', 2, 1)->default(0);
            $table->text('notes')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('quote_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('supplier_id')->constrained();
            $table->foreignId('project_id')->constrained();
            $table->foreignId('product_item_id')->nullable()->constrained()->nullOnDelete();
            $table->string('customer_name')->nullable();
            $table->string('product_name');
            $table->unsignedInteger('qty')->default(0);
            $table->text('specs')->nullable();
            $table->text('variations')->nullable();
            $table->date('target_date')->nullable();
            $table->string('packing')->nullable();
            $table->enum('status', ['Waiting Link', 'Link Sent', 'Price Filled', 'Needs Revision', 'Approved'])->default('Waiting Link');
            $table->decimal('quoted_price', 12, 2)->nullable();
            $table->enum('currency', ['USD', 'THB'])->default('USD');
            $table->string('lead_time', 100)->nullable();
            $table->unsignedInteger('moq')->nullable();
            $table->decimal('sample_price', 12, 2)->nullable()->default(0);
            $table->string('sample_lead_time', 100)->nullable();
            $table->enum('sample_condition', ['Refundable', 'Non-Refundable', 'Free'])->nullable();
            $table->text('buyer_note')->nullable();
            $table->text('remark')->nullable();
            $table->string('session_token', 100)->nullable()->unique();
            $table->timestamps();

            $table->index('status');
        });

        Schema::create('supplier_samples', function (Blueprint $table) {
            $table->id();
            $table->foreignId('supplier_id')->constrained();
            $table->foreignId('project_id')->constrained();
            $table->string('product_name');
            $table->string('customer_name')->nullable();
            $table->enum('status', ['Waiting Supplier', 'Sample Sent', 'Approved'])->default('Waiting Supplier');
            $table->text('specs')->nullable();
            $table->string('cost', 50)->default('TBD');
            $table->string('tracking_no', 100)->nullable();
            $table->date('expected_date')->nullable();
            $table->timestamps();

            $table->index('status');
        });

        Schema::create('supplier_bills', function (Blueprint $table) {
            $table->id();
            $table->foreignId('supplier_id')->constrained();
            $table->foreignId('project_id')->constrained();
            $table->string('product_name');
            $table->enum('bill_type', ['Deposit', 'Balance', 'Full Payment']);
            $table->decimal('amount', 14, 2)->default(0);
            $table->enum('currency', ['USD', 'THB'])->default('USD');
            $table->string('due_month', 20)->nullable();
            $table->enum('status', ['Pending', 'Paid', 'Overdue'])->default('Pending');
            $table->boolean('pi_uploaded')->default(false);
            $table->string('pi_file_path', 500)->nullable();
            $table->boolean('invoice_uploaded')->default(false);
            $table->string('invoice_file_path', 500)->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('supplier_bills');
        Schema::dropIfExists('supplier_samples');
        Schema::dropIfExists('quote_requests');
        Schema::dropIfExists('suppliers');
    }
};
