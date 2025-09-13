import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';

import 'package:ezip/state/app_state.dart' as app;
import 'package:ezip/shared/widgets/listing_card.dart';

import 'package:ezip/models/listing.dart';
import 'package:ezip/api/api_client.dart';
import 'package:ezip/screens/room_detail_page.dart';

class MapAndListingsPage extends StatefulWidget {
  const MapAndListingsPage({super.key});
  @override
  State<MapAndListingsPage> createState() => _MapAndListingsPageState();
}

class _MapAndListingsPageState extends State<MapAndListingsPage> {
  GoogleMapController? _mapController;

  // 데이터/상태
  List<Listing> _items = [];
  bool _busy = false;

  // 마커/선택
  final Set<Marker> _markers = {};
  int? _selectedId;

  // 리스트 시트
  final DraggableScrollableController _drag = DraggableScrollableController();
  ScrollController? _listCtrl;
  static const double _cardExtent = 168;

  // API (https + /api/v1)
  static const String _kBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ezip.kro.kr/api/v1/',
  );
  late final ApiClient _api = ApiClient(_kBaseUrl);

  // favoriteIds 리스너 핸들 (추가/해제용)
  late final VoidCallback _favListener;

  @override
  void initState() {
    super.initState();
    _favListener = () => setState(_rebuildMarkers);
    app.favoriteIds.addListener(_favListener);
    _load(); // 첫 로드
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _drag.dispose();
    app.favoriteIds.removeListener(_favListener);
    super.dispose();
  }

  // -------- 로딩/스낵 도우미 --------
  void _setBusy(bool v) {
    if (!mounted) return;
    setState(() => _busy = v);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // -------- 목록 로드 --------
  Future<void> _load() async {
    _setBusy(true);
    try {
      final list = await _api.getRooms(query: {'page': 0, 'size': 50});
      setState(() {
        _items = list;
        _rebuildMarkers();
      });
      _fitToAll();
    } on DioException catch (e) {
      _showSnack(
        '목록 불러오기 실패 (${e.response?.statusCode ?? '-'})\n${e.requestOptions.uri}',
      );
    } catch (e) {
      _showSnack('목록 불러오기 실패: $e');
    } finally {
      _setBusy(false);
    }
  }

  // -------- 마커 재구성 --------
  void _rebuildMarkers() {
    final likedSet = app.favoriteIds.value;
    _markers
      ..clear()
      ..addAll(_items.map((e) {
        final selected = e.id == _selectedId;
        final liked = likedSet.contains(e.id);
        final hue = selected
            ? BitmapDescriptor.hueAzure
            : (liked ? BitmapDescriptor.hueRose : 275.0 /*보라톤*/);
        return Marker(
          markerId: MarkerId(e.id.toString()),
          position: LatLng(e.lat, e.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(title: e.shortTitle, snippet: e.priceLabel),
          onTap: () => _onMarkerTap(e.id),
        );
      }));
    setState(() {}); // 지도 갱신
  }

  void _onMarkerTap(int id) {
    setState(() => _selectedId = id);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1 && _listCtrl != null && _listCtrl!.hasClients) {
      _listCtrl!.animateTo(
        idx * _cardExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
    if (_drag.size < 0.38) {
      _drag.animateTo(
        0.38,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleSheet() {
    final target = (_drag.size >= 0.95) ? 0.38 : 0.95;
    _drag.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _fitToAll() async {
    if (_mapController == null || _items.isEmpty) return;
    final sw = LatLng(
      _items.map((e) => e.lat).reduce((a, b) => a < b ? a : b),
      _items.map((e) => e.lng).reduce((a, b) => a < b ? a : b),
    );
    final ne = LatLng(
      _items.map((e) => e.lat).reduce((a, b) => a > b ? a : b),
      _items.map((e) => e.lng).reduce((a, b) => a > b ? a : b),
    );
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 60),
    );
  }

  // -------- 정렬 --------
  Future<void> _showSortSheet() async {
    final sel = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.new_releases_outlined),
            title: const Text('최신순'),
            onTap: () => Navigator.pop(context, 'latest'),
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: const Text('보증금 낮은순'),
            onTap: () => Navigator.pop(context, 'deposit_asc'),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('월세 낮은순'),
            onTap: () => Navigator.pop(context, 'monthly_asc'),
          ),
          ListTile(
            leading: const Icon(Icons.square_foot_outlined),
            title: const Text('면적 큰순'),
            onTap: () => Navigator.pop(context, 'area_desc'),
          ),
        ]),
      ),
    );
    if (sel == null) return;
    setState(() {
      switch (sel) {
        case 'latest':
          _items.sort((a, b) => b.id.compareTo(a.id));
          break;
        case 'deposit_asc':
          _items.sort((a, b) => a.deposit.compareTo(b.deposit));
          break;
        case 'monthly_asc':
          _items.sort((a, b) => a.monthly.compareTo(b.monthly));
          break;
        case 'area_desc':
          _items.sort((a, b) => b.area.compareTo(a.area));
          break;
      }
      _rebuildMarkers();
    });
    _fitToAll();
  }

  // -------- 테스트 시드 --------
  Future<void> _seed() async {
    final samples = [
      {
        'type': '월세', 'monthly': 45, 'deposit': 300, 'area': 17.5, 'floor': 2,
        'maintenanceFee': '5', 'shortTitle': '테스트 원룸 A',
        'lat': 36.6289, 'lng': 127.4580,
        'imageUrl': 'https://picsum.photos/seed/seedA/1200/800',
        'tags': ['풀옵션', '세탁기'],
      },
      {
        'type': '월세', 'monthly': 38, 'deposit': 200, 'area': 16.0, 'floor': 3,
        'maintenanceFee': '4', 'shortTitle': '테스트 원룸 B',
        'lat': 36.6302, 'lng': 127.4615,
        'imageUrl': 'https://picsum.photos/seed/seedB/1200/800',
        'tags': ['에어컨', '가성비'],
      },
      {
        'type': '전세', 'monthly': 0, 'deposit': 9500, 'area': 34.0, 'floor': 6,
        'maintenanceFee': '7', 'shortTitle': '테스트 투룸 C',
        'lat': 36.6247, 'lng': 127.4542,
        'imageUrl': 'https://picsum.photos/seed/seedC/1200/800',
        'tags': ['투룸', '엘리베이터'],
      },
    ];

    try {
      _setBusy(true);
      for (final b in samples) {
        await _api.createRoom(_toServerBody(b));
      }
      await _load();
      _showSnack('테스트 매물 3개 등록 완료');
    } on DioException catch (e) {
      _showSnack('시드 실패 (${e.response?.statusCode ?? '-'})\n${e.requestOptions.uri}');
    } catch (e) {
      _showSnack('시드 실패: $e');
    } finally {
      _setBusy(false);
    }
  }

  Map<String, dynamic> _toServerBody(Map<String, dynamic> b) => {
    'type': b['type'],
    'monthly': b['monthly'],
    'deposit': b['deposit'],
    'area': b['area'],
    'floor': b['floor'],
    'maintenanceFee': b['maintenanceFee']?.toString(),
    'maintenance_fee': b['maintenanceFee']?.toString(),
    'shortTitle': b['shortTitle'],
    'title': b['shortTitle'],
    'lat': b['lat'],
    'latitude': b['lat'],
    'lng': b['lng'],
    'longitude': b['lng'],
    'imageUrl': b['imageUrl'],
    'image_url': b['imageUrl'],
    'tags': b['tags'],
    'tag_list': b['tags'],
  };

  @override
  Widget build(BuildContext context) {
    const camera = CameraPosition(
      target: LatLng(36.6289, 127.4580), // 충북대 근처
      zoom: 13.5,
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: camera,
          markers: _markers,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          onMapCreated: (c) => _mapController = c,
        ),

        // 상단: 필터바(검색창 제거, 글래스 스타일만 유지)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _FilterBar(onRefresh: _load),
        ),

        // 하단: 글래스 시트
        DraggableScrollableSheet(
          controller: _drag,
          initialChildSize: 0.38,
          minChildSize: 0.20,
          maxChildSize: 1.0,
          snap: true,
          builder: (context, scrollController) {
            _listCtrl = scrollController;
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: const [
                      BoxShadow(blurRadius: 16, offset: Offset(0, -2), color: Colors.black26)
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Row(
                          children: [
                            Text(
                              '학교 근처 매물 · ${_items.length}개',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _showSortSheet,
                              icon: const Icon(Icons.tune),
                              label: const Text('정렬'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_full),
                              tooltip: '전체보기/축소',
                              onPressed: _toggleSheet,
                            ),
                          ],
                        ),
                      ),

                      if (_busy)
                        const Expanded(child: Center(child: CircularProgressIndicator()))
                      else
                        Expanded(
                          child: ValueListenableBuilder<Set<int>>(
                            valueListenable: app.favoriteIds,
                            builder: (_, favSet, __) {
                              if (_items.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('표시할 매물이 없어요'),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        onPressed: _seed,
                                        icon: const Icon(Icons.add),
                                        label: const Text('테스트 매물 넣기'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                controller: scrollController,
                                itemCount: _items.length,
                                itemExtent: _cardExtent,
                                padding: const EdgeInsets.only(bottom: 24),
                                itemBuilder: (context, i) {
                                  final item = _items[i];
                                  final selected = item.id == _selectedId;
                                  final likedNow = favSet.contains(item.id);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                    child: ListingCard(
                                      key: ValueKey(item.id),
                                      item: item,
                                      isSelected: selected,
                                      liked: likedNow,
                                      onTap: () async {
                                        setState(() => _selectedId = item.id);
                                        _mapController?.animateCamera(
                                          CameraUpdate.newLatLng(LatLng(item.lat, item.lng)),
                                        );
                                        final changed = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RoomDetailPage(roomId: item.id),
                                          ),
                                        );
                                        if (changed == true) _load();
                                      },
                                      // ✅ 로컬 찜: item과 함께 저장해야 Favorites 탭에서 보임
                                      onLikeToggle: () => app.toggleFavoriteWithItem(item),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------- 상단 필터 바 (검색 없음!) ----------
class _FilterBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _FilterBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 2))
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _DropdownBox(label: '거래', items: const ['전체', '월세', '전세']),
                    _DropdownBox(label: '가격', items: const ['전체', '~50만', '50~100만', '100만+']),
                    _DropdownBox(label: '크기', items: const ['전체', '원룸', '1.5룸', '투룸+']),
                    _DropdownBox(label: '인원', items: const ['전체', '1인', '2인', '3인+']),
                    _DropdownBox(label: '층수', items: const ['전체', '지하', '저층', '중층', '고층']),
                    _DropdownBox(label: '옵션', items: const ['전체', '반려동물', '주차', '엘리베이터']),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('새로고침'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownBox extends StatefulWidget {
  final String label;
  final List<String> items;
  const _DropdownBox({super.key, required this.label, required this.items});

  @override
  State<_DropdownBox> createState() => _DropdownBoxState();
}

class _DropdownBoxState extends State<_DropdownBox> {
  String? value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 112, maxWidth: 140),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.95),
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: value ?? widget.items.first,
                    items: widget.items
                        .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e, overflow: TextOverflow.ellipsis),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => value = v),
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
