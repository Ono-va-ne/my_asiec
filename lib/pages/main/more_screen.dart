import 'package:flutter/material.dart';
import 'package:my_asiec/pages/profile/auth_screen.dart';
import '../profile/profile_screen.dart'; // Импорт экрана профиля
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart'; // Импорт сервиса авторизации
import '../settings_screen.dart';
import '../pomodoro_screen.dart';
import '../hall_of_fame_screen.dart';
import '../handbook_list_screen.dart';
import 'package:my_asiec/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> _launchTG(BuildContext context) async {
  final url = 'https://t.me/MyASIEC';
  final uri = Uri.parse(url);

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _appVersion = 'Загрузка...';
  int? _currentUserId;
  String? _userFullName;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _checkAuth();
  }

  // Проверка сессии пользователя
  Future<void> _checkAuth() async {
    final userId = await AuthService.getCurrentUserId();
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('userFullName');

    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _userFullName = fullName;
      });
    }
  }

  // Переход в Профиль или Авторизацию
  Future<void> _openProfileOrAuth() async {
    if (_currentUserId == null) {
      // Пользователь НЕ вошел -> Открываем экран Входа
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );

      // После возврата с экрана входа обновляем статус
      if (result == true || mounted) {
        _checkAuth();
      }
    } else {
      // Пользователь ВОШЕЛ -> Открываем его Профиль
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            targetUserId: _currentUserId!,
            currentUserId: _currentUserId!,
          ),
        ),
      );

      // Обновляем состояние после возврата (вдруг нажал "Выйти")
      _checkAuth();
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      print("Ошибка при загрузке информации о пакете: $e");
      if (mounted) {
        setState(() {
          _appVersion = 'Ошибка загрузки версии';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const String logo = 'assets/logo.svg';
    final Widget svg = SvgPicture.asset(
      logo,
      semanticsLabel: 'myASIEC Logo',
      height: 86,
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.primary,
        BlendMode.srcIn,
      ),
    );

    const String tg = 'assets/tg.svg';
    final Widget svgTg = SvgPicture.asset(
      tg,
      semanticsLabel: 'tg',
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.onSurfaceVariant,
        BlendMode.srcIn,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moreScreen),
      ),
      body: ListView(
        children: [
          // --- ПУНКТ ПРОФИЛЯ / ВХОДА В ВЕРХУ СПИСКА ---
          ListTile(
            leading: Icon(
              _currentUserId == null ? Icons.account_circle_outlined : Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            title: Text(
              _currentUserId == null
                  ? 'Войти в аккаунт'
                  : (_userFullName ?? 'Мой профиль'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _currentUserId == null
                  ? 'Авторизуйтесь для доступа к чатам'
                  : 'Просмотр профиля и настройки аккаунта',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openProfileOrAuth,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.pomodoroTimer),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PomodoroScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(l10n.hallOfFame),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const HallOfFameScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: Text(l10n.handbookScreen),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HandbookListScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settings),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: svgTg,
            title: Text(l10n.telegramChannelLink),
            onTap: () => _launchTG(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutApp),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AboutDialog(
                  applicationName: l10n.myASIEC,
                  applicationVersion: _appVersion,
                  applicationIcon: svg,
                  applicationLegalese: '©2026 Onovane',
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(l10n.aboutDescription),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}