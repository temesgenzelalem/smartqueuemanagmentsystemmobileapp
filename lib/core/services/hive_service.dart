import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

class HiveService {
  static Box<dynamic>? _cacheBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox<dynamic>(AppConstants.hiveBoxCache);
  }

  static Box<dynamic> get cacheBox {
    final box = _cacheBox;
    if (box == null || !box.isOpen) {
      throw StateError('HiveService not initialized. Call HiveService.init() first.');
    }
    return box;
  }

  static Future<void> put(String key, dynamic value) async {
    await cacheBox.put(key, value);
  }

  static T? get<T>(String key) {
    final value = cacheBox.get(key);
    if (value is T) return value;
    return null;
  }

  static Future<void> delete(String key) async {
    await cacheBox.delete(key);
  }
}
