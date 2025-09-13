import 'package:flutter/material.dart';
import 'package:ezip/shared/widgets/ezip_app_bar.dart';
import 'package:ezip/state/app_state.dart';

class SignUpInfoPage extends StatelessWidget {
  const SignUpInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = TextEditingController();
    final pw = TextEditingController();
    final pw2 = TextEditingController();

    return Scaffold(
      appBar: EzipAppBar(onTapMap: () => Navigator.pop(context), onTapPost: () => Navigator.pushNamed(context, '/post'), onTapMy: () {}),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('회원정보 입력', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(controller: email, decoration: const InputDecoration(labelText: '아이디', hintText: '이메일 주소 입력')),
                const SizedBox(height: 12),
                _PwField(controller: pw),
                const SizedBox(height: 12),
                _PwField(controller: pw2),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    isLoggedIn.value = true;
                    Navigator.popUntil(context, (route) => route.settings.name == null);
                  },
                  child: const Text('회원가입 완료'),
                ),
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
