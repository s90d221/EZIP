import 'package:flutter/material.dart';
import 'package:ezip/models/listing.dart';

class ListingCard extends StatelessWidget {
  final Listing item;
  final bool isSelected;
  final bool liked;
  final VoidCallback? onTap;
  final VoidCallback? onLikeToggle;

  const ListingCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.liked,
    this.onTap,
    this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 태그를 한 줄 문자열로 합치고 말줄임 처리
    final tagsLine = (item.tags.isNotEmpty)
        ? item.tags.join(' · ')
        : '';

    return Material(
      color: Colors.grey.shade100,
      elevation: isSelected ? 2 : 0,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Row(
              children: [
                // 썸네일
                SizedBox(
                  width: 120,
                  height: 160,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: _Thumbnail(url: item.imageUrl),
                  ),
                ),

                // 우측 정보
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단: 타이틀 (1줄 고정)
                        Text(
                          item.shortTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 가격/보증금 (1줄)
                        Text(
                          item.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // 면적/층/관리비 (1줄)
                        Text(
                          _subInfoLine(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),

                        // 태그: 한 줄 + 말줄임
                        if (tagsLine.isNotEmpty)
                          Text(
                            tagsLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 하트 (오버레이)
            Positioned(
              bottom: 8,
              right: 8,
              child: _HeartButton(
                liked: liked,
                onTap: onLikeToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subInfoLine(Listing it) {
    // 예: "17.5㎡ · 2층 · 관리비 5"
    final parts = <String>[];
    if (it.area > 0) parts.add('${it.area.toStringAsFixed(it.area.truncateToDouble() == it.area ? 0 : 1)}㎡');
    if (it.floor != 0) parts.add('${it.floor}층');
    if (it.maintenanceFee.isNotEmpty) parts.add('관리비 ${it.maintenanceFee}');
    return parts.join(' · ');
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;
  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF1F1F1),
        child: const Center(child: Icon(Icons.home, size: 32, color: Colors.black26)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF1F1F1),
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 28, color: Colors.black26)),
      ),
      // 로딩 중에도 높이 유지
      loadingBuilder: (context, child, event) {
        if (event == null) return child;
        return Container(
          color: const Color(0xFFF7F7F7),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}

class _HeartButton extends StatelessWidget {
  final bool liked;
  final VoidCallback? onTap;
  const _HeartButton({required this.liked, this.onTap});

  @override
  Widget build(BuildContext context) {
    // 하트 뒤에 살짝 배경을 깔아서 어디에 놓여도 잘 보이게
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            size: 22,
            color: liked ? Colors.pink : Colors.black45,
          ),
        ),
      ),
    );
  }
}
