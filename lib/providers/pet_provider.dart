import 'package:flutter/foundation.dart';

import '../data/models/pet_model.dart';
import '../data/repositories/pet_repository.dart';
import '../data/repositories/settings_repository.dart';

class PetProvider extends ChangeNotifier {
  final PetRepository _petRepo;
  final SettingsRepository _settingsRepo;

  PetProvider(this._petRepo, this._settingsRepo);

  List<PetModel> _pets = [];
  PetModel? _activePet;
  bool _loading = false;

  List<PetModel> get pets => _pets;
  PetModel? get activePet => _activePet;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _pets = await _petRepo.getAll();
    _activePet = await _petRepo.getActive();
    _loading = false;
    notifyListeners();
  }

  Future<void> setActivePet(int id) async {
    await _petRepo.setActive(id);
    await _settingsRepo.setSelectedPetId(id);
    _activePet = _pets.where((p) => p.id == id).firstOrNull;
    _pets = _pets
        .map(
          (p) => PetModel(
            id: p.id,
            name: p.name,
            type: p.type,
            imagePath: p.imagePath,
            isActive: p.id == id,
            createdAt: p.createdAt,
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<int> addPet(PetModel pet) async {
    final id = await _petRepo.insert(pet);
    final inserted = PetModel(
      id: id,
      name: pet.name,
      type: pet.type,
      imagePath: pet.imagePath,
      isActive: pet.isActive,
      createdAt: pet.createdAt,
    );
    _pets = [..._pets, inserted];
    notifyListeners();
    return id;
  }

  Future<void> updatePetPhoto(int id, String imagePath) async {
    await _petRepo.updateImagePath(id, imagePath);
    _pets = _pets
        .map(
          (p) => p.id == id
              ? PetModel(
                  id: p.id,
                  name: p.name,
                  type: p.type,
                  imagePath: imagePath,
                  isActive: p.isActive,
                  createdAt: p.createdAt,
                )
              : p,
        )
        .toList();
    if (_activePet?.id == id) {
      final current = _activePet!;
      _activePet = PetModel(
        id: current.id,
        name: current.name,
        type: current.type,
        imagePath: imagePath,
        isActive: current.isActive,
        createdAt: current.createdAt,
      );
    }
    notifyListeners();
  }

  Future<void> deletePet(int id) async {
    await _petRepo.delete(id);
    await load();
    if (_activePet?.id != null) {
      await _settingsRepo.setSelectedPetId(_activePet!.id!);
    }
  }
}
