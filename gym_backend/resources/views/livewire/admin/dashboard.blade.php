<div>
    <h1 class="mb-6 text-2xl font-semibold text-gray-900">Dashboard</h1>

    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div class="rounded-lg border border-gray-200 bg-white p-5">
            <p class="text-sm text-gray-500">Users</p>
            <p class="mt-1 text-3xl font-semibold text-gray-900">{{ $userCount }}</p>
        </div>
        <div class="rounded-lg border border-gray-200 bg-white p-5">
            <p class="text-sm text-gray-500">Muscle Groups</p>
            <p class="mt-1 text-3xl font-semibold text-gray-900">{{ $muscleGroupCount }}</p>
        </div>
        <div class="rounded-lg border border-gray-200 bg-white p-5">
            <p class="text-sm text-gray-500">Exercises</p>
            <p class="mt-1 text-3xl font-semibold text-gray-900">{{ $exerciseCount }}</p>
        </div>
    </div>
</div>
