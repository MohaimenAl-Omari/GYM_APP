<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // RapidAPI key for "EDB WITH IMAGES AND GIFS by AscendAPI" — subscribe
    // (free Basic plan, no card) at:
    // https://rapidapi.com/ascendapi/api/edb-with-gifs-and-images-by-ascendapi
    // Used by php artisan exercises:fetch-gifs to backfill real gif_url
    // values onto the seeded exercises.
    'exercisedb' => [
        'key' => env('EXERCISEDB_RAPIDAPI_KEY'),
        'host' => 'edb-with-gifs-and-images-by-ascendapi.p.rapidapi.com',
    ],

];
