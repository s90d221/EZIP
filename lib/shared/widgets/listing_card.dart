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

    final tags = item.tags;
    final showTags = tags.take(2).toList();
    final hiddenCount = tags.length - showTags.length;

    return AnimatedScale(
      scale: isSelected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 160,
            child: Row(
              children: [
                // ===== 썸네일 & 오버레이 =====
                SizedBox(
                  width: 120,
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Thumbnail(url: item.imageUrl),
                      // 가격 배지
                      Positioned(
                        left: 4,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.priceLabel,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                        ),
                      ),
                      // 하트
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: _HeartButton(liked: liked, onTap: onLikeToggle),
                      ),
                    ],
                  ),
                ),

                // ===== 정보 =====
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 타이틀
                        Text(
                          item.shortTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 서브 정보: 면적/층/관리비
                        Row(
                          children: [
                            const Icon(Icons.square_foot_outlined, size: 16, color: Colors.black45),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _subInfoLine(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // 태그 칩 + 나머지 카운트
                        if (tags.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: -6,
                            children: [
                              for (final t in showTags)
                                _TagChip(text: t),
                              if (hiddenCount > 0)
                                _TagChip(text: '+$hiddenCount', subtle: true),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subInfoLine(Listing it) {
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

class _Thumbnail extends StatelessWidget {
  final String url;
  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF4F6F8),
        child: const Center(child: Icon(Icons.home_rounded, size: 32, color: Colors.black26)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF4F6F8),
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 28, color: Colors.black26)),
      ),
      loadingBuilder: (context, child, event) {
        if (event == null) return child;
        return Container(
          color: const Color(0xFFF7F9FB),
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
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: Tween(begin: .8, end: 1.0).animate(anim), child: child),
            child: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(liked),
              size: 20,
              color: liked ? Colors.pink : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final bool subtle;
  const _TagChip({required this.text, this.subtle = false});

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
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
