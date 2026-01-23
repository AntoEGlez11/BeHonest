import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../application/registration_controller.dart';
import 'package:latlong2/latlong.dart';

class RegistrationModal extends ConsumerStatefulWidget {
  final LatLng? selectedLocation;

  const RegistrationModal({super.key, this.selectedLocation});

  @override
  ConsumerState<RegistrationModal> createState() => _RegistrationModalState();
}

class _RegistrationModalState extends ConsumerState<RegistrationModal> {
  final TextEditingController _nameController = TextEditingController();
  
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
        color: Color(0xFF1E293B), // Slate 900
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      // Use constrained height for wizard feel
      height: 550, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header
          const Text( 
            'What did you find?', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 1. SMART INPUT (The Core)
          TextField(
            controller: _nameController,
            onChanged: (val) => controller.predictCategory(val),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'E.g. "Tacos El Paisa"',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.black26,
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          
          const SizedBox(height: 32),

          // 2. LIVE PREVIEW (The Magic)
          Center(
             child: _buildLiveIconPreview(state),
          ),

          const SizedBox(height: 32),

          // 3. AMENITIES (Quick Tags)
          if (state.selectedCategory != null) ...[
            const Text('Quick Details', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AmenityChip(label: 'WiFi', icon: Icons.wifi, selected: state.amenities.contains('wifi'), onTap: () => controller.toggleAmenity('wifi')),
                _AmenityChip(label: 'Cards', icon: Icons.credit_card, selected: state.amenities.contains('card'), onTap: () => controller.toggleAmenity('card')),
                _AmenityChip(label: 'Open Now', icon: Icons.schedule, selected: state.amenities.contains('open_now'), onTap: () => controller.toggleAmenity('open_now')),
              ],
            ),
          ],

          const Spacer(),

          // 4. SUBMIT
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (state.selectedCategory == null || state.isSubmitting) 
                  ? null 
                  : () async {
                      final success = await controller.submit();
                      if (success && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Row(
                               children: [
                                 const Icon(Icons.check_circle, color: Colors.green),
                                 const SizedBox(width: 8),
                                 Text('Added "${_nameController.text}" to the map!'),
                               ],
                             ),
                             backgroundColor: Colors.black87,
                             behavior: SnackBarBehavior.floating,
                           ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: state.isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.selectedCategory == null ? 'Name the place...' : 'Add ${state.selectedCategory}'),
                        if (state.selectedCategory != null) const SizedBox(width: 8),
                         if (state.selectedCategory != null) const Icon(Icons.arrow_forward),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16), // Bottom safe area
        ],
      ),
    );
  }

  Widget _buildLiveIconPreview(RegistrationState state) {
    IconData icon = Icons.question_mark;
    Color color = Colors.grey;
    String label = 'Unknown';

    if (state.selectedCategory != null) {
      if (state.selectedCategory == 'Restaurant') { icon = Icons.restaurant; color = Colors.redAccent; }
      else if (state.selectedCategory == 'Mechanic') { icon = Icons.car_repair; color = Colors.orange; }
      else if (state.selectedCategory == 'Store') { icon = Icons.shopping_bag; color = Colors.purple; }
      else if (state.selectedCategory == 'Bike Shop') { icon = Icons.pedal_bike; color = Colors.teal; }
      else if (state.selectedCategory == 'Cafe') { icon = Icons.local_cafe; color = Colors.brown; }
      label = state.selectedCategory!;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: 400.ms,
          curve: Curves.easeOutBack,
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              if (state.selectedCategory != null)
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Icon(icon, size: 50, color: color)
              .animate(target: state.selectedCategory != null ? 1 : 0)
              .shake(hz: 4, curve: Curves.easeInOut), // Shake when detected
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: 300.ms,
          child: Text(
            state.isAutoDetected ? '✨ AI Detected: $label' : label,
            key: ValueKey(label),
            style: TextStyle(
              color: state.isAutoDetected ? Colors.amber : Colors.white70, 
              fontWeight: FontWeight.bold,
              fontSize: 16
            ),
          ),
        )
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AmenityChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.blueAccent : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
