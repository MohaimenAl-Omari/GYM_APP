<?php

namespace App\Livewire\Admin\MuscleGroups;

use App\Models\MuscleGroup;
use Illuminate\Support\Facades\Storage;
use Livewire\Attributes\Layout;
use Livewire\Component;
use Livewire\WithFileUploads;

#[Layout('layouts.admin')]
class Manager extends Component
{
    use WithFileUploads;

    public bool $showModal = false;
    public ?int $editingId = null;

    public string $name_en = '';
    public string $name_ar = '';
    public $media = null; // new upload (temporary file)
    public ?string $existingMedia = null;

    protected function rules(): array
    {
        return [
            'name_en' => ['required', 'string', 'max:255'],
            'name_ar' => ['required', 'string', 'max:255'],
            'media' => ['nullable', 'image', 'max:4096'],
        ];
    }

    public function openCreate(): void
    {
        $this->resetForm();
        $this->showModal = true;
    }

    public function openEdit(int $id): void
    {
        $group = MuscleGroup::findOrFail($id);
        $this->editingId = $group->id;
        $this->name_en = $group->name_en;
        $this->name_ar = $group->name_ar;
        $this->existingMedia = $group->media;
        $this->media = null;
        $this->showModal = true;
    }

    public function save(): void
    {
        $validated = $this->validate();

        $data = [
            'name_en' => $validated['name_en'],
            'name_ar' => $validated['name_ar'],
        ];

        if ($this->media) {
            if ($this->editingId && $this->existingMedia) {
                Storage::disk('public')->delete($this->existingMedia);
            }
            $data['media'] = $this->media->store('muscle-groups', 'public');
        }

        if ($this->editingId) {
            MuscleGroup::findOrFail($this->editingId)->update($data);
            session()->flash('status', 'Muscle group updated.');
        } else {
            MuscleGroup::create($data);
            session()->flash('status', 'Muscle group created.');
        }

        $this->closeModal();
    }

    public function delete(int $id): void
    {
        $group = MuscleGroup::findOrFail($id);

        if ($group->exercises()->exists()) {
            session()->flash('error', 'Can\'t delete a muscle group that still has exercises.');
            return;
        }

        if ($group->media) {
            Storage::disk('public')->delete($group->media);
        }

        $group->delete();
        session()->flash('status', 'Muscle group deleted.');
    }

    public function closeModal(): void
    {
        $this->showModal = false;
        $this->resetForm();
    }

    private function resetForm(): void
    {
        $this->reset(['editingId', 'name_en', 'name_ar', 'media', 'existingMedia']);
        $this->resetErrorBag();
    }

    public function render()
    {
        return view('livewire.admin.muscle-groups.manager', [
            'muscleGroups' => MuscleGroup::withCount('exercises')->orderBy('name_en')->get(),
        ]);
    }
}
