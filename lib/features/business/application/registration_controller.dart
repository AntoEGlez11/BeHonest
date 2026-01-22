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

  RegistrationState({
    this.selectedCategory, 
    this.isSubmitting = false, 
    this.error,
    this.lat,
    this.lng,
  });

  RegistrationState copyWith({
    String? selectedCategory, 
    bool? isSubmitting, 
    String? error,
    double? lat,
    double? lng,
  }) {
    return RegistrationState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

class RegistrationController extends StateNotifier<RegistrationState> {
  final BusinessRepository _repository;

  RegistrationController(this._repository, double? initialLat, double? initialLng) 
      : super(RegistrationState(lat: initialLat, lng: initialLng));

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category, error: null);
  }

  void setLocation(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng, error: null);
  }

  Future<bool> submit() async {
    if (state.selectedCategory == null) {
      state = state.copyWith(error: "Please select a category");
      return false;
    }
    if (state.lat == null || state.lng == null) {
      state = state.copyWith(error: "Location not available");
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final newBusiness = Business(
        id: const Uuid().v4(),
        name: "New ${state.selectedCategory}",
        category: state.selectedCategory!,
        latitude: state.lat!,
        longitude: state.lng!,
        description: '',
        score: 0.0, // Initial score
      );

      await _repository.createBusiness(newBusiness);
      
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint("Registration Error: $e");
      final errorMsg = e is PostgrestException 
          ? "Error: ${e.message} \nDetails: ${e.details}" 
          : "Failed to register: ${e.toString()}";
          
      state = state.copyWith(isSubmitting: false, error: errorMsg);
      return false;
    }
  }
}

final registrationControllerProvider = StateNotifierProvider.autoDispose<RegistrationController, RegistrationState>((ref) {
  final mapState = ref.watch(mapControllerProvider);
  final repo = ref.watch(businessRepositoryProvider);
  
  return RegistrationController(repo, mapState.userLocation?.latitude, mapState.userLocation?.longitude);
});
