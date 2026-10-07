import 'package:flutter/material.dart';

import '../../data/models/checkpoint.dart';

/// Checkpoint option card based on `newDesign/2._checkpoint_selection/code.html`.
///
/// Features:
/// - Dark teal card surface (`#212B2F`)
/// - Leading lock icon & gate title
/// - Glowing Gold outline and custom radio button when selected
class CheckpointTile extends StatelessWidget {
  const CheckpointTile({
    super.key,
    required this.checkpoint,
    required this.selected,
    required this.onTap,
  });

  final Checkpoint checkpoint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF212B2F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? const Color(0xFFF5D061) : const Color(0xFF3E4E55),
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Leading Lock Icon
                const Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: Color(0xFFA3B1B7),
                ),
                const SizedBox(width: 14),

                // Gate Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            checkpoint.gate,
                            style: const TextStyle(
                              fontFamily: 'Barlow',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF8F6F6),
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (!checkpoint.open) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x33CF4647),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DITUTUP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFCF4647),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (checkpoint.name.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          checkpoint.name,
                          style: const TextStyle(
                            fontFamily: 'Barlow',
                            fontSize: 12.5,
                            color: Color(0xFFA3B1B7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Radio Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFF5D061)
                          : const Color(0xFF3E4E55),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: selected ? 10 : 0,
                      height: selected ? 10 : 0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5D061),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
