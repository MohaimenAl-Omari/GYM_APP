<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sets', function (Blueprint $table) {
            $table->string('client_request_id', 32)->nullable();
            $table->unique(['session_exercise_id', 'client_request_id'], 'sets_client_request_unique');
        });
    }

    public function down(): void
    {
        Schema::table('sets', function (Blueprint $table) {
            $table->dropUnique('sets_client_request_unique');
            $table->dropColumn('client_request_id');
        });
    }
};
