import 'package:flutter/material.dart';
import 'package:ezip/state/app_state.dart';
import 'package:ezip/shared/widgets/ezip_logo.dart';
import 'package:ezip/shared/widgets/listing_card.dart';
// import 'package:ezip/data/listing.dart';
import 'package:ezip/models/listing.dart';
import 'package:ezip/api/api_client.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  // 베이스 URL 설정 (dart-define로도 주입 가능)
  static const String _kBaseUrl =
  String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.ezip.kro.kr/api/v1/');
  static final ApiClient _api = ApiClient(_kBaseUrl);

  // 찜 ID로 상세 N건 병렬 로드(실패한 건 스킵)
  Future<List<Listing>> _fetchFavs(Set<int> ids) async {
    if (ids.isEmpty) return const <Listing>[];

    final results = await Future.wait(ids.map((id) async {
      try {
        final item = await _api.getRoomDetail(id); // Future<Listing>
        return item;                               // Listing -> Listing?
      } catch (_) {
        return null; // 실패한 항목은 스킵
      }
    }));

    final list = results.whereType<Listing>().toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('favoriteIds hash (FavoritesPage): ${identityHashCode(favoriteIds)}');

    return Scaffold(
      appBar: const FavoritesAppBar(),
      body: ValueListenableBuilder<Set<int>>(
        valueListenable: favoriteIds,
        builder: (context, favSet, _) {
          if (favSet.isEmpty) {
            return const Center(child: Text('아직 찜한 매물이 없어요'));
          }

          return FutureBuilder<List<Listing>>(
            future: _fetchFavs(favSet),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('불러오기 실패: ${snap.error}'));
              }
              final favs = snap.data ?? const <Listing>[];
              if (favs.isEmpty) {
                return const Center(child: Text('찜한 매물을 찾지 못했어요'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: favs.length,
                itemBuilder: (context, i) {
                  final item = favs[i];
                  final likedNow = favSet.contains(item.id);
                  return ListingCard(
                    key: ValueKey(item.id),
                    item: item,
                    isSelected: false,
                    liked: likedNow,
                    onTap: () {},
                    onLikeToggle: () => toggleFavorite(item.id),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class FavoritesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FavoritesAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 12,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const EzipLogoLarge(),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 20, color: Colors.pink),
                  const SizedBox(width: 6),
                  Text(
                    '찜',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFE6E6E6)),
      ),
    );
  }
}