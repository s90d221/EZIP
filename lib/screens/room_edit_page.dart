import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezip/models/listing.dart';
import 'package:ezip/api/api_client.dart';

class RoomEditPage extends StatefulWidget {
  final Listing? initial; // null이면 생성, 있으면 수정
  const RoomEditPage({super.key, this.initial});

  @override
  State<RoomEditPage> createState() => _RoomEditPageState();
}

class _RoomEditPageState extends State<RoomEditPage> with TickerProviderStateMixin {
  static const String _kBaseUrl =
  String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.ezip.kro.kr/api/v1/');
  late final ApiClient _api = ApiClient(_kBaseUrl);

  final _formKey = GlobalKey<FormState>();

  late String _type; // '월세' | '전세'
  final _monthly = TextEditingController();
  final _deposit = TextEditingController();
  final _area = TextEditingController();
  final _floor = TextEditingController();
  final _maintenance = TextEditingController();
  final _title = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _image = TextEditingController();
  final _tags = TextEditingController(); // 쉼표 구분

  @override
  void initState() {
    super.initState();
    final l = widget.initial;
    _type = l?.type ?? '월세';
    _monthly.text = (l?.monthly ?? 0).toString();
    _deposit.text = (l?.deposit ?? 0).toString();
    _area.text = (l?.area ?? 0).toString();
    _floor.text = (l?.floor ?? 0).toString();
    _maintenance.text = l?.maintenanceFee ?? '0';
    _title.text = l?.shortTitle ?? '';
    _lat.text = (l?.lat ?? 36.6289).toString();
    _lng.text = (l?.lng ?? 127.4580).toString();
    _image.text = l?.imageUrl ??
        'https://picsum.photos/seed/room-${DateTime.now().millisecondsSinceEpoch}/1200/800';
    _tags.text = (l?.tags ?? const <String>[]).join(', ');

    // 미리보기/요약 실시간 갱신
    for (final c in [
      _image, _title, _monthly, _deposit, _area, _floor, _maintenance, _lat, _lng, _tags
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _monthly.dispose();
    _deposit.dispose();
    _area.dispose();
    _floor.dispose();
    _maintenance.dispose();
    _title.dispose();
    _lat.dispose();
    _lng.dispose();
    _image.dispose();
    _tags.dispose();
    super.dispose();
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    IconData? icon,
    String? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixText: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF94A3B8)),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Map<String, dynamic> _buildBody() {
    return {
      'type': _type,
      'monthly': int.tryParse(_monthly.text) ?? 0,
      'deposit': int.tryParse(_deposit.text) ?? 0,
      'area': double.tryParse(_area.text) ?? 0,
      'floor': int.tryParse(_floor.text) ?? 0,
      'maintenanceFee': _maintenance.text.trim(),
      'shortTitle': _title.text.trim(),
      'lat': double.tryParse(_lat.text) ?? 0,
      'lng': double.tryParse(_lng.text) ?? 0,
      'imageUrl': _image.text.trim(),
      'tags': _tags.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final body = _buildBody();
    try {
      if (widget.initial == null) {
        final created = await _api.createRoom(body);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('등록 완료 (id=${created.id})')));
        Navigator.pop(context, true);
      } else {
        await _api.updateRoom(widget.initial!.id, body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정 완료')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  String _summary() {
    final isJeonse = _type == '전세';
    final monthly = int.tryParse(_monthly.text) ?? 0;
    final deposit = int.tryParse(_deposit.text) ?? 0;
    final area = double.tryParse(_area.text) ?? 0;
    final floor = int.tryParse(_floor.text) ?? 0;
    final mfee = _maintenance.text.trim();
    final price = isJeonse ? '전세 $deposit' : '월세 $deposit/$monthly';
    return '$price · ${area.toStringAsFixed(0)}㎡ · ${floor}층 · 관리비 $mfee';
  }

  @override
  Widget build(BuildContext context) {
    final isJeonse = _type == '전세';
    final media = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? '매물 등록' : '매물 수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE6E6E6)),
        ),
      ),

      // 하단 고정 저장 버튼 (FAB 대신)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('저장'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ===== 이미지 미리보기 카드 =====
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: const Color(0xFFF1F5F9),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _image.text.trim().isEmpty
                        ? const Center(child: Icon(Icons.image, size: 56, color: Colors.black26))
                        : Image.network(
                      _image.text.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 48, color: Colors.black38),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        // focus 이동해서 바로 편집할 수 있게
                        FocusScope.of(context).unfocus();
                        // 스크롤 아래 이미지 URL 필드로 자연스럽게 이동
                        Scrollable.ensureVisible(_imageKey.currentContext!,
                            duration: const Duration(milliseconds: 250));
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('사진 변경'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== 헤더 & 요약 =====
            Text(
              _title.text.isEmpty ? '한 줄 설명을 입력해 주세요' : _title.text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              _summary(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // ===== 거래 유형 =====
            Text('거래 유형', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('월세'),
                  selected: _type == '월세',
                  onSelected: (s) => setState(() => _type = '월세'),
                ),
                ChoiceChip(
                  label: const Text('전세'),
                  selected: _type == '전세',
                  onSelected: (s) => setState(() => _type = '전세'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ===== 가격 섹션 =====
            Text('가격 정보', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (!isJeonse)
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _monthly,
                      decoration: _decoration(
                        label: '월세',
                        suffix: '만원',
                        icon: Icons.payments_outlined,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            TextFormField(
              controller: _deposit,
              decoration: _decoration(
                label: isJeonse ? '전세 보증금' : '보증금',
                suffix: '만원',
                icon: Icons.savings_outlined,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // ===== 기본 정보 =====
            Text('기본 정보', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _area,
                    decoration: _decoration(label: '면적', suffix: '㎡', icon: Icons.square_foot_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _floor,
                    decoration: _decoration(label: '층수', suffix: '층', icon: Icons.stairs_outlined),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maintenance,
              decoration: _decoration(label: '관리비', suffix: '만원', icon: Icons.receipt_long_outlined),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: _decoration(label: '한 줄 설명', hint: '예) 역세권, 채광 좋아요 ☀️', icon: Icons.title_outlined),
              validator: (v) => (v == null || v.trim().isEmpty) ? '필수 항목입니다' : null,
            ),
            const SizedBox(height: 16),

            // ===== 위치 =====
            Text('위치', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    decoration: _decoration(label: '위도', icon: Icons.place_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))],
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null) return '숫자를 입력해 주세요';
                      if (d < -90 || d > 90) return '위도는 -90~90';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    decoration: _decoration(label: '경도', icon: Icons.place_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))],
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null) return '숫자를 입력해 주세요';
                      if (d < -180 || d > 180) return '경도는 -180~180';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ===== 이미지 & 태그 =====
            Text('이미지 · 태그', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            // 이미지 URL
            _ImageField(
              controller: _image,
              decoration: _decoration(label: '이미지 URL', icon: Icons.link_outlined, hint: 'https://...'),
              fieldKey: _imageKey,
            ),
            const SizedBox(height: 12),

            // 태그 + 미리보기
            TextFormField(
              controller: _tags,
              decoration: _decoration(label: '태그 (쉼표로 구분)', icon: Icons.tag_outlined, hint: '예) 역세권, 반려동물, 엘리베이터'),
            ),
            const SizedBox(height: 8),
            _TagPreview(tags: _tags.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()),
            SizedBox(height: media.viewInsets.bottom), // 키보드 높이만큼 여유
          ],
        ),
      ),
    );
  }

  // 이미지 URL 입력칸으로 스크롤 이동할 때 쓰는 키
  final _imageKey = GlobalKey();
}

/// 이미지 URL 입력 필드(라벨 오른쪽에 작은 붙여넣기 버튼)
class _ImageField extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final Key fieldKey;
  const _ImageField({
    required this.controller,
    required this.decoration,
    required this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      decoration: decoration.copyWith(
        suffixIcon: IconButton(
          tooltip: '클립보드 붙여넣기',
          icon: const Icon(Icons.paste_outlined),
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null && data!.text!.trim().isNotEmpty) {
              controller.text = data.text!.trim();
            }
          },
        ),
      ),
      keyboardType: TextInputType.url,
    );
  }
}

/// 태그 미리보기 칩
class _TagPreview extends StatelessWidget {
  final List<String> tags;
  const _TagPreview({required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const Text('태그 없음', style: TextStyle(color: Colors.black45));
    }
    return Wrap(
      spacing: 6,
      runSpacing: -6,
      children: tags.map((t) => Chip(label: Text(t))).toList(),
    );
  }
}
