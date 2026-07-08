<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('session_exercise_id')->constrained();
            $table->integer('set_number');
            $table->integer('reps');
            $table->decimal('weight', 5, 2);
            $table->enum('weight_unit', ['kg', 'lbs']);
            $table->integer('rest_time')->nullable(); // seconds 
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sets');
    }
};
