import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../handbook_by_speciality_screen.dart';
import 'package:my_asiec/l10n/app_localizations.dart';

class SpecialtiesScreen extends StatefulWidget {
  const SpecialtiesScreen({super.key});
  @override
  State<SpecialtiesScreen> createState() => _SpecialtiesScreenState();
}

class _SpecialtiesScreenState extends State<SpecialtiesScreen> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  Future<List<Map<String, dynamic>>> _fetchSpecialties() async {
    final data = await _client.from('formulas_specs').select().order('name');
    return List<Map<String, dynamic>>.from(data as List);
  }

  @override
  void initState() {
    super.initState();
    _future = _fetchSpecialties();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('${l10n.error}: ${snap.error}'));
            }
            final items = snap.data ?? [];
            return OrientationBuilder(builder: (context, orientation) {
              // Устанавливаем количество столбцов в зависимости от ориентации
              final crossAxisCount =
                  orientation == Orientation.portrait ? 2 : 4;

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount, // Используем переменную
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final sp = items[i];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HandbookBySpecialtyScreen(
                            specialtyId: sp['id'],
                            specialtyName: sp['name'] ?? 'Специальность',
                          ),
                        ),
                      );
                    },
                    child: Card(
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          // SVG icon is now the first child, so it's in the background.
                          Builder(builder: (context) {
                            final iconData = sp['icon'];
                            if (iconData == null) return const SizedBox.shrink();
                            if (iconData is! String || iconData.trim().isEmpty)
                              return const SizedBox.shrink();
                            Widget iconWidget;
                            final trimmed = iconData.trimLeft();
                            if (trimmed.startsWith('<svg')) {
                              iconWidget = SvgPicture.string(
                                iconData,
                                width: 64,
                                height: 64,
                                fit: BoxFit.contain,
                                colorFilter: ColorFilter.mode(
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(100),
                                    BlendMode.modulate),
                                placeholderBuilder: (ctx) =>
                                    const SizedBox(width: 64, height: 64),
                              );
                            } else {
                              iconWidget = SvgPicture.network(
                                iconData,
                                width: 64,
                                height: 64,
                                fit: BoxFit.contain,
                                colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.primaryContainer,
                                    BlendMode.modulate),
                                placeholderBuilder: (ctx) => const SizedBox(
                                    width: 128,
                                    height: 128,
                                    child: Center(
                                        child: SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)))),
                                // optional: handle loading errors
                                // semanticsLabel: sp['name'] ?? 'icon',
                              );
                            }
                            return Positioned(
                              bottom: 10,
                              right: 10,
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: iconWidget,
                              ),
                            );
                          }),
                          // The text is now the second child, so it's in the foreground.
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              sp['name'] ?? 'Специальность',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            });
          },
        ),
      ),
    );
  }
}
