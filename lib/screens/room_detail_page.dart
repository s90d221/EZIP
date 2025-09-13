import 'package:ezip/screens/room_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:ezip/models/listing.dart';
import 'package:ezip/models/review.dart';
import 'package:ezip/api/api_client.dart';

class RoomDetailPage extends StatefulWidget {
  final int roomId;
  const RoomDetailPage({super.key, required this.roomId});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  static const String _kBaseUrl =
  String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.ezip.kro.kr/api/v1/');
  late final ApiClient _api = ApiClient(_kBaseUrl);

  late Future<Listing> _future;
  late Future<List<Review>> _futureReviews;

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    _future = _api.getRoomDetail(widget.roomId);
    _futureReviews = _api.getReviews(query: {'roomId': widget.roomId});
    setState(() {});
  }

  Future<void> _deleteRoom() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제하시겠어요?'),
        content: const Text('이 매물을 정말 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteRoom(widget.roomId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제 완료')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  Future<void> _openEdit(Listing l) async {
    // RoomEditPage에서 저장 후 true 반환하면 리로드
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RoomEditPage(initial: l)),
    );
    if (updated == true) _reloadAll();
  }

  Future<void> _createOrEditReview({Review? editing}) async {
    final ctrl = TextEditingController(text: editing?.content ?? '');
    final nameCtrl = TextEditingController(text: editing?.author ?? '익명');
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editing == null ? '리뷰 작성' : '리뷰 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '작성자')),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '내용'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('저장')),
        ],
      ),
    );
    if (saved != true) return;

    try {
      if (editing == null) {
        await _api.createReview(Review(
          id: 0,
          roomId: widget.roomId,
          author: nameCtrl.text,
          content: ctrl.text,
          createdAt: DateTime.now(),
        ));
      } else {
        await _api.updateReview(editing.id, {
          'content': ctrl.text,
          'author': nameCtrl.text,
        });
      }
      _reloadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('리뷰 저장 실패: $e')));
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('리뷰 삭제'),
        content: const Text('정말 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteReview(reviewId);
      _reloadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('리뷰 삭제 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Listing>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final err = snap.hasError ? snap.error.toString() : null;
        final l = snap.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('매물 상세'),
            actions: [
              if (!loading && l != null)
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEdit(l)),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteRoom),
            ],
          ),
          floatingActionButton: (!loading && l != null)
              ? FloatingActionButton.extended(
            onPressed: () => _createOrEditReview(),
            icon: const Icon(Icons.rate_review),
            label: const Text('리뷰 작성'),
          )
              : null,
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : err != null
              ? Center(child: Text('불러오기 실패: $err'))
              : _DetailBody(listing: l!, reviewsFuture: _futureReviews, onEditReview: _createOrEditReview, onDeleteReview: _deleteReview),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Listing listing;
  final Future<List<Review>> reviewsFuture;
  final void Function({Review? editing}) onEditReview;
  final void Function(int reviewId) onDeleteReview;

  const _DetailBody({
    required this.listing,
    required this.reviewsFuture,
    required this.onEditReview,
    required this.onDeleteReview,
  });

  @override
  Widget build(BuildContext context) {
    final chips = listing.tags.isEmpty
        ? [const Chip(label: Text('태그 없음'))]
        : listing.tags.map((t) => Chip(label: Text(t))).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              listing.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48)),
            ),
          ),
          const SizedBox(height: 12),

          // 기본 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.shortTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${listing.priceLabel} · ${listing.area}㎡ · ${listing.floor}층 · 관리비 ${listing.maintenanceFee}만'),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: -6, children: chips),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text('위치: ${listing.lat.toStringAsFixed(5)}, ${listing.lng.toStringAsFixed(5)}'),
                ),
                const Divider(),
              ],
            ),
          ),

          // 리뷰 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('리뷰', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          FutureBuilder<List<Review>>(
            future: reviewsFuture,
            builder: (context, rsnap) {
              if (rsnap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (rsnap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('리뷰 불러오기 실패: ${rsnap.error}'),
                );
              }
              final reviews = rsnap.data ?? const <Review>[];
              if (reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('아직 리뷰가 없어요. 첫 리뷰를 남겨보세요!'),
                );
              }
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = reviews[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(r.author),
                    subtitle: Text(r.content),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEditReview(editing: r),
                          tooltip: '수정',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => onDeleteReview(r.id),
                          tooltip: '삭제',
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
