import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/exercises/models/muscle_group.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/shared/widgets/cached_remote_image.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';

/// Add-your-own-exercise form. Same screen handles both creating a new
/// custom exercise and editing an existing one the user already owns —
/// pass [exerciseToEdit] for the latter. [initialMuscleGroup] pre-selects
/// a group when this is opened from inside that group's exercise list, so
/// the user doesn't have to re-pick something they already navigated to.
///
/// Deliberately the simplest form this app's data model allows: one name
/// (not separate EN/AR — a personal exercise is usually a proper noun or
/// note that doesn't need translating), an optional description, an
/// optional photo. No GIF field — a user isn't going to have one, and
/// asking would just be friction for content only they'll ever see.
class AddEditExerciseScreen extends StatefulWidget {
  const AddEditExerciseScreen({
    super.key,
    this.initialMuscleGroup,
    this.exerciseToEdit,
  });

  final MuscleGroup? initialMuscleGroup;
  final Exercise? exerciseToEdit;

  bool get isEditing => exerciseToEdit != null;

  @override
  State<AddEditExerciseScreen> createState() => _AddEditExerciseScreenState();
}

class _AddEditExerciseScreenState extends State<AddEditExerciseScreen> {
  final ExerciseService _service = ExerciseService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late Future<List<MuscleGroup>> _groupsFuture;
  MuscleGroup? _selectedGroup;

  /// A freshly-picked local photo (overrides [_existingPhotoUrl] in the
  /// preview once set). Null with [_photoRemoved] false and an edit in
  /// progress means "keep whatever photo is already saved."
  XFile? _newPhoto;
  String? _existingPhotoUrl;
  bool _photoRemoved = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _service.fetchMuscleGroups();
    _selectedGroup = widget.initialMuscleGroup;

    final editing = widget.exerciseToEdit;
    if (editing != null) {
      final isArabic = Get.find<LocaleController>().isArabic;
      _nameController.text = editing.localizedName(isArabic);
      _descriptionController.text = editing.localizedDescription(isArabic) ?? '';
      _existingPhotoUrl = editing.mediaUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    Navigator.of(context).pop(); // close the picker sheet
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _newPhoto = picked;
      _photoRemoved = false;
    });
  }

  void _removePhoto() {
    Navigator.of(context).pop();
    setState(() {
      _newPhoto = null;
      _photoRemoved = true;
    });
  }

  void _showPhotoSheet() {
    final hasExistingPhoto =
        (_newPhoto != null) || (_existingPhotoUrl != null && !_photoRemoved);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _PhotoSheetOption(
              icon: Icons.photo_camera_outlined,
              label: 'take_photo'.tr,
              onTap: () => _pickPhoto(ImageSource.camera),
            ),
            _PhotoSheetOption(
              icon: Icons.photo_library_outlined,
              label: 'choose_from_gallery'.tr,
              onTap: () => _pickPhoto(ImageSource.gallery),
            ),
            if (hasExistingPhoto)
              _PhotoSheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'remove_photo'.tr,
                isDestructive: true,
                onTap: _removePhoto,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppNotification.showError(context, 'please_enter_exercise_name'.tr);
      return;
    }
    if (_selectedGroup == null) {
      AppNotification.showError(context, 'please_choose_muscle_group'.tr);
      return;
    }

    setState(() => _isSaving = true);

    final draft = ExerciseDraft(
      muscleGroupId: _selectedGroup!.id,
      name: name,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      photoPath: _newPhoto?.path,
      removePhoto: _photoRemoved,
    );

    try {
      final saved = widget.isEditing
          ? await _service.updateExercise(widget.exerciseToEdit!.id, draft)
          : await _service.createExercise(draft);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      final message = _extractErrorMessage(e) ?? 'generic_error'.tr;
      AppNotification.showError(context, message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _extractErrorMessage(Object error) {
    if (error is! DioException) return null;
    final data = error.response?.data;
    if (data is Map) {
      if (data['message'] != null) return data['message'].toString();
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.find<LocaleController>().isArabic;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
              24.rs(context), 12.rs(context), 24.rs(context), 32.rs(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedTap(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textGrey, size: 19),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    (widget.isEditing ? 'edit_exercise' : 'add_exercise').tr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              SizedBox(height: 20.rs(context)),
              FadeSlideIn(
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  color: AppColors.darkSurface,
                  borderColor: AppColors.darkBorder,
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('exercise_name'.tr),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'exercise_name_hint'.tr,
                        icon: Icons.fitness_center_rounded,
                      ),
                      SizedBox(height: 16.rs(context)),
                      _buildLabel('muscle_group_label'.tr),
                      const SizedBox(height: 8),
                      _buildMuscleGroupPicker(isArabic),
                      SizedBox(height: 16.rs(context)),
                      _buildLabel('description_optional'.tr),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'description_hint'.tr,
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                      SizedBox(height: 16.rs(context)),
                      _buildLabel('photo_optional'.tr),
                      const SizedBox(height: 8),
                      _buildPhotoPicker(),
                      SizedBox(height: 24.rs(context)),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.rf(context),
        fontWeight: FontWeight.w600,
        color: AppColors.textLightGrey,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: AppColors.textWhite, fontSize: 15.rf(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14.rf(context)),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0),
            child: Icon(icon, color: AppColors.textGrey, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildMuscleGroupPicker(bool isArabic) {
    return FutureBuilder<List<MuscleGroup>>(
      future: _groupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 44,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        }
        final groups = snapshot.data ?? const [];
        // Keep the group this exercise already belongs to selectable even
        // if, for some reason, it didn't come back in the fetched list.
        final selected = _selectedGroup;
        final all = selected != null && !groups.any((g) => g.id == selected.id)
            ? [selected, ...groups]
            : groups;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: all.map((group) {
            final isSelected = _selectedGroup?.id == group.id;
            return AnimatedTap(
              onTap: () => setState(() => _selectedGroup = group),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.darkBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  group.localizedName(isArabic),
                  style: TextStyle(
                    color: isSelected ? AppColors.textWhite : AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.rf(context),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPhotoPicker() {
    final showingExisting = _newPhoto == null && !_photoRemoved && _existingPhotoUrl != null;
    return AnimatedTap(
      onTap: _showPhotoSheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: _newPhoto != null
            ? Image.file(File(_newPhoto!.path), fit: BoxFit.cover, width: double.infinity)
            : showingExisting
                ? CachedRemoteImage(url: _existingPhotoUrl, iconSize: 32)
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_a_photo_outlined,
                            color: AppColors.textGrey, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          'photo_optional'.tr,
                          style: TextStyle(color: AppColors.textGrey, fontSize: 12.rf(context)),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedTap(
      onTap: _isSaving ? null : _handleSave,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.primaryGlow,
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.textWhite),
                )
              : Text(
                  'save'.tr,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16.rf(context),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PhotoSheetOption extends StatelessWidget {
  const _PhotoSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textWhite;
    return AnimatedTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
