import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezip/shared/widgets/ezip_logo.dart';
import 'package:ezip/shared/widgets/responsive_grid.dart';

class PostRoomPage extends StatefulWidget {
  const PostRoomPage({super.key});

  @override
  State<PostRoomPage> createState() => _PostRoomPageState();
}

class _PostRoomPageState extends State<PostRoomPage> {
  final _formKey = GlobalKey<FormState>();

  // 선택값(디자인 데모용 로컬 상태)
  String? _orientation; // 남향/동향/서향/북향
  String? _roomType;    // 원룸/1.5룸/투룸+
  String? _heating;     // 개별난방/중앙난방
  String? _entrance;    // 계단식/복도식
  String? _parking;     // 가능/불가

  // 인풋 데코 통일
  InputDecoration _deco(
      String label, {
        String? hint,
        String? suffix,
        IconData? icon,
      }) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixText: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: base,
      focusedBorder: base.copyWith(borderSide: const BorderSide(color: Color(0xFF94A3B8))),
    );
  }

  Widget _sectionTitle(BuildContext context, String text, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) Icon(icon, size: 18, color: Colors.black54),
        if (icon != null) const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _chipGroup({
    required List<String> items,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: -6,
      children: items
          .map(
            (e) => ChoiceChip(
          label: Text(e),
          selected: value == e,
          onSelected: (_) => setState(() => onChanged(e)),
        ),
      )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final int columns = w >= 900 ? 3 : (w >= 600 ? 2 : 1);

    return Scaffold(
      appBar: const PostFormAppBar(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('매물 등록하기'),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  // TODO: 실제 등록 로직 연결
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('등록 정보를 확인했어요!')),
                  );
                }
              },
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== 가격 정보 =====
            _sectionTitle(context, '가격 정보', icon: Icons.payments_outlined),
            const SizedBox(height: 8),
            ResponsiveGrid(
              columns: columns,
              gap: 12,
              children: [
                TextFormField(
                  decoration: _deco('월세', hint: '예: 50', suffix: '만원', icon: Icons.payments_outlined),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextFormField(
                  decoration: _deco('보증금', hint: '예: 1000', suffix: '만원', icon: Icons.savings_outlined),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextFormField(
                  decoration: _deco('관리비', hint: '예: 5', suffix: '만원', icon: Icons.receipt_long_outlined),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ===== 기본 정보 =====
            _sectionTitle(context, '기본 정보', icon: Icons.info_outline),
            const SizedBox(height: 8),
            ResponsiveGrid(
              columns: columns,
              gap: 12,
              children: [
                TextFormField(
                  decoration: _deco('면적', hint: '예: 50', suffix: '㎡', icon: Icons.square_foot_outlined),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
                TextFormField(
                  decoration: _deco('층수', hint: '예: 2', suffix: '층', icon: Icons.stairs_outlined),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextFormField(
                  decoration: _deco('방 수', hint: '예: 1', suffix: '개', icon: Icons.meeting_room_outlined),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 칩 선택(드롭다운 → 칩)
            _chipGroup(
              items: const ['남향', '동향', '서향', '북향'],
              value: _orientation,
              onChanged: (v) => _orientation = v,
            ),
            const SizedBox(height: 8),
            _chipGroup(
              items: const ['원룸', '1.5룸', '투룸+'],
              value: _roomType,
              onChanged: (v) => _roomType = v,
            ),
            const SizedBox(height: 16),

            // ===== 추가 정보 =====
            _sectionTitle(context, '추가 정보', icon: Icons.add_circle_outline),
            const SizedBox(height: 8),
            ResponsiveGrid(
              columns: columns,
              gap: 12,
              children: [
                // 난방 종류
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('난방 종류', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    _chipGroup(
                      items: const ['개별난방', '중앙난방'],
                      value: _heating,
                      onChanged: (v) => _heating = v,
                    ),
                  ],
                ),
                // 현관 유형
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('현관 유형', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    _chipGroup(
                      items: const ['계단식', '복도식'],
                      value: _entrance,
                      onChanged: (v) => _entrance = v,
                    ),
                  ],
                ),
                // 주차 가능 여부
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('주차 가능 여부', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    _chipGroup(
                      items: const ['가능', '불가'],
                      value: _parking,
                      onChanged: (v) => _parking = v,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ===== 사진 등록 =====
            _sectionTitle(context, '사진 등록', icon: Icons.photo_library_outlined),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {}, // TODO: 이미지 선택 연결
                  icon: const Icon(Icons.photo),
                  label: const Text('사진 추가'),
                ),
                const SizedBox(width: 8),
                const Text('0/10', style: TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            _PhotoGridPlaceholder(), // 예쁜 플레이스홀더
            const SizedBox(height: 16),

            // ===== 상세 설명 =====
            _sectionTitle(context, '상세 설명', icon: Icons.notes_outlined),
            const SizedBox(height: 8),
            TextFormField(
              minLines: 4,
              maxLines: 8,
              decoration: _deco('매물에 대한 추가 정보를 입력하세요', icon: Icons.description_outlined),
            ),
            const SizedBox(height: 16),

            // ===== 집주인 정보 =====
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE6E6E6)),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle(context, '집주인 정보', icon: Icons.person_outline),
                const SizedBox(height: 12),
                ResponsiveGrid(
                  columns: columns,
                  gap: 12,
                  children: [
                    TextFormField(decoration: _deco('집주인 이름', hint: '홍길동', icon: Icons.badge_outlined)),
                    TextFormField(decoration: _deco('전화번호', hint: '010-1234-5678', icon: Icons.call_outlined)),
                    TextFormField(decoration: _deco('사업자 등록 번호 (선택)', hint: '123-45-67890', icon: Icons.business_outlined)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        // TODO: 등록 로직(동일하게 위 버튼과 연결 가능)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('임시 저장 완료!')),
                        );
                      }
                    }, child: const Text('임시 저장')),
                  ],
                )
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGridPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 2행 x 3열 플레이스홀더 (반응형 넓으면 더 넉넉)
    final size = MediaQuery.of(context).size.width;
    final cross = size >= 900 ? 5 : (size >= 600 ? 4 : 3);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: cross, // 첫 행 정도만
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (_, i) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: const Center(
          child: Icon(Icons.photo_size_select_actual_outlined, color: Colors.black26, size: 32),
        ),
      ),
    );
  }
}

class PostFormAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PostFormAppBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 12,
      title: Row(
        children: [
          const EzipLogoLarge(),
          Expanded(
            child: Center(
              child: Text(
                '방 내놓기',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // 좌우 완전 대칭: 로고와 동일 폭의 투명 위젯
          const Opacity(opacity: 0, child: EzipLogoLarge()),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFE6E6E6)),
      ),
    );
  }
}
