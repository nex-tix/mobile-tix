import 'models/checkpoint.dart';

/// Dummy checkpoints. No network: the station list is authored here so the UI can be
/// reviewed with realistic copy.
const List<Checkpoint> dummyCheckpoints = [
  Checkpoint(
    id: 'gate-1',
    gate: 'Gate 1',
    name: 'Pintu Masuk Utama',
    note: 'Shift pagi · 2 petugas',
    scansToday: 128,
  ),
  Checkpoint(
    id: 'gate-2',
    gate: 'Gate 2',
    name: 'Pintu Masuk Selatan',
    note: 'Shift pagi · 1 petugas',
    scansToday: 74,
  ),
  Checkpoint(
    id: 'gate-3',
    gate: 'Gate 3',
    name: 'Pintu Masuk Barat',
    note: 'Ditutup sampai 12.00',
    open: false,
    scansToday: 0,
  ),
];

Checkpoint get defaultCheckpoint => dummyCheckpoints.first;
