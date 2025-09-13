import 'package:flutter/foundation.dart';

/// 로그인 여부
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

/// 전역 즐겨찾기: 매물 id Set
final ValueNotifier<Set<int>> favoriteIds = ValueNotifier(<int>{});

void toggleFavorite(int id) {
  // 항상 새 Set을 만들어 할당
  final next = {...favoriteIds.value};
  if (next.contains(id)) {
    next.remove(id);
  } else {
    next.add(id);
  }
  favoriteIds.value = next;
}
