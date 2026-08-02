<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Admin Login — Gym App</title>
    @vite(['resources/css/app.css'])
    @livewireStyles
</head>
<body class="flex min-h-screen items-center justify-center bg-gray-50">
    {{ $slot }}
    @livewireScripts
</body>
</html>
