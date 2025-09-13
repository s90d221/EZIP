import 'package:flutter/material.dart';
import 'package:ezip/models/listing.dart';
import 'package:ezip/api/api_client.dart';

class RoomEditPage extends StatefulWidget {
  final Listing? initial; // null이면 생성, 있으면 수정
  const RoomEditPage({super.key, this.initial});

  @override
  State<RoomEditPage> createState() => _RoomEditPageState();
}

class _RoomEditPageState extends State<RoomEditPage> {
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
    _image.text = l?.imageUrl ?? 'https://picsum.photos/seed/room-${DateTime.now().millisecondsSinceEpoch}/1200/800';
    _tags.text = (l?.tags ?? const <String>[]).join(', ');
  }

  @override
  void dispose() {
    _monthly.dispose(); _deposit.dispose(); _area.dispose(); _floor.dispose();
    _maintenance.dispose(); _title.dispose(); _lat.dispose(); _lng.dispose(); _image.dispose(); _tags.dispose();
    super.dispose();
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
      'tags': _tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final body = _buildBody();
    try {
      if (widget.initial == null) {
        final created = await _api.createRoom(body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('등록 완료 (id=${created.id})')));
        Navigator.pop(context, true);
      } else {
        await _api.updateRoom(widget.initial!.id, body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정 완료')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isJeonse = _type == '전세';
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? '매물 등록' : '매물 수정')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('저장'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: '거래 유형'),
              items: const [
                DropdownMenuItem(value: '월세', child: Text('월세')),
                DropdownMenuItem(value: '전세', child: Text('전세')),
              ],
              onChanged: (v) => setState(() => _type = v ?? '월세'),
            ),
            if (!isJeonse)
              TextFormField(
                controller: _monthly,
                decoration: const InputDecoration(labelText: '월세 (만원)'),
                keyboardType: TextInputType.number,
              ),
            TextFormField(
              controller: _deposit,
              decoration: InputDecoration(labelText: isJeonse ? '전세 보증금 (만원)' : '보증금 (만원)'),
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _area, decoration: const InputDecoration(labelText: '면적(㎡)'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _floor, decoration: const InputDecoration(labelText: '층수'), keyboardType: TextInputType.number)),
              ],
            ),
            TextFormField(controller: _maintenance, decoration: const InputDecoration(labelText: '관리비(만원)'), keyboardType: TextInputType.number),
            TextFormField(controller: _title, decoration: const InputDecoration(labelText: '한 줄 설명'), validator: (v) => (v==null||v.isEmpty)?'필수':null),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _lat, decoration: const InputDecoration(labelText: '위도'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _lng, decoration: const InputDecoration(labelText: '경도'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            TextFormField(controller: _image, decoration: const InputDecoration(labelText: '이미지 URL')),
            TextFormField(controller: _tags, decoration: const InputDecoration(labelText: '태그 (쉼표로 구분)')),
          ],
        ),
      ),
    );
  }
}
