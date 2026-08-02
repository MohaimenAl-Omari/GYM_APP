<div>
    <h1 class="mb-6 text-2xl font-semibold text-gray-900">Users</h1>

    <input
        type="text"
        wire:model.live.debounce.300ms="search"
        placeholder="Search by name, phone, or email..."
        class="mb-4 w-72 rounded-md border border-gray-300 px-3 py-2 text-sm"
    >

    <div class="overflow-hidden rounded-lg border border-gray-200 bg-white">
        <table class="w-full text-left text-sm">
            <thead class="border-b border-gray-200 bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                    <th class="px-4 py-3">Name</th>
                    <th class="px-4 py-3">Phone</th>
                    <th class="px-4 py-3">Email</th>
                    <th class="px-4 py-3">Signed up via</th>
                    <th class="px-4 py-3">Joined</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse ($users as $user)
                    <tr wire:key="user-{{ $user->id }}">
                        <td class="px-4 py-3 font-medium text-gray-900">{{ $user->name }}</td>
                        <td class="px-4 py-3 text-gray-600">{{ $user->phone_number ?? '—' }}</td>
                        <td class="px-4 py-3 text-gray-600">{{ $user->email ?? '—' }}</td>
                        <td class="px-4 py-3 text-gray-600">
                            @if ($user->google_id) Google
                            @elseif ($user->apple_id) Apple
                            @else Phone
                            @endif
                        </td>
                        <td class="px-4 py-3 text-gray-600">{{ $user->created_at->format('M j, Y') }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" class="px-4 py-8 text-center text-gray-400">No users yet.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $users->links() }}</div>
</div>
