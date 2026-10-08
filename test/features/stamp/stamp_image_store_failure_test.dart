import 'package:anitrail/features/stamp/services/stamp_image_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'failed writes are reported and cannot be reused from the preferences cache',
    () async {
      var writes = 0;
      var throwOnWrite = false;
      var failReads = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            (call) async {
              if (call.method.startsWith('getAll')) {
                if (failReads) throw PlatformException(code: 'read_failed');
                return <String, Object>{};
              }
              if (call.method == 'setInt') {
                writes++;
                if (throwOnWrite) throw PlatformException(code: 'write_failed');
                return false;
              }
              throw StateError('Unexpected call: ${call.method}');
            },
          );
      final store = StampImageStore();
      await expectLater(store.imageNumberFor('spot'), throwsStateError);
      await expectLater(store.imageNumberFor('spot'), throwsStateError);
      expect(writes, 2);
      throwOnWrite = true;
      await expectLater(
        store.imageNumberFor('spot'),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(
        store.imageNumberFor('spot'),
        throwsA(isA<PlatformException>()),
      );
      expect(writes, 4);
      throwOnWrite = false;
      failReads = true;
      await expectLater(
        store.imageNumberFor('spot'),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(
        store.imageNumberFor('spot'),
        throwsA(isA<PlatformException>()),
      );
      expect(
        writes,
        5,
      ); // Failed reload must block reuse of the cached selection.
      failReads = false;
      await expectLater(store.imageNumberFor('spot'), throwsStateError);
      expect(writes, 6);
    },
  );
}
