import 'models/checkpoint.dart';

/// Dummy checkpoints. No network: the station list is authored here so the UI can be
/// reviewed with realistic copy.
const List<Checkpoint> dummyCheckpoints = [
  Checkpoint(
    id: '1',
    gate: 'Gerbang Utama',
    name: 'Pintu Masuk Utama',
    note: 'Shift aktif · 2 petugas',
    scansToday: 0,
  ),
  Checkpoint(
    id: '2',
    gate: 'Gerbang Selatan',
    name: 'Pintu Masuk Selatan',
    note: 'Shift aktif · 1 petugas',
    scansToday: 0,
  ),
  Checkpoint(
    id: '3',
    gate: 'Gerbang Barat',
    name: 'Pintu Masuk Barat',
    note: 'Ditutup sampai 12.00',
    open: false,
    scansToday: 0,
  ),
];

Checkpoint get defaultCheckpoint => dummyCheckpoints.first;
