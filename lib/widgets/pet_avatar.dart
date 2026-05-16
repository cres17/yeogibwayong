import 'dart:io';

import 'package:flutter/material.dart';

import '../data/models/pet_model.dart';

class PetAvatar extends StatelessWidget {
  final PetModel pet;
  final double size;
  final bool showActiveBadge;

  const PetAvatar({
    super.key,
    required this.pet,
    this.size = 80,
    this.showActiveBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ringWidth = size * 0.06;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (pet.isActive && showActiveBadge)
          Container(
            width: size + ringWidth * 2,
            height: size + ringWidth * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
            ),
          ),
        ClipOval(
          child: _PetImage(
            imagePath: pet.imagePath,
            size: size,
          ),
        ),
        if (pet.isActive && showActiveBadge)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                color: colorScheme.onPrimary,
                size: size * 0.16,
              ),
            ),
          ),
      ],
    );
  }
}

class _PetImage extends StatelessWidget {
  final String imagePath;
  final double size;

  const _PetImage({required this.imagePath, required this.size});

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    return file.existsSync()
        ? Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(context),
          )
        : _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.pets,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
