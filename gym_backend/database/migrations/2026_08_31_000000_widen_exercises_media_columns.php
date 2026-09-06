<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * `media`/`gif_url` are about to start holding two very different kinds
     * of value: a short relative storage path ("exercises/bench-press.gif")
     * uploaded through the admin panel, or a full external URL pasted in
     * directly (e.g. a CDN-hosted, already-licensed demo GIF from
     * ExerciseDB or elsewhere). The default `string` length (255) is fine
     * for the former but can be tight for a long signed/query-string CDN
     * URL — widening to 500 costs nothing (still a plain VARCHAR, no index
     * on these columns) and removes a silent truncation risk before it
     * ever bites.
     */
    public function up(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->string('media', 500)->nullable()->change();
            $table->string('gif_url', 500)->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->string('media', 255)->nullable()->change();
            $table->string('gif_url', 255)->nullable()->change();
        });
    }
};
