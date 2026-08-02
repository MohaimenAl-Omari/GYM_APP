<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Admin' }} — Gym App</title>
    @vite(['resources/css/app.css'])
    @livewireStyles
</head>
<body class="min-h-screen bg-gray-50 text-gray-900">
    <div class="flex min-h-screen">
        <aside class="w-60 shrink-0 border-r border-gray-200 bg-white">
            <div class="border-b border-gray-200 px-5 py-4">
                <p class="text-sm font-semibold text-gray-900">Gym App Admin</p>
                <p class="text-xs text-gray-500">{{ auth('admin')->user()->name ?? '' }}</p>
            </div>
            <nav class="flex flex-col gap-1 p-3 text-sm">
                @php($current = request()->route()?->getName())
                @foreach ([
                    ['route' => 'admin.dashboard', 'label' => 'Dashboard'],
                    ['route' => 'admin.muscle-groups', 'label' => 'Muscle Groups'],
                    ['route' => 'admin.exercises', 'label' => 'Exercises'],
                    ['route' => 'admin.users', 'label' => 'Users'],
                ] as $item)
                    <a
                        href="{{ route($item['route']) }}"
                        wire:navigate
                        class="rounded-md px-3 py-2 font-medium transition {{ $current === $item['route'] ? 'bg-gray-900 text-white' : 'text-gray-600 hover:bg-gray-100' }}"
                    >
                        {{ $item['label'] }}
                    </a>
                @endforeach

                <form method="POST" action="{{ route('admin.logout') }}" class="mt-4 border-t border-gray-200 pt-3">
                    @csrf
                    <button type="submit" class="w-full rounded-md px-3 py-2 text-left font-medium text-gray-500 hover:bg-gray-100">
                        Log out
                    </button>
                </form>
            </nav>
        </aside>

        <main class="flex-1 p-8">
            {{ $slot }}
        </main>
    </div>

    @livewireScripts
</body>
</html>
