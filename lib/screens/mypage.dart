import 'package:flutter/material.dart';
import 'package:ezip/shared/widgets/ezip_logo.dart';
import 'package:ezip/shared/widgets/listing_card.dart';
import 'package:ezip/models/listing.dart';
import 'package:flutter/services.dart';
import 'package:ezip/state/app_state.dart' as fav;
import 'package:ezip/api/api_client.dart';

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
                showDragHandle: true,
                builder: (ctx) => SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        // 10개+ 언어 옵션
                        ListTile(title: Text('한국어'),              dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('English'),            dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('日本語'),               dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('中文(简体)'),            dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('中文(繁體)'),            dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('Español'),            dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('Français'),           dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('Deutsch'),            dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('Português (Brasil)'), dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('Русский'),            dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('Tiếng Việt'),         dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('Bahasa Indonesia'),   dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('ไทย'),                 dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('العربية'),             dense: true, visualDensity: VisualDensity.compact,  ),
                        ListTile(title: Text('हिन्दी'),              dense: true, visualDensity: VisualDensity.compact,  ),
                      ],
                    ),
                  ),
                ),
              );

              // 선택된 로케일 코드 매핑
              if (sel != null) {
                // 선택된 텍스트 -> 코드 매핑
                final map = {
                  '한국어': 'ko',
                  'English': 'en',
                  '日本語': 'ja',
                  '中文(简体)': 'zh-CN',
                  '中文(繁體)': 'zh-TW',
                  'Español': 'es',
                  'Français': 'fr',
                  'Deutsch': 'de',
                  'Português (Brasil)': 'pt-BR',
                  'Русский': 'ru',
                  'Tiếng Việt': 'vi',
                  'Bahasa Indonesia': 'id',
                  'ไทย': 'th',
                  'العربية': 'ar',
                  'हिन्दी': 'hi',
                };

                // 바텀시트에서 받은 건 title 텍스트이므로, 클릭 시 pop할 때 title을 반환하도록 아래처럼 처리하면 돼:
                // → 각 ListTile onTap에서 Navigator.pop(ctx, '<title 텍스트>')
                // 지금은 텍스트 기반으로 처리 예시:
                final code = map[sel] ?? sel;

                try {
                  await setLang(code); // i18n.dart 필요
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('언어가 변경되었어요: $code')),
                  );
                } catch (_) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('언어 변경에 실패했어요')),
                  );
                }
              }
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

  Future<void> setLang(String code) async {}
}


class _RecentViewTab extends StatefulWidget {
  const _RecentViewTab();
  @override
  State<_RecentViewTab> createState() => _RecentViewTabState();
}

class _RecentViewTabState extends State<_RecentViewTab> {
  static const String _kBaseUrl =
  String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.ezip.kro.kr/api/v1/');
  late final ApiClient _api = ApiClient(_kBaseUrl);

  bool _busy = false;
  String? _err;
  List<Listing> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      // 서버에서 최근(?) 목록 대용으로 최신 방 리스트를 가져와 표시
      final list = await _api.getRooms(query: {'page': 0, 'size': 24});
      setState(() => _items = list);
    } catch (e) {
      setState(() => _err = '불러오기 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_err!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.inbox_outlined, size: 56, color: Colors.black26),
              SizedBox(height: 10),
              Text('표시할 방이 아직 없어요', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final cross = w >= 1000 ? 3 : (w >= 640 ? 2 : 1);

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 16 / 10,
            ),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final it = _items[i];
              return _RecentCard(
                listing: it,
                onTap: () {
                  // TODO: 상세 연결 원하면 여기에 push
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => RoomDetailPage(roomId: it.id)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("'${it.shortTitle}' (id=${it.id}) 눌렀어요")),
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

class _RecentCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  const _RecentCard({required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tags = listing.tags;
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // 이미지 + 가격 뱃지
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    listing.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF4F6F8),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.black26),
                      ),
                    ),
                    loadingBuilder: (ctx, child, e) {
                      if (e == null) return child;
                      return Container(
                        color: const Color(0xFFF7F9FB),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        listing.priceLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 텍스트 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타이틀
                    Text(
                      listing.shortTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 메타 (면적/층/관리비)
                    Row(
                      children: [
                        const Icon(Icons.square_foot_outlined, size: 16, color: Colors.black45),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _meta(listing),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 태그 칩
                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: -6,
                        children: [
                          for (final t in tags.take(2)) _MiniChip(text: t),
                          if (tags.length > 2) _MiniChip(text: '+${tags.length - 2}', subtle: true),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _meta(Listing it) {
    final parts = <String>[];
    if (it.area > 0) {
      final noDecimal = it.area.truncateToDouble() == it.area;
      parts.add('${it.area.toStringAsFixed(noDecimal ? 0 : 1)}㎡');
    }
    if (it.floor != 0) parts.add('${it.floor}층');
    if (it.maintenanceFee.isNotEmpty) parts.add('관리비 ${it.maintenanceFee}');
    return parts.join(' · ');
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final bool subtle;
  const _MiniChip({required this.text, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    final color = subtle ? Colors.black38 : const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: subtle ? Colors.black12 : const Color(0xFF2563EB).withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: subtle ? Colors.black26 : const Color(0xFF2563EB).withOpacity(.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}


class _FavTab extends StatelessWidget {
  const _FavTab();

  // FavoritesPage와 동일한 베이스 URL
  static const String _kBaseUrl =
  String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.ezip.kro.kr/api/v1/');
  static final ApiClient _api = ApiClient(_kBaseUrl);

  // 로컬 캐시 + (부족분) API 병합
  Future<List<Listing>> _buildList(Set<int> ids, Map<int, Listing> cache) async {
    if (ids.isEmpty) return const <Listing>[];

    // 1) 캐시에 있는 건 즉시 사용
    final list = <Listing>[];
    final missing = <int>[];
    for (final id in ids) {
      final cached = cache[id];
      if (cached != null) {
        list.add(cached);
      } else {
        missing.add(id);
      }
    }

    // 2) 캐시에 없는 id는 API로 채우기 (실패는 스킵)
    if (missing.isNotEmpty) {
      final fetched = await Future.wait(missing.map((id) async {
        try {
          return await _api.getRoomDetail(id);
        } catch (_) {
          return null;
        }
      }));
      list.addAll(fetched.whereType<Listing>());
    }

    // FavoritesPage와 동일하게 정렬(id 오름차순)
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // 1) 먼저 id 집합을 구독
    return ValueListenableBuilder<Set<int>>(
      valueListenable: fav.favoriteIds,
      builder: (context, idSet, _) {
        if (idSet.isEmpty) {
          return const _FavEmpty(); // 빈 상태 동일
        }

        // 2) 캐시 맵도 구독 → 캐시와 병합해서 렌더
        return ValueListenableBuilder<Map<int, Listing>>(
          valueListenable: fav.favoriteItems,
          builder: (_, cache, __) {
            return FutureBuilder<List<Listing>>(
              future: _buildList(idSet, cache),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('불러오기 실패: ${snap.error}'));
                }
                final items = snap.data ?? const <Listing>[];
                if (items.isEmpty) {
                  return const Center(child: Text('찜한 매물을 찾지 못했어요'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final likedNow = idSet.contains(item.id);
                    return ListingCard
                      (
                      key: ValueKey(item.id),
                      item: item,
                      isSelected: false,
                      liked: likedNow,
                      onTap: () {
                        // TODO: 상세 이동 원하면 연결
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => RoomDetailPage(roomId: item.id)));
                      },
                      // 로컬 상태/캐시 동기화 유지
                      onLikeToggle: () => fav.toggleFavoriteWithItem(item),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}


class _FavEmpty extends StatelessWidget {
  const _FavEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 56, color: Colors.black26),
            const SizedBox(height: 10),
            const Text('아직 찜한 방이 없어요', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                // TODO: 지도 탭으로 이동 로직이 있으면 연결
                // e.g. context.read<TabNav>().goToMap();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('지도에서 마음에 드는 방을 찜해보세요!')),
                );
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('지도에서 방 보러가기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MannerTab extends StatefulWidget {
  const _MannerTab();
  @override
  State<_MannerTab> createState() => _MannerTabState();
}

class _MannerTabState extends State<_MannerTab> {
  final _search = TextEditingController();
  String _filter = '전체'; // 전체 / 받은 평가 / 내가 쓴 평가

  // 데모 데이터 (mine: 내가 쓴 평가인지)
  final List<Map<String, dynamic>> _items = [
    {'name': '왕동동 부동산', 'text': '깨끗하게 써줘서 고마워요', 'mine': false},
    {'name': '광주 집주인님', 'text': '정돈 잘해주시네요.', 'mine': false},
    {'name': '내가 쓴 평가', 'text': '조용하고 깔끔해요.', 'mine': true},
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = _items.where((e) {
      if (_filter == '받은 평가' && e['mine'] == true) return false;
      if (_filter == '내가 쓴 평가' && e['mine'] == false) return false;
      if (q.isEmpty) return true;
      return e['name'].toString().toLowerCase().contains(q) ||
          e['text'].toString().toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ===== 상단 필터 & 검색 =====
        Wrap(
          spacing: 8,
          runSpacing: -6,
          children: [
            ChoiceChip(
              label: const Text('전체'),
              selected: _filter == '전체',
              onSelected: (_) => setState(() => _filter = '전체'),
            ),
            ChoiceChip(
              label: const Text('받은 평가'),
              selected: _filter == '받은 평가',
              onSelected: (_) => setState(() => _filter = '받은 평가'),
            ),
            ChoiceChip(
              label: const Text('내가 쓴 평가'),
              selected: _filter == '내가 쓴 평가',
              onSelected: (_) => setState(() => _filter = '내가 쓴 평가'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '이름 또는 내용을 검색해요',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          _EmptyState(filter: _filter, keyword: q)
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final it = filtered[i];
              final mine = it['mine'] as bool;
              return _MannerCard(
                name: it['name'] as String,
                text: it['text'] as String,
                mine: mine,
              );
            },
          ),
      ],
    );
  }
}

class _MannerCard extends StatelessWidget {
  final String name;
  final String text;
  final bool mine; // 내가 쓴 평가인지

  const _MannerCard({
    required this.name,
    required this.text,
    required this.mine,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = mine ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);
    final badgeText = mine ? '내가 쓴 평가' : '받은 평가';

    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(name: name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단: 이름 + 배지
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _Badge(text: badgeText, color: badgeColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        '방문일: 2025-02-01', // 필요 시 실제 날짜로 교체
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: '도움돼요',
                        icon: const Icon(Icons.thumb_up_off_alt, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('도움돼요!')),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: '신고',
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('신고 접수 (연결 필요)')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final color = _colorFromString(name);
    return CircleAvatar(
      radius: 22,
      backgroundColor: color.withOpacity(.15),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _colorFromString(String s) {
    final h = s.runes.fold<int>(0, (p, c) => p + c) % 360;
    return HSLColor.fromAHSL(1, h.toDouble(), 0.55, 0.45).toColor();
    // 톤은 취향껏 조절 가능 :)
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  final String keyword;
  const _EmptyState({required this.filter, required this.keyword});

  @override
  Widget build(BuildContext context) {
    final msg = keyword.isNotEmpty
        ? '‘$keyword’(으)로 검색된 평가가 없어요'
        : (filter == '전체'
        ? '아직 보여줄 평가가 없어요'
        : '선택한 필터에 해당하는 평가가 없어요');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.black26),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}


class _ContractTab extends StatelessWidget {
  const _ContractTab();

  @override
  Widget build(BuildContext context) {
    final items = List.generate(3, (i) {
      return {
        'price': '월세 300/35',
        'status': ['중', '완료', '완료'][i],
        'address': '충북 청주시 ○○동, 역세권, 6층',
        'period': '2025.03.01 ~ 2026.02.28',
      };
    });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final it = items[i];
        return _ContractCard(
          priceLabel: it['price']!,
          status: it['status']!,
          address: it['address']!,
          period: it['period']!,
          onOpenContract: () {
            // TODO: 계약서 확인 로직 연결
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('계약서를 열었어요 (연결 필요)')),
            );
          },
        );
      },
    );
  }
}

class _ContractCard extends StatelessWidget {
  final String priceLabel; // 예: 월세 300/35
  final String status;     // '중' | '완료'
  final String address;    // 주소 요약
  final String period;     // 계약 기간
  final VoidCallback? onOpenContract;

  const _ContractCard({
    required this.priceLabel,
    required this.status,
    required this.address,
    required this.period,
    this.onOpenContract,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == '완료';
    final badge = _StatusBadge(
      text: isDone ? '완료' : '진행중',
      color: isDone ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
    );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 가격 + 상태 배지
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$priceLabel  ·  계약 ${status}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                badge,
              ],
            ),
            const SizedBox(height: 8),

            // 주소
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 기간
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Text(period, style: const TextStyle(color: Colors.black87)),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE6E6E6)),
            const SizedBox(height: 10),

            // 하단 액션
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onOpenContract,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('계약서 확인'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Spacer(),
                // 필요하면 다른 액션 추가 가능 (예: 영수증, 다운로드 등)
                // TextButton.icon(onPressed: () {}, icon: Icon(Icons.download_outlined), label: Text('다운로드')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        children: [
          Icon(
            text == '완료' ? Icons.check_circle : Icons.autorenew,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              // ===== 헤더 =====
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEEF2FF), Color(0xFFE0F2FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // 장식 원
                    Positioned(
                      right: -24, top: -24,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.25),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, size: 40, color: Colors.black54),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('김치중독자',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                SizedBox(height: 2),
                                Text('user@example.com',
                                    style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ===== 정보 카드 =====
              Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _ProfileField(
                      icon: Icons.badge_outlined,
                      label: '이름',
                      value: 'Kropwiodqpw',
                    ),
                    const Divider(height: 1, color: Color(0xFFE6E6E6)),
                    _ProfileField(
                      icon: Icons.tag_faces_outlined,
                      label: '닉네임',
                      value: '김치중독자',
                    ),
                    const Divider(height: 1, color: Color(0xFFE6E6E6)),
                    _ProfileField(
                      icon: Icons.call_outlined,
                      label: '전화번호',
                      value: '010-8923-3412',
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: '복사',
                        onPressed: () => _copy(context, '010-8923-3412'),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE6E6E6)),
                    _ProfileField(
                      icon: Icons.mail_outline,
                      label: '이메일',
                      value: 'user@example.com',
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: '복사',
                        onPressed: () => _copy(context, 'user@example.com'),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE6E6E6)),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('비밀번호 변경',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('비밀번호 변경 화면으로 이동 (연결 필요)')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===== 위험 동작 =====
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('회원탈퇴'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFEAB8B8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('정말 회원탈퇴 하시겠어요?'),
                        content: const Text('계정 삭제는 되돌릴 수 없어요.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('탈퇴'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      // TODO: 실제 탈퇴 로직 연결
                      // app_state.dart 의 상태 사용 예시:
                      // import 'package:ezip/state/app_state.dart' as app;
                      // await app.setLoggedIn(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('회원탈퇴 처리되었습니다.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('복사됨: $text')),
    );
  }
}

/// 정보 한 줄 위젯
class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(color: Colors.black54)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
