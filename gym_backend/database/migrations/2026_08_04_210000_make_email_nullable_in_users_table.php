<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * signUp() creates users via username/phone and never sets email, but
     * the original users table has email as NOT NULL with no default —
     * that mismatch is what throws "Field 'email' doesn't have a default
     * value" on signup. Google/Apple login still use email, so it stays
     * unique, just nullable now.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('email')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('email')->nullable(false)->change();
        });
    }
};
