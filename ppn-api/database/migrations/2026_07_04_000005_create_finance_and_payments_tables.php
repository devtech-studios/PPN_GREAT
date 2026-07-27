<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('finance_documents', function (Blueprint $table) {
            $table->id();
            $table->string('doc_no', 30)->unique();
            $table->foreignId('project_id')->constrained();
            $table->foreignId('customer_id')->constrained();
            $table->enum('doc_type', ['QU', 'PI', 'DP', 'CI']);
            $table->enum('status', ['Draft', 'Sent', 'Paid', 'Overdue', 'Cancelled'])->default('Draft');
            $table->decimal('total_amount', 14, 2)->default(0);
            $table->string('credit_term', 50)->nullable();
            $table->date('issue_date')->nullable();
            $table->date('due_date')->nullable();
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index('status');
            $table->index(['project_id', 'doc_type']);
        });

        Schema::create('finance_doc_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('finance_document_id')->constrained()->cascadeOnDelete();
            $table->string('item_name');
            $table->unsignedInteger('qty')->default(1);
            $table->decimal('unit_price', 12, 2)->default(0);
            $table->decimal('total_price', 14, 2)->default(0);
            $table->timestamps();
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained();
            $table->foreignId('finance_document_id')->nullable()->constrained('finance_documents')->nullOnDelete();
            $table->foreignId('customer_id')->constrained();
            $table->enum('payment_type', ['Deposit', 'Balance', 'Full']);
            $table->decimal('amount', 14, 2);
            $table->enum('method', ['Bank Transfer', 'Cheque', 'Cash', 'Other'])->default('Bank Transfer');
            $table->date('payment_date');
            $table->enum('status', ['Pending Verification', 'Confirmed'])->default('Pending Verification');
            $table->string('slip_file_path', 500)->nullable();
            $table->foreignId('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('verified_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
        Schema::dropIfExists('finance_doc_items');
        Schema::dropIfExists('finance_documents');
    }
};
