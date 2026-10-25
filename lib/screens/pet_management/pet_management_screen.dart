import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../data/models/pet_model.dart';
import '../../providers/pet_provider.dart';
import '../../services/overlay_service.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/playful_pet_stage.dart';

class PetManagementScreen extends StatefulWidget {
  const PetManagementScreen({super.key});

  @override
  State<PetManagementScreen> createState() => _PetManagementScreenState();
}

class _PetManagementScreenState extends State<PetManagementScreen> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();
    final activePet = provider.activePet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('펫 놀이터'),
        actions: [
          IconButton(
            tooltip: '팝업 미리보기',
            icon: const Icon(Icons.preview_outlined),
            onPressed: activePet == null || _uploading
                ? null
                : () => _runPhotoAction(() async {
                    final overlay = OverlayService.instance;
                    if (!await overlay.isPermissionGranted()) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('설정에서 다른 앱 위에 표시 권한을 먼저 허용해주세요.'),
                        ),
                      );
                      return;
                    }
                    await overlay.show(
                      petImagePath: activePet.imagePath,
                      triggerType: 'preview',
                    );
                  }),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  PlayfulPetStage(pet: activePet),
                  const SizedBox(height: 16),
                  _PhotoSetupCard(
                    pet: activePet,
                    onAdd: _startUploadFlow,
                    onReplace: activePet == null
                        ? null
                        : () => _replaceActivePhoto(activePet),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        '내 펫 사진',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '대표 사진이 실제 팝업에 떠요',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (provider.pets.isEmpty)
                    const _EmptyState()
                  else
                    ...provider.pets.map(
                      (pet) => _PetListItem(
                        pet: pet,
                        onTap: () =>
                            _runPhotoAction(() => _onPetTap(pet, provider)),
                        onReplace: () => _replacePetPhoto(pet),
                        onDelete: pet.type == 'default'
                            ? null
                            : () => _runPhotoAction(
                                () => _onDelete(pet, provider),
                              ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _startUploadFlow,
        icon: _uploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(_uploading ? '사진 준비 중...' : '펫 사진 추가'),
      ),
    );
  }

  Future<void> _onPetTap(PetModel pet, PetProvider provider) async {
    if (pet.isActive || pet.id == null) return;
    await provider.setActivePet(pet.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${pet.name} 사진이 실제 팝업에 사용돼요.')));
  }

  Future<void> _onDelete(PetModel pet, PetProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('펫 사진 삭제'),
        content: Text('${pet.name} 사진을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && pet.id != null) {
      await provider.deletePet(pet.id!);
      final file = File(pet.imagePath);
      if (await file.exists()) await file.delete();
    }
  }

  Future<String?> _pickAndCropPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '팝업에 보일 사진 맞추기',
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
      ],
    );
    if (cropped == null) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final petsDir = Directory('${docsDir.path}/pets');
    if (!await petsDir.exists()) await petsDir.create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = '${petsDir.path}/pet_$timestamp.jpg';
    await File(cropped.path).copy(destPath);
    return destPath;
  }

  Future<void> _runPhotoAction(Future<void> Function() action) async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진 작업을 완료하지 못했어요. 권한과 저장 공간을 확인하고 다시 시도해주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _startUploadFlow() => _runPhotoAction(_addPhoto);

  Future<void> _addPhoto() async {
    final provider = context.read<PetProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final path = await _pickAndCropPhoto();
    if (path == null || !mounted) return;

    final nameController = TextEditingController(text: '내 펫');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 이름'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(path),
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '이 사진을 뭐라고 부를까요?'),
              maxLength: 20,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('대표 사진으로 저장'),
          ),
        ],
      ),
    );

    if (!mounted || name == null || name.isEmpty) {
      await File(path).delete();
      return;
    }

    setState(() => _uploading = true);
    try {
      final id = await provider.addPet(
        PetModel(
          name: name,
          type: 'user_upload',
          imagePath: path,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      await provider.setActivePet(id);
      messenger.showSnackBar(
        SnackBar(content: Text('$name 사진을 실제 팝업 사진으로 설정했어요.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _replaceActivePhoto(PetModel pet) => _replacePetPhoto(pet);

  Future<void> _replacePetPhoto(PetModel pet) =>
      _runPhotoAction(() => _replacePhoto(pet));

  Future<void> _replacePhoto(PetModel pet) async {
    if (pet.id == null) return;
    final provider = context.read<PetProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final newPath = await _pickAndCropPhoto();
    if (newPath == null) return;

    final oldPath = pet.imagePath;
    await provider.updatePetPhoto(pet.id!, newPath);
    if (pet.type != 'default') {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) await oldFile.delete();
    }
    messenger.showSnackBar(
      SnackBar(content: Text('${pet.name} 사진을 새로 설정했어요.')),
    );
  }
}

class _PhotoSetupCard extends StatelessWidget {
  const _PhotoSetupCard({
    required this.pet,
    required this.onAdd,
    required this.onReplace,
  });

  final PetModel? pet;
  final VoidCallback onAdd;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          if (pet == null)
            CircleAvatar(
              radius: 36,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.add_a_photo, color: cs.onPrimaryContainer),
            )
          else
            PetAvatar(pet: pet!, size: 72, showActiveBadge: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet == null ? '팝업에 뜰 사진을 정해주세요' : '현재 팝업 사진: ${pet!.name}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '이 대표 사진이 제한 시간 초과 시 화면 위에 나타나요.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: pet == null ? onAdd : onReplace,
            child: Text(pet == null ? '설정' : '교체'),
          ),
        ],
      ),
    );
  }
}

class _PetListItem extends StatelessWidget {
  const _PetListItem({
    required this.pet,
    required this.onTap,
    required this.onReplace,
    required this.onDelete,
  });

  final PetModel pet;
  final VoidCallback onTap;
  final VoidCallback onReplace;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: PetAvatar(pet: pet, size: 54),
        title: Text(pet.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(pet.isActive ? '실제 팝업에 쓰는 대표 사진' : '탭해서 대표 사진으로 설정'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'replace') onReplace();
            if (value == 'delete') onDelete?.call();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'replace', child: Text('사진 교체')),
            if (onDelete != null)
              const PopupMenuItem(value: 'delete', child: Text('삭제')),
          ],
          icon: pet.isActive
              ? Icon(Icons.check_circle, color: cs.primary)
              : const Icon(Icons.more_vert),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text('아직 사진이 없어요. 실제 팝업에 쓸 사진을 추가해보세요.')),
    );
  }
}
