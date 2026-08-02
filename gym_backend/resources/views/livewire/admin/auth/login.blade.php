<div class="w-full max-w-sm rounded-lg border border-gray-200 bg-white p-8 shadow-sm">
    <h1 class="mb-1 text-xl font-semibold text-gray-900">Gym App Admin</h1>
    <p class="mb-6 text-sm text-gray-500">Sign in to manage exercises, muscle groups, and users.</p>

    <form wire:submit="submit" class="space-y-4">
        <div>
            <label for="email" class="mb-1 block text-sm font-medium text-gray-700">Email</label>
            <input
                type="email"
                id="email"
                wire:model="email"
                autofocus
                autocomplete="username"
                class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-400 focus:outline-none focus:ring focus:ring-blue-100"
            />
            @error('email')
                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
            @enderror
        </div>

        <div>
            <label for="password" class="mb-1 block text-sm font-medium text-gray-700">Password</label>
            <input
                type="password"
                id="password"
                wire:model="password"
                autocomplete="current-password"
                class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-400 focus:outline-none focus:ring focus:ring-blue-100"
            />
            @error('password')
                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
            @enderror
        </div>

        <label class="flex items-center gap-2 text-sm text-gray-600">
            <input type="checkbox" wire:model="remember" class="rounded border-gray-300" />
            Remember me
        </label>

        <button
            type="submit"
            class="w-full rounded-md bg-gray-900 py-2 text-sm font-medium text-white transition hover:bg-gray-700"
            wire:loading.attr="disabled"
        >
            <span wire:loading.remove>Sign in</span>
            <span wire:loading>Signing in&hellip;</span>
        </button>
    </form>
</div>
