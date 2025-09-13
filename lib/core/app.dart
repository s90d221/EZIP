import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ezip/core/constants.dart';
import 'package:ezip/state/app_state.dart';
import 'package:ezip/shared/widgets/ezip_app_bar.dart';

import 'package:ezip/screens/map_and_listings_page.dart';
import 'package:ezip/screens/post_room_page.dart';
import 'package:ezip/screens/favorites_page.dart';
import 'package:ezip/screens/mypage.dart';
import 'package:ezip/features/auth/login_page.dart';
import 'package:ezip/features/auth/terms_page.dart';
import 'package:ezip/features/auth/sign_up_info_page.dart';


class EZIPApp extends StatelessWidget {
  const EZIPApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: kBrandBlue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE6E6E6)),
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide(color: Color(0xFFE6E6E6)),
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EZIP',
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: theme,
      home: const _HomeShell(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/signup/terms': (_) => const TermsPage(),
        '/signup/info': (_) => const SignUpInfoPage(),
        '/post': (_) => const PostRoomPage(),
        '/mypage': (_) => const MyPage(),
      },
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({super.key});
  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;
  final _pages = [MapAndListingsPage(), PostRoomPage(), FavoritesPage(), MyPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _index == 0
          ? EzipAppBar(
        onTapMap: () => setState(() => _index = 0),
        onTapPost: () => setState(() => _index = 1),
        onTapMy: () => setState(() => _index = 3),
      )
          : null,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: '지도'),
          NavigationDestination(icon: Icon(Icons.add_home_outlined), selectedIcon: Icon(Icons.add_home), label: '방 내놓기'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: '찜'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '마이'),
        ],
      ),
    );
  }
}