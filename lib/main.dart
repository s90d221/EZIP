import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'core/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EZIPApp());
}




/// ===== 전역 상태 =====
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
final ValueNotifier<int> favoritesVersion = ValueNotifier(0);
const kBrandBlue = Color(0xFF4F7DF3);

// 전역 즐겨찾기 상태: 매물 id를 담는 Set
final ValueNotifier<Set<int>> favoriteIds = ValueNotifier(<int>{});

// 즐겨찾기 토글 헬퍼
void toggleFavorite(int id) {
  final next = Set<int>.from(favoriteIds.value);
  if (!next.add(id)) next.remove(id); // 이미 있으면 제거
  favoriteIds.value = next;           // 구독자들 전부 리빌드
  favoritesVersion.value++;           // (있으면) 기존 빌더들도 같이 깨우기
}


