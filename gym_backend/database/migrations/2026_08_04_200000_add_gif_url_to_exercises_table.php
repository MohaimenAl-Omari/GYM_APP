<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * The Flutter app's Exercise model already reads `gif_url` (falls
     * back to the static `media` image when absent) — this column didn't
     * exist yet, so it was always coming back null. Needed before the
     * exercise seeder can populate it.
     */
    public function up(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->string('gif_url')->nullable()->after('media');
        });
    }

    public function down(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->dropColumn('gif_url');
        });
    }
};
