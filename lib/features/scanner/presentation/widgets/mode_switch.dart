import 'package:flutter/material.dart';

import '../../../../shared/widgets/segmented_switch.dart';
import '../../data/models/scan_outcome.dart';

/// CHECK-IN | CEK — the two jobs the scanner can do, on the shared segmented control.
class ModeSwitch extends StatelessWidget {
  const ModeSwitch({super.key, required this.mode, required this.onChanged});

  final ScanMode mode;
  final ValueChanged<ScanMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedSwitch(
      labels: [for (final option in ScanMode.values) option.label],
      index: ScanMode.values.indexOf(mode),
      onChanged: (index) => onChanged(ScanMode.values[index]),
    );
  }
}
