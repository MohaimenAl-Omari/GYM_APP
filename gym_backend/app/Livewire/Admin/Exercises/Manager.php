<?php

namespace App\Livewire\Admin\Exercises;

use App\Models\Exercise;
use App\Models\MuscleGroup;
use Illuminate\Support\Facades\Storage;
use Livewire\Attributes\Layout;
use Livewire\Component;
use Livewire\WithFileUploads;
use Livewire\WithPagination;

#[Layout('layouts.admin')]
class Manager extends Component
{
    use WithFileUploads;
    use WithPagination;

    public bool $showModal = false;
    public ?int $editingId = null;

    public string $muscle_group_id = '';
    public string $name_en = '';
    public string $name_ar = '';
    public string $description_en = '';
    public string $description_ar = '';

    // Static image: either an uploaded file or a pasted external URL.
    public $media = null;
    public string $mediaUrlInput = '';
    public ?string $existingMedia = null;

    // Animated GIF (preferred over the static image when both are set —
    // mirrors Exercise::demoUrl / the Flutter app's Exercise.demoUrl).
    public $gif = null;
    public string $gifUrlInput = '';
    public ?string $existingGifUrl = null;

    public string $filterMuscleGroup = '';
    public string $search = '';

    protected function rules(): array
    {
        return [
            'muscle_group_id' => ['required', 'exists:muscle_groups,id'],
            'name_en' => ['required', 'string', 'max:255'],
            'name_ar' => ['required', 'string', 'max:255'],
            'description_en' => ['nullable', 'string'],
            'description_ar' => ['nullable', 'string'],
            // Video was previously accepted here but never actually
            // rendered anywhere in the app (Image.network can't play an
            // mp4) — narrowed to what the UI can actually show. GIFs get
            // their own dedicated field below instead of sharing this one.
            'media' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp', 'max:10240'],
            'mediaUrlInput' => ['nullable', 'url', 'max:500'],
            'gif' => ['nullable', 'file', 'mimes:gif', 'max:10240'],
            'gifUrlInput' => ['nullable', 'url', 'max:500'],
        ];
    }

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function updatingFilterMuscleGroup(): void
    {
        $this->resetPage();
    }

    public function openCreate(): void
    {
        $this->resetForm();
        $this->showModal = true;
    }

    public function openEdit(int $id): void
    {
        $exercise = Exercise::findOrFail($id);
        $this->editingId = $exercise->id;
        $this->muscle_group_id = (string) $exercise->muscle_group_id;
        $this->name_en = $exercise->name_en;
        $this->name_ar = $exercise->name_ar;
        $this->description_en = $exercise->description_en ?? '';
        $this->description_ar = $exercise->description_ar ?? '';

        $this->existingMedia = $exercise->media;
        $this->existingGifUrl = $exercise->gif_url;
        // Only prefill the URL box when the stored value actually is an
        // external URL — an uploaded file's storage path has no business
        // showing up there.
        $this->mediaUrlInput = $this->isExternalUrl($exercise->media) ? $exercise->media : '';
        $this->gifUrlInput = $this->isExternalUrl($exercise->gif_url) ? $exercise->gif_url : '';
        $this->media = null;
        $this->gif = null;

        $this->showModal = true;
    }

    public function save(): void
    {
        $validated = $this->validate();

        $data = [
            'muscle_group_id' => $validated['muscle_group_id'],
            'name_en' => $validated['name_en'],
            'name_ar' => $validated['name_ar'],
            'description_en' => $validated['description_en'] ?: null,
            'description_ar' => $validated['description_ar'] ?: null,
        ];

        $data = array_merge($data, $this->resolveMediaField(
            upload: $this->media,
            urlInput: $this->mediaUrlInput,
            column: 'media',
            existing: $this->existingMedia,
        ));

        $data = array_merge($data, $this->resolveMediaField(
            upload: $this->gif,
            urlInput: $this->gifUrlInput,
            column: 'gif_url',
            existing: $this->existingGifUrl,
        ));

        if ($this->editingId) {
            Exercise::findOrFail($this->editingId)->update($data);
            session()->flash('status', 'Exercise updated.');
        } else {
            Exercise::create($data);
            session()->flash('status', 'Exercise created.');
        }

        $this->closeModal();
    }

    public function delete(int $id): void
    {
        $exercise = Exercise::findOrFail($id);

        foreach ([$exercise->media, $exercise->gif_url] as $path) {
            // Never delete an external URL from our own storage — there's
            // nothing of ours to delete, it just lives on someone else's
            // server.
            if ($path && !$this->isExternalUrl($path)) {
                Storage::disk('public')->delete($path);
            }
        }

        $exercise->delete();
        session()->flash('status', 'Exercise deleted.');
    }

    public function closeModal(): void
    {
        $this->showModal = false;
        $this->resetForm();
    }

    private function resetForm(): void
    {
        $this->reset([
            'editingId', 'muscle_group_id', 'name_en', 'name_ar',
            'description_en', 'description_ar',
            'media', 'mediaUrlInput', 'existingMedia',
            'gif', 'gifUrlInput', 'existingGifUrl',
        ]);
        $this->resetErrorBag();
    }

    /**
     * Precedence for one media field: a freshly uploaded file wins, then a
     * pasted URL, then whatever was already there is left untouched. When
     * a new upload replaces a previously *uploaded* file, the old one is
     * deleted from storage; an old external URL is just abandoned (never
     * ours to delete).
     *
     * @return array<string, string> empty when nothing about this field changed
     */
    private function resolveMediaField($upload, string $urlInput, string $column, ?string $existing): array
    {
        if ($upload) {
            if ($existing && !$this->isExternalUrl($existing)) {
                Storage::disk('public')->delete($existing);
            }

            return [$column => $upload->store('exercises', 'public')];
        }

        if ($urlInput !== '') {
            return [$column => $urlInput];
        }

        return [];
    }

    private function isExternalUrl(?string $value): bool
    {
        return $value !== null && (str_starts_with($value, 'http://') || str_starts_with($value, 'https://'));
    }

    private function resolvePreviewUrl(?string $path): ?string
    {
        if (!$path) {
            return null;
        }

        return $this->isExternalUrl($path) ? $path : Storage::url($path);
    }

    public function render()
    {
        $exercises = Exercise::with('muscleGroup')
            ->when($this->filterMuscleGroup, fn ($q) => $q->where('muscle_group_id', $this->filterMuscleGroup))
            ->when($this->search, fn ($q) => $q->where(function ($q) {
                $q->where('name_en', 'like', "%{$this->search}%")
                    ->orWhere('name_ar', 'like', "%{$this->search}%");
            }))
            ->orderBy('name_en')
            ->paginate(15);

        return view('livewire.admin.exercises.manager', [
            'exercises' => $exercises,
            'muscleGroups' => MuscleGroup::orderBy('name_en')->get(),
            'existingMediaPreviewUrl' => $this->resolvePreviewUrl($this->existingMedia),
            'existingGifPreviewUrl' => $this->resolvePreviewUrl($this->existingGifUrl),
        ]);
    }
}
