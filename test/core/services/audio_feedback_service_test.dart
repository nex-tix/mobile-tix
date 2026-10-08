// File: audio_feedback_service_test.dart
// Unit test AudioFeedbackService (Commit 8.1)

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/services/audio_feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioFeedbackService Tests', () {
    late AudioFeedbackService service;

    setUp(() {
      service = AudioFeedbackService.instance;
    });

    test('singleton instance returns identical reference', () {
      expect(AudioFeedbackService(), same(AudioFeedbackService.instance));
    });

    test('initialize succeeds without exception', () async {
      await expectLater(service.initialize(), completes);
    });

    test('playSuccess completes without error', () async {
      await expectLater(service.playSuccess(), completes);
    });

    test('playError completes without error', () async {
      await expectLater(service.playError(), completes);
    });

    test('dispose completes cleanly', () async {
      await expectLater(service.dispose(), completes);
    });
  });
}
