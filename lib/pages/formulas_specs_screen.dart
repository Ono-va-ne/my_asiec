import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../pages/formulas_by_speciality_screen.dart';

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
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Ошибка: ${snap.error}'));
            }
            final items = snap.data ?? [];
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
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
                        builder:
                            (_) => FormulasBySpecialtyScreen(
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
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    sp['name'] ?? 'Специальность',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sp['description'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // SVG icon in top-right corner (supports inline SVG string or URL)
                        Builder(builder: (context) {
                          final iconData = sp['icon'];
                          if (iconData == null) return const SizedBox.shrink();
                          if (iconData is! String || iconData.trim().isEmpty) return const SizedBox.shrink();
                          Widget iconWidget;
                          final trimmed = iconData.trimLeft();
                          if (trimmed.startsWith('<svg')) {
                            iconWidget = SvgPicture.string(
                              iconData,
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary.withAlpha(155), BlendMode.modulate),
                              placeholderBuilder: (ctx) => const SizedBox(width: 128, height: 128),
                            );
                          } else {
                            iconWidget = SvgPicture.network(
                              iconData,
                              width: 128,
                              height: 128,
                              fit: BoxFit.contain,
                              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primaryContainer, BlendMode.modulate),
                              placeholderBuilder: (ctx) => const SizedBox(width: 128, height: 128, child: Center(child: SizedBox(width:12,height:12,child:CircularProgressIndicator(strokeWidth:2)))),
                              // optional: handle loading errors
                              // semanticsLabel: sp['name'] ?? 'icon',
                            );
                          }
                          return Positioned(
                            bottom: 10,
                            right: 10,
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: iconWidget,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
