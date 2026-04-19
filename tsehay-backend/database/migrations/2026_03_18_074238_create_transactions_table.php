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
    Schema::create('transactions', function (Blueprint $table) {
        $table->id();
        $table->unsignedBigInteger('user_id');
        $table->enum('type', ['deposit', 'withdraw', 'transfer']);
        $table->decimal('amount', 15, 2)->nullable();
        $table->string('account_number')->nullable();
        $table->string('account_holder')->nullable();
        $table->string('amount_words')->nullable();
        $table->string('deposited_by')->nullable();
        $table->string('to_account')->nullable();
        $table->string('photo')->nullable();
        $table->date('date')->nullable();
        $table->enum('status', ['waiting', 'pending', 'processing', 'completed'])->default('waiting');
        $table->unsignedBigInteger('window_id')->nullable();
        $table->integer('priority')->default(0);
        $table->string('queue_number')->nullable();
        $table->timestamps();
    });
}   /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
