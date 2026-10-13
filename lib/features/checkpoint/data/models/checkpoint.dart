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

  Map<String, dynamic> toJson() => {
    'id': id,
    'gate': gate,
    'name': name,
    'note': note,
    'open': open,
    'scansToday': scansToday,
  };

  factory Checkpoint.fromJson(Map<String, dynamic> json) => Checkpoint(
    id: json['id']?.toString() ?? '',
    gate: json['gate'] as String? ?? json['name'] as String? ?? 'Gate',
    name: json['location'] as String? ?? json['name'] as String? ?? '',
    note: json['note'] as String? ?? json['location'] as String? ?? 'Aktif',
    open: json['open'] as bool? ?? json['is_active'] as bool? ?? true,
    scansToday: (json['scansToday'] as num?)?.toInt() ?? 0,
  );
}
