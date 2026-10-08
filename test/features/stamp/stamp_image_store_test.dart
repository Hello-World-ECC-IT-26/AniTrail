import 'dart:math';

import 'package:anitrail/features/stamp/services/stamp_image_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'selects all four variants and persists each spot across store recreation',
    () async {
      final store = StampImageStore(random: Random(42));
      final selected = <int>{};
      for (var i = 0; i < 40; i++) {
        final id = 'spot-$i';
        final number = await store.imageNumberFor(id);
        expect(number, inInclusiveRange(1, 4));
        selected.add(number);
        expect(await store.imageNumberFor(id), number);
        await (await SharedPreferences.getInstance()).reload();
        expect(await StampImageStore().imageNumberFor(id), number);
      }
      expect(selected, {1, 2, 3, 4});
    },
  );

  test('concurrent requests share one selection', () async {
    final store = StampImageStore(random: Random(7));
    final first = store.imageNumberFor('same-spot');
    final second = store.imageNumberFor('same-spot');
    expect(identical(first, second), isTrue);
    final results = await Future.wait([first, second]);
    expect(results[0], results[1]);
    expect(await StampImageStore().imageNumberFor('same-spot'), results[0]);
  });

  test(
    'invalid stored selection and empty spot ID fail without substitution',
    () async {
      SharedPreferences.setMockInitialValues({'stamp_image_v1.invalid': 5});
      final store = StampImageStore();
      await expectLater(store.imageNumberFor('invalid'), throwsStateError);
      await expectLater(store.imageNumberFor(''), throwsArgumentError);
    },
  );
}
