import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/registration_controller.dart';

import 'package:latlong2/latlong.dart';

class RegistrationModal extends ConsumerStatefulWidget {
  final LatLng? selectedLocation;

  const RegistrationModal({super.key, this.selectedLocation});

  @override
  ConsumerState<RegistrationModal> createState() => _RegistrationModalState();
}

class _RegistrationModalState extends ConsumerState<RegistrationModal> {
  @override
  void initState() {
    super.initState();
    if (widget.selectedLocation != null) {
      Future.microtask(() {
        ref.read(registrationControllerProvider.notifier).setLocation(
          widget.selectedLocation!.latitude,
          widget.selectedLocation!.longitude,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);
    final controller = ref.read(registrationControllerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What is this place?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CategoryButton(
                icon: '🍔', 
                label: 'Food', 
                isSelected: state.selectedCategory == 'Food',
                onTap: () => controller.selectCategory('Food'),
              ),
              _CategoryButton(
                icon: '🔧', 
                label: 'Service', 
                isSelected: state.selectedCategory == 'Service',
                onTap: () => controller.selectCategory('Service'),
              ),
              _CategoryButton(
                icon: '🏪', 
                label: 'Store', 
                isSelected: state.selectedCategory == 'Store',
                onTap: () => controller.selectCategory('Store'),
              ),
            ],
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: state.isSubmitting 
                  ? null 
                  : () async {
                      final success = await controller.submit();
                      if (success && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Business registered!')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: state.isSubmitting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add Business'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.icon, 
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF374151),
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
