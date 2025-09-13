import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezip/models/listing.dart';

/// ===== Favorites State =====
/// - favoriteIds: 영구 저장(SharedPreferences)
/// - favoriteItems: 메모리 캐시(화면 즉시 반영용)
// 최근 본 방 (세션/로컬 캐시)
final recentViewed = ValueNotifier<List<Listing>>(<Listing>[]);

void markViewed(Listing item, {int maxItems = 20}) {
  final list = List<Listing>.from(recentViewed.value);
  list.removeWhere((e) => e.id == item.id); // 중복 제거
  list.insert(0, item);                     // 최신이 앞
  if (list.length > maxItems) list.removeRange(maxItems, list.length);
  recentViewed.value = list;
}

void clearRecent() {
  recentViewed.value = <Listing>[];
}

final favoriteIds = ValueNotifier<Set<int>>(<int>{});
final favoriteItems = ValueNotifier<Map<int, Listing>>({});
const _kFavIdsKey = 'fav_ids';

/// 앱 시작 시 한 번 호출해서 로드
Future<void> initAppState() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_kFavIdsKey) ?? const <String>[];
  final ids = raw.map(int.parse).toSet();
  favoriteIds.value = ids;
}

/// 내부 저장 헬퍼
Future<void> _persistFavIds() async {
  final prefs = await SharedPreferences.getInstance();
  final list = favoriteIds.value.map((e) => e.toString()).toList();
  await prefs.setStringList(_kFavIdsKey, list);
}

/// 즐겨찾기 토글 (id만 아는 경우)
void toggleFavorite(int id) {
  final cur = favoriteIds.value;
  if (cur.contains(id)) {
    removeFavorite(id);
  } else {
    favoriteIds.value = {...cur, id};
    _persistFavIds();
    // 아이템 정보가 없을 수 있으니 favoriteItems는 건드리지 않음
  }
}

/// 즐겨찾기 토글 (Listing 정보를 함께 가진 경우)
void toggleFavoriteWithItem(Listing item) {
  final cur = favoriteIds.value;
  if (cur.contains(item.id)) {
    removeFavorite(item.id);
  } else {
    favoriteIds.value = {...cur, item.id};
    favoriteItems.value = {...favoriteItems.value, item.id: item};
    _persistFavIds();
  }
}

/// 찜 해제
void removeFavorite(int id) {
  final ids = {...favoriteIds.value}..remove(id);
  favoriteIds.value = ids;

  final map = {...favoriteItems.value}..remove(id);
  favoriteItems.value = map;

  _persistFavIds();
}

/// 유틸
bool isFavorite(int id) => favoriteIds.value.contains(id);
/// ===== Auth =====
final isLoggedIn = ValueNotifier<bool>(false);
const _kLoggedInKey = 'logged_in';

/// 편의 함수
Future<void> setLoggedIn(bool v) async {
  isLoggedIn.value = v;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kLoggedInKey, v);
}
