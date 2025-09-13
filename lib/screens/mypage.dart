import 'package:flutter/material.dart';
import 'package:ezip/shared/widgets/ezip_logo.dart';
import 'package:ezip/state/app_state.dart';
import 'package:ezip/shared/widgets/listing_card.dart';
import 'package:ezip/api/api_client.dart';
import 'package:ezip/models/listing.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyPageAppBar(),
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            indicatorPadding: EdgeInsets.zero,
            tabs: const [
              Tab(text: '최근 본 방'),
              Tab(text: '찜한 방'),
              Tab(text: '매너평가'),
              Tab(text: '계약정보'),
              Tab(text: '내 정보'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _RecentViewTab(),
                _FavTab(),        // API 연동된 찜 탭
                _MannerTab(),
                _ContractTab(),
                _ProfileTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyPageAppBar({super.key});

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
      automaticallyImplyLeading: false, // 탭 구조에서 뒤로가기 화살표 숨김

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EzipLogoLarge(),                // ezip
          const SizedBox(width: 50),
          const Icon(Icons.person_outline,      // 아이콘 + "마이페이지"
              size: 20, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            '마이페이지',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 65),
          IconButton(                           // 지구본(언어)
            icon: const Icon(Icons.language, color: Colors.black87),
            tooltip: '언어',
            onPressed: () async {
              final sel = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: const Text('한국어'), onTap: () => Navigator.pop(ctx, 'ko')),
                      ListTile(title: const Text('English'), onTap: () => Navigator.pop(ctx, 'en')),
                      ListTile(title: const Text('日本語'), onTap: () => Navigator.pop(ctx, 'ja')),
                      ListTile(title: const Text('中文(简体)'), onTap: () => Navigator.pop(ctx, 'zh-CN')),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),

      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFE6E6E6)),
      ),
    );
  }
}

class _RecentViewTab extends StatelessWidget {
  const _RecentViewTab();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('최근 본 방이 아직 없어요.'));
}

/// =====================
/// 찜 탭 (API 연동)
/// =====================
class _FavTab extends StatelessWidget {
  const _FavTab();

  // 베이스 URL (dart-define으로 주입 권장)
  static const String _kBaseUrl =
  String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.ezip.kro.kr/api/v1/');
  static final ApiClient _api = ApiClient(_kBaseUrl);

  /// 찜 ID들로 상세 정보 병렬 조회 (실패 항목은 스킵)
  static Future<List<Listing>> _fetchFavs(Set<int> ids) async {
    if (ids.isEmpty) return const <Listing>[];
    final results = await Future.wait(ids.map((id) async {
      try {
        final item = await _api.getRoomDetail(id); // Future<Listing>
        return item; // OK
      } catch (_) {
        return null; // 404 등은 건너뛰기
      }
    }));
    final list = results.whereType<Listing>().toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: favoriteIds,
      builder: (_, favSet, __) {
        if (favSet.isEmpty) {
          return const Center(child: Text('찜한 방이 없어요.'));
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
              return const Center(child: Text('찜한 방을 찾지 못했어요.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
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
    );
  }
}

class _MannerTab extends StatelessWidget {
  const _MannerTab();
  @override
  Widget build(BuildContext context) {
    final items = [
      {'name': '왕동동 부동산', 'text': '깨끗하게 써줘서 고마워요'},
      {'name': '광주 집주인님', 'text': '정돈 잘해주시네요.'},
      {'name': '내가 쓴 평가', 'text': '조용하고 깔끔해요.'},
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(items[i]['name']!),
        subtitle: Text(items[i]['text']!),
      ),
    );
  }
}

class _ContractTab extends StatelessWidget {
  const _ContractTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        3,
            (i) => Card(
          child: ListTile(
            title: Text('월세 300/35  ·  계약 ${['중','완료','완료'][i]}'),
            subtitle: const Text('충북 청주시 ○○동, 역세권, 6층'),
            trailing: OutlinedButton(onPressed: () {}, child: const Text('계약서 확인')),
          ),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 16),
            const ListTile(title: Text('이메일'), subtitle: Text('user@example.com')),
            const ListTile(title: Text('비밀번호 변경'), trailing: Icon(Icons.chevron_right)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => isLoggedIn.value = false, child: const Text('회원탈퇴')),
          ],
        ),
      ),
    );
  }
}
