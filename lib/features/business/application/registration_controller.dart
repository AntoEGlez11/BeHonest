import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../map/application/map_controller.dart';
import '../data/business_repository.dart';

import '../domain/business.dart';

class RegistrationState {
// ... state class is fine ...
  final String? selectedCategory;
  final bool isSubmitting;
  final String? error;
  final double? lat;
  final double? lng;
  final List<String> amenities;
  final bool isAutoDetected;

  RegistrationState({
    this.selectedCategory, 
    this.isSubmitting = false, 
    this.error,
    this.lat,
    this.lng,
    this.amenities = const [],
    this.isAutoDetected = false,
  });

  RegistrationState copyWith({
    String? selectedCategory, 
    bool? isSubmitting, 
    String? error,
    double? lat,
    double? lng,
    List<String>? amenities,
    bool? isAutoDetected,
  }) {
    return RegistrationState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      amenities: amenities ?? this.amenities,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
    );
  }
}

class RegistrationController extends StateNotifier<RegistrationState> {
  final BusinessRepository _repository;

  RegistrationController(this._repository, double? initialLat, double? initialLng) 
      : super(RegistrationState(lat: initialLat, lng: initialLng));

  // "AI" Prediction Logic
  void predictCategory(String name) {
    if (name.isEmpty) return;
    
    final lower = name.toLowerCase();
    String? category;
    
    if (lower.contains('taco') || lower.contains('food') || lower.contains('restaurante') || lower.contains('pizza') || lower.contains('burger')) {
      category = 'Restaurant';
    } else if (lower.contains('taller') || lower.contains('auto') || lower.contains('mechanic')) {
      category = 'Mechanic';
    } else if (lower.contains('tienda') || lower.contains('market') || lower.contains('oxxo') || lower.contains('7-eleven')) {
      category = 'Store';
    } else if (lower.contains('bici') || lower.contains('bike') || lower.contains('cycle')) {
      category = 'Bike Shop';
    } else if (lower.contains('cafe') || lower.contains('coffee') || lower.contains('starbucks')) {
      category = 'Cafe';
    }

    if (category != null && category != state.selectedCategory) {
      state = state.copyWith(selectedCategory: category, isAutoDetected: true);
    }
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category, isAutoDetected: false, error: null);
  }

  void toggleAmenity(String amenity) {
    final current = List<String>.from(state.amenities);
    if (current.contains(amenity)) {
      current.remove(amenity);
    } else {
      current.add(amenity);
    }
    state = state.copyWith(amenities: current);
  }

  void setLocation(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng, error: null);
  }

  Future<bool> submit() async {
    if (state.selectedCategory == null) {
      state = state.copyWith(error: "Please help us categorize this place.");
      return false;
    }
    // ... rest of submit logic
    // Using simple createBusiness for now
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final newBusiness = Business(
        id: const Uuid().v4(),
        name: "New Place", // TODO: Pass name from UI
        category: state.selectedCategory!,
        latitude: state.lat!,
        longitude: state.lng!,
        description: 'Added by community',
        score: 0.0,
        amenities: state.amenities,
      );

      await _repository.createBusiness(newBusiness);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint("Registration Error: $e");
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final registrationControllerProvider = StateNotifierProvider.autoDispose<RegistrationController, RegistrationState>((ref) {
  final mapState = ref.watch(mapControllerProvider);
  final repo = ref.watch(businessRepositoryProvider);
  
  return RegistrationController(repo, mapState.userLocation?.latitude, mapState.userLocation?.longitude);
});
