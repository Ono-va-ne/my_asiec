import 'package:flutter/material.dart';
import '../settings_screen.dart';
import '../pomodoro_screen.dart';
import '../hall_of_fame_screen.dart';
import 'package:my_asiec/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Импортируем пакет для получения информации о приложении


Future<void> _launchTG(BuildContext context) async {
  // Формируем стандартную ссылку на пост VK

  final url = 'https://t.me/MyASIEC';
  final uri = Uri.parse(url);

  // Пытаемся открыть ссылку. LaunchMode.externalApplication
  // попытается открыть приложение TG, если оно установлено,
  // иначе откроет браузер.
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});
   @override
  State<MoreScreen> createState() => _MoreScreenState();
}


class _MoreScreenState extends State<MoreScreen> {
  String _appVersion = 'Загрузка...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  Future<void> _loadAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      // Получили информацию о пакете
      if (mounted) {
        // Проверяем, что виджет все еще "жив" перед обновлением состояния
        setState(() {
          _appVersion =
              packageInfo.version; // Обновляем переменную состояния с версией
        });
      }
    } catch (e) {
      print("Ошибка при загрузке информации о пакете: $e");
      if (mounted) {
        setState(() {
          _appVersion =
              'Ошибка загрузки версии'; // Показываем сообщение об ошибке, если что-то пошло не так
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HallOfFameScreen()));
            },
          ),
          Divider(),
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
            leading: Icon(Icons.info_outline),
            title: Text(l10n.aboutApp),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AboutDialog(
                      applicationName: l10n.myASIEC,
                      applicationVersion:
                          _appVersion,
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
