import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AssetCopyService {
  AssetCopyService._();
  static final AssetCopyService instance = AssetCopyService._();

  static const _defaultPetAsset = 'assets/images/pets/default_pet.png';
  static const _defaultPetFilename = 'default_pet.png';
  static const _copiedKey = 'default_pet_copied';

  // Returns the absolute path to the default pet image in documents dir.
  // Copies it from assets on first call.
  Future<String> ensureDefaultPetCopied() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();
    final petsDir = Directory('${dir.path}/pets');
    if (!petsDir.existsSync()) petsDir.createSync(recursive: true);

    final destPath = '${petsDir.path}/$_defaultPetFilename';

    if (prefs.getBool(_copiedKey) != true || !File(destPath).existsSync()) {
      final bytes = await rootBundle.load(_defaultPetAsset);
      await File(destPath).writeAsBytes(bytes.buffer.asUint8List());
      await prefs.setBool(_copiedKey, true);
    }

    return destPath;
  }
}
