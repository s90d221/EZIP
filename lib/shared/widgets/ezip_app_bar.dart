import 'package:flutter/material.dart';
import 'ezip_logo.dart';

class EzipAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onTapMap, onTapPost, onTapMy;
  const EzipAppBar({super.key, required this.onTapMap, required this.onTapPost, required this.onTapMy});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 12,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          const EzipLogoLarge(),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '지역, 지하철, 대학, 단지, 매물번호',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
