import 'package:flutter/foundation.dart';

/// A gate a staff member can be stationed at.
@immutable
class Checkpoint {
  const Checkpoint({
    required this.id,
    required this.gate,
    required this.name,
    required this.note,
    this.open = true,
    this.scansToday = 0,
  });

  final String id;
  final String gate;
  final String name;

  /// Operational note under the gate name — shift, staffing.
  final String note;

  /// Whether the gate is operating this shift. A closed gate stays selectable but is
  /// flagged, because the operator may be posted there before it opens.
  final bool open;
  final int scansToday;

  String get label => '$gate\n$name';
}
