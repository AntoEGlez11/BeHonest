import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business/domain/business.dart';
import '../../discovery/domain/taxonomy.dart';
import '../../map/presentation/widgets/rating_modal.dart';
import '../../map/providers/business_provider.dart';
import '../application/visit_service.dart';

class BusinessSheet extends ConsumerWidget {
  final Business business;

  const BusinessSheet({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is close enough to rate
    final isNearby = ref.watch(isWithinRangeProvider(business));

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Dark Slate
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Stack(
            children: [
              ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // 1. Cover Image (Gallery Placeholder)
                  _buildGallery(context),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Header (Name, Rating, Category)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                business.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (business.score != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.black),
                                    const SizedBox(width: 4),
                                    Text(
                                      business.score!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    )
                                  ],
                                ),
                              )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            Text(
                              business.category.toUpperCase(),
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            if (business.vibe != Vibe.unknown)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: business.vibe.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: business.vibe.color, width: 0.5),
                                ),
                                child: Text(
                                  business.vibe.label.toUpperCase(),
                                  style: TextStyle(color: business.vibe.color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 3. Quick Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ActionButton(icon: Icons.directions, label: 'Go', onTap: () {}),
                            _ActionButton(icon: Icons.call, label: 'Call', onTap: business.phone != null ? () {} : null),
                            _ActionButton(icon: Icons.language, label: 'Web', onTap: business.website != null ? () {} : null),
                            _ActionButton(icon: Icons.share, label: 'Share', onTap: () {}),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 4. Info Section (Address, Hours)
                        if (business.address != null) ...[
                          _InfoRow(icon: Icons.location_on, text: business.address!),
                          const SizedBox(height: 16),
                        ],
                        if (business.openingHoursDisplay != null) ...[
                          _InfoRow(icon: Icons.access_time, text: business.openingHoursDisplay!, color: Colors.greenAccent),
                          const SizedBox(height: 16),
                        ],

                         // 5. Amenities
                        if (business.amenities.isNotEmpty) ...[
                          const Text('Amenities', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: business.amenities.map((tag) => Chip(
                              label: Text(tag.replaceAll('_', ' ').toUpperCase()),
                              backgroundColor: Colors.white10,
                              labelStyle: const TextStyle(fontSize: 10, color: Colors.white),
                            )).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 6. Description
                        if (business.description != null) ...[
                          Text(
                            business.description!,
                            style: const TextStyle(color: Colors.white70, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 7. CTA: Rate
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isNearby 
                                ? () {
                                    Navigator.pop(context);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => RatingModal(business: business),
                                    );
                                  }
                                : null, // Disabled if too far
                            icon: Icon(isNearby ? Icons.rate_review : Icons.location_off),
                            label: Text(isNearby ? 'Rate this Place' : 'Get closer to rate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGallery(BuildContext context) {
    if (business.photos.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.white10,
        child: const Center(child: Icon(Icons.store, size: 64, color: Colors.white24)),
      );
    }
    
    return SizedBox(
      height: 250,
      child: PageView(
        children: business.photos.map((url) => Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_,__,___) => Container(color: Colors.grey),
        )).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
               color: enabled ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.white10,
               shape: BoxShape.circle,
               border: Border.all(color: enabled ? Colors.blueAccent : Colors.transparent),
            ),
            child: Icon(icon, color: enabled ? Colors.blueAccent : Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: enabled ? Colors.white : Colors.grey, fontSize: 12))
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white54),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: color ?? Colors.white70))),
      ],
    );
  }
}
