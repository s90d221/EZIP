import 'package:flutter/material.dart';
import 'package:ezip/shared/widgets/ezip_app_bar.dart';
import 'package:ezip/state/app_state.dart';
import 'package:ezip/state/app_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    final id = TextEditingController();
    final pw = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: EzipAppBar(onTapMap: () => Navigator.pop(context), onTapPost: () => Navigator.pushNamed(context, '/post'), onTapMy: () {}),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 0,
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(side: BorderSide(color: cs.outlineVariant), borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('이메일로 로그인', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                TextField(controller: id, decoration: const InputDecoration(labelText: '아이디', hintText: '이메일 주소 입력')),
                const SizedBox(height: 12),
                _PwField(controller: pw),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    isLoggedIn.value = true;
                    Navigator.pop(context);
                  },
                  child: const Text('로그인'),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  TextButton(onPressed: () => Navigator.pushNamed(context, '/signup/terms'), child: const Text('이메일로 가입하기')),
                  TextButton(onPressed: () {}, child: const Text('비밀번호 재설정')),
                ])
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _PwField extends StatefulWidget {
  final TextEditingController controller;
  const _PwField({required this.controller});
  @override
  State<_PwField> createState() => _PwFieldState();
}

class _PwFieldState extends State<_PwField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: '비밀번호',
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}