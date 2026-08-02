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
    public $media = null;
    public ?string $existingMedia = null;

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
            'media' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp,gif,mp4', 'max:10240'],
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
        $this->media = null;
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

        if ($this->media) {
            if ($this->editingId && $this->existingMedia) {
                Storage::disk('public')->delete($this->existingMedia);
            }
            $data['media'] = $this->media->store('exercises', 'public');
        }

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

        if ($exercise->media) {
            Storage::disk('public')->delete($exercise->media);
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
            'description_en', 'description_ar', 'media', 'existingMedia',
        ]);
        $this->resetErrorBag();
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
        ]);
    }
}
