import 'package:flutter/material.dart';
import 'package:ezip/shared/widgets/ezip_logo.dart';
import 'package:ezip/shared/widgets/responsive_grid.dart';

class PostRoomPage extends StatelessWidget {
  const PostRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String hint) =>
        InputDecoration(hintText: hint, fillColor: Colors.white, filled: true);

    Widget col(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        child,
      ],
    );

    final w = MediaQuery.of(context).size.width;
    final int columns = w >= 900 ? 3 : (w >= 600 ? 2 : 1);

    return Scaffold(
      appBar: const PostFormAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ResponsiveGrid(
            columns: columns,
            gap: 12,
            children: [
              col('월세 (만원)', TextField(decoration: deco('예 : 50'))),
              col('보증금 (만원)', TextField(decoration: deco('예 : 1000'))),
              DropdownButtonFormField(
                items: const [
                  DropdownMenuItem(value: '남향', child: Text('남향')),
                  DropdownMenuItem(value: '동향', child: Text('동향')),
                  DropdownMenuItem(value: '서향', child: Text('서향')),
                  DropdownMenuItem(value: '북향', child: Text('북향')),
                ],
                onChanged: (_) {},
                decoration: const InputDecoration(labelText: '방향'),
              ),
              DropdownButtonFormField(
                items: const [
                  DropdownMenuItem(value: '원룸', child: Text('원룸')),
                  DropdownMenuItem(value: '1.5룸', child: Text('1.5룸')),
                  DropdownMenuItem(value: '투룸+', child: Text('투룸+')),
                ],
                onChanged: (_) {},
                decoration: const InputDecoration(labelText: '방 종류'),
              ),
              col('면적 (m2)', TextField(decoration: deco('예 : 50'))),
              col('난방 종류', DropdownButtonFormField(items: const [
                DropdownMenuItem(value: '개별난방', child: Text('개별난방')),
                DropdownMenuItem(value: '중앙난방', child: Text('중앙난방')),
              ], onChanged: (_) {})),
              col('층수', TextField(decoration: deco('예 : 2층'))),
              col('관리비 (원)', TextField(decoration: deco('예 : 50'))),
              col('현관 유형', DropdownButtonFormField(items: const [
                DropdownMenuItem(value: '계단식', child: Text('계단식')),
                DropdownMenuItem(value: '복도식', child: Text('복도식')),
              ], onChanged: (_) {})),
              col('방 수', TextField(decoration: deco('예 : 1'))),
              col('건축물 용도', TextField(decoration: deco('예 : 공동주택'))),
              col('사용 승인일', TextField(decoration: deco('2000년 01월 01일'))),
              col('주차 가능 여부', DropdownButtonFormField(items: const [
                DropdownMenuItem(value: '가능', child: Text('가능')),
                DropdownMenuItem(value: '불가', child: Text('불가')),
              ], onChanged: (_) {})),
              col('총 주차 대수', TextField(decoration: deco('예 : 10'))),
              col('입주 가능일', TextField(decoration: deco('2000년 01월 01일'))),
              col('옵션', TextField(decoration: deco('예 : 공동주택'))),
              col('보안/안전 시설', TextField(decoration: deco('예 : CCTV, 비디오폰 ...'))),
            ],
          ),
          const SizedBox(height: 16),
          Text('사진 등록', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.photo), label: const Text('0/10')),
          const SizedBox(height: 16),
          Text('상세 설명', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const TextField(minLines: 4, maxLines: 8, decoration: InputDecoration(hintText: '매물에 대한 추가적인 정보를 입력하세요.')),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE6E6E6)),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('집주인 정보', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ResponsiveGrid(
                columns: columns,
                gap: 12,
                children: const [
                  TextField(decoration: InputDecoration(labelText: '집주인 이름', hintText: '홍길동')),
                  TextField(decoration: InputDecoration(labelText: '전화번호', hintText: '010-1234-5678')),
                  TextField(decoration: InputDecoration(labelText: '사업자 등록 번호 (선택)', hintText: '123-45-67890')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: () {}, child: const Text('매물 등록하기')),
                ],
              )
            ]),
          ),
        ],
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
          const SizedBox(width:54), // 좌우 균형용
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFE6E6E6)),
      ),
    );
  }
}