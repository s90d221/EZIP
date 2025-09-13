import 'package:flutter/material.dart';
import 'package:ezip/shared/widgets/ezip_app_bar.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});
  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  final Map<String, bool> agree = {
    '필수) 이용약관 동의': false,
    '필수) 개인정보 수집/이용 동의': false,
    '선택) 마케팅 정보 수신 동의': false,
    '선택) 이벤트 푸시 알림 수신 동의': false,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: EzipAppBar(onTapMap: () => Navigator.pop(context), onTapPost: () => Navigator.pushNamed(context, '/post'), onTapMy: () {}),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            elevation: 0,
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(side: BorderSide(color: cs.outlineVariant), borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('약관 동의', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                ...agree.keys.map((k) => CheckboxListTile(
                  value: agree[k],
                  onChanged: (v) => setState(() => agree[k] = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(k),
                )),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: (agree['필수) 이용약관 동의']! && agree['필수) 개인정보 수집/이용 동의']!)
                      ? () => Navigator.pushNamed(context, '/signup/info')
                      : null,
                  child: const Text('동의하고 진행하기'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
