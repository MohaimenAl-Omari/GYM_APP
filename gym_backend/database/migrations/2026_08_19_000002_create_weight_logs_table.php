<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * `users.weight` only ever holds the current value (overwritten on
     * every profile update), so there's no history to chart. This table
     * is a simple append-only log of readings over time for the Progress
     * screen's body-stats trend — it doesn't replace users.weight, which
     * stays the "current" value shown on the profile screen.
     */
    public function up(): void
    {
        Schema::create('weight_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->decimal('weight', 5, 2);
            $table->enum('weight_unit', ['kg', 'lbs']);
            $table->date('logged_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('weight_logs');
    }
};
