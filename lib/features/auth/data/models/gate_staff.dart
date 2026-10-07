import 'package:flutter/foundation.dart';

/// The signed-in gate staff member.
@immutable
class GateStaff {
  const GateStaff({
    required this.name,
    required this.role,
    required this.initials,
    required this.employeeId,
    required this.shift,
  });

  final String name;
  final String role;
  final String initials;
  final String employeeId;
  final String shift;
}

const GateStaff dummyStaff = GateStaff(
  name: 'Admin Gate',
  role: 'Gate Staff',
  initials: 'AG',
  employeeId: 'GT-0182',
  shift: 'Shift pagi · 07.00–15.00',
);
