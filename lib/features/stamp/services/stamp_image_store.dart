import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// This device's persistent, randomly selected stamp for each spot.
class StampImageStore {
  static final instance = StampImageStore();
  static const _keyPrefix = 'stamp_image_v1.';
  final Random _random;
  final Map<String, Future<int>> _pending = {};

  Future<void>? _tail;
  bool _needsReload = false;

  StampImageStore({Random? random}) : _random = random ?? Random();

  Future<int> imageNumberFor(String spotId) {
    if (spotId.isEmpty) {
      return Future.error(
        ArgumentError.value(spotId, 'spotId', 'must not be empty'),
      );
    }
    return _pending.putIfAbsent(spotId, () {
      // Serialize preference access, including reloads after failed writes.
      final result = (_tail ?? Future<void>.value()).then(
        (_) => _loadOrSelect(spotId),
      );
      _tail = result.then<void>(
        (_) {
          _pending.remove(spotId);
          if (_pending.isEmpty) _tail = null;
        },
        onError: (Object error, StackTrace stack) {
          _pending.remove(spotId);
          if (_pending.isEmpty) _tail = null;
        },
      );
      return result;
    });
  }

  Future<int> _loadOrSelect(String spotId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_needsReload) {
      await prefs.reload();
      _needsReload = false;
    }
    final key = '$_keyPrefix$spotId';
    final saved = prefs.getInt(key);
    if (saved != null) {
      if (saved < 1 || saved > 4) {
        throw StateError('Invalid saved stamp image for $spotId');
      }
      return saved;
    }
    final selected = _random.nextInt(4) + 1;
    try {
      if (!await prefs.setInt(key, selected)) {
        throw StateError('Could not save stamp image for $spotId');
      }
    } catch (_) {
      // SharedPreferences updates its cache before writing to disk.
      // Reload so an unsuccessful selection cannot be reused as saved data.
      _needsReload = true;
      await prefs.reload();
      _needsReload = false;
      rethrow;
    }
    return selected;
  }

  static String assetPath(int imageNumber) =>
      'assets/images/stamp${imageNumber.toString().padLeft(2, '0')}.png';
}
