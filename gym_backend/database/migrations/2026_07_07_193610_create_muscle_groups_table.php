<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('muscle_groups', function (Blueprint $table) {
            $table->id();
            $table->string('name_en');
            $table->string('name_ar');
            $table->string('media')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('muscle_groups');
    }
};
