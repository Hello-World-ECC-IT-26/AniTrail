import 'package:shared_preferences/shared_preferences.dart';
import '../models/tour_plan.dart';

abstract interface class TourPlanStore {
  Future<TourPlan> load(String userId, String cardId);
  Future<void> save(String userId, String cardId, TourPlan plan);
}

class LocalTourPlanStore implements TourPlanStore {
  String _key(String userId, String cardId) =>
      'shiori_tour_v1:${Uri.encodeComponent(userId)}:${Uri.encodeComponent(cardId)}';

  @override
  Future<TourPlan> load(String userId, String cardId) async {
    final prefs = await SharedPreferences.getInstance();
    return TourPlan(prefs.getStringList(_key(userId, cardId)) ?? const []);
  }

  @override
  Future<void> save(String userId, String cardId, TourPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(_key(userId, cardId), plan.spotIds);
    if (!saved) throw const FormatException('巡る順番を保存できませんでした');
  }
}
