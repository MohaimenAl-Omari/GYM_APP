@php use Illuminate\Support\Facades\Storage; @endphp
<div>
    <div class="mb-6 flex items-center justify-between">
        <h1 class="text-2xl font-semibold text-gray-900">Exercises</h1>
        <button wire:click="openCreate" class="rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700">
            + Add Exercise
        </button>
    </div>

    @if (session('status'))
        <div class="mb-4 rounded-md bg-green-50 px-4 py-2 text-sm text-green-700">{{ session('status') }}</div>
    @endif

    <div class="mb-4 flex gap-3">
        <input
            type="text"
            wire:model.live.debounce.300ms="search"
            placeholder="Search exercises..."
            class="w-64 rounded-md border border-gray-300 px-3 py-2 text-sm"
        >
        <select wire:model.live="filterMuscleGroup" class="rounded-md border border-gray-300 px-3 py-2 text-sm">
            <option value="">All muscle groups</option>
            @foreach ($muscleGroups as $group)
                <option value="{{ $group->id }}">{{ $group->name_en }}</option>
            @endforeach
        </select>
    </div>

    <div class="overflow-hidden rounded-lg border border-gray-200 bg-white">
        <table class="w-full text-left text-sm">
            <thead class="border-b border-gray-200 bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                    <th class="px-4 py-3">Media</th>
                    <th class="px-4 py-3">Name (EN)</th>
                    <th class="px-4 py-3">Name (AR)</th>
                    <th class="px-4 py-3">Muscle Group</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse ($exercises as $exercise)
                    <tr wire:key="ex-{{ $exercise->id }}">
                        <td class="px-4 py-3">
                            @if ($exercise->media)
                                <img src="{{ Storage::url($exercise->media) }}" class="h-10 w-10 rounded object-cover" alt="">
                            @else
                                <div class="h-10 w-10 rounded bg-gray-100"></div>
                            @endif
                        </td>
                        <td class="px-4 py-3 font-medium text-gray-900">{{ $exercise->name_en }}</td>
                        <td class="px-4 py-3 text-gray-600" dir="rtl">{{ $exercise->name_ar }}</td>
                        <td class="px-4 py-3 text-gray-600">{{ $exercise->muscleGroup->name_en }}</td>
                        <td class="px-4 py-3 text-right">
                            <button wire:click="openEdit({{ $exercise->id }})" class="mr-3 text-sm font-medium text-gray-600 hover:text-gray-900">Edit</button>
                            <button
                                wire:click="delete({{ $exercise->id }})"
                                wire:confirm="Delete this exercise?"
                                class="text-sm font-medium text-red-600 hover:text-red-800"
                            >
                                Delete
                            </button>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" class="px-4 py-8 text-center text-gray-400">No exercises found.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $exercises->links() }}</div>

    @if ($showModal)
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
            <div class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-lg bg-white p-6 shadow-lg">
                <h2 class="mb-4 text-lg font-semibold text-gray-900">
                    {{ $editingId ? 'Edit Exercise' : 'New Exercise' }}
                </h2>

                <form wire:submit="save" class="space-y-4">
                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">Muscle Group</label>
                        <select wire:model="muscle_group_id" class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm">
                            <option value="">Select a muscle group</option>
                            @foreach ($muscleGroups as $group)
                                <option value="{{ $group->id }}">{{ $group->name_en }}</option>
                            @endforeach
                        </select>
                        @error('muscle_group_id') <p class="mt-1 text-sm text-red-600">{{ $message }}</p> @enderror
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="mb-1 block text-sm font-medium text-gray-700">Name (English)</label>
                            <input type="text" wire:model="name_en" class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm">
                            @error('name_en') <p class="mt-1 text-sm text-red-600">{{ $message }}</p> @enderror
                        </div>
                        <div>
                            <label class="mb-1 block text-sm font-medium text-gray-700">Name (Arabic)</label>
                            <input type="text" wire:model="name_ar" dir="rtl" class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm">
                            @error('name_ar') <p class="mt-1 text-sm text-red-600">{{ $message }}</p> @enderror
                        </div>
                    </div>

                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">Description (English)</label>
                        <textarea wire:model="description_en" rows="3" class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"></textarea>
                    </div>

                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">Description (Arabic)</label>
                        <textarea wire:model="description_ar" dir="rtl" rows="3" class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"></textarea>
                    </div>

                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">Image / Video</label>
                        <input type="file" wire:model="media" accept="image/*,video/mp4" class="w-full text-sm">
                        <div wire:loading wire:target="media" class="mt-1 text-xs text-gray-400">Uploading&hellip;</div>
                        @error('media') <p class="mt-1 text-sm text-red-600">{{ $message }}</p> @enderror

                        @if ($media)
                            <img src="{{ $media->temporaryUrl() }}" class="mt-2 h-16 w-16 rounded object-cover">
                        @elseif ($existingMedia)
                            <img src="{{ Storage::url($existingMedia) }}" class="mt-2 h-16 w-16 rounded object-cover">
                        @endif
                    </div>

                    <div class="flex justify-end gap-2 pt-2">
                        <button type="button" wire:click="closeModal" class="rounded-md px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100">
                            Cancel
                        </button>
                        <button type="submit" class="rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700" wire:loading.attr="disabled" wire:target="save">
                            Save
                        </button>
                    </div>
                </form>
            </div>
        </div>
    @endif
</div>
