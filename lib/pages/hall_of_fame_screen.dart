import 'package:my_asiec/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HallOfFameScreen extends StatefulWidget {
  const HallOfFameScreen({super.key});

  @override
  State<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends State<HallOfFameScreen> {
  late final Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchHallOfFame();
  }

  Future<List<Map<String, dynamic>>> _fetchHallOfFame() async {
    final response = await Supabase.instance.client
        .from('hall_of_fame')
        .select()
        .order('id', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Зал славы'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final members = snapshot.data ?? [];
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Пока здесь никого нет.'),
                  const SizedBox(height: 16),
                  Text(
                    'Поддержите разработку и попадите в Зал славы!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final photoUrl = member['photo_url'] as String?;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.0),
                        onTap: () async {
                          final urlString = member['url'] as String?;
                          if (urlString != null && urlString.isNotEmpty) {
                            await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: (photoUrl != null && photoUrl.isNotEmpty)
                                    ? Image.network(photoUrl, width: 64, height: 64, fit: BoxFit.cover)
                                    : const SizedBox(width: 64, height: 64, child: Icon(Icons.person, size: 32)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member['name'] ?? 'Без имени',
                                      style: TextStyle(
                                        color: member['url'] != null ? Theme.of(context).colorScheme.primary : null,
                                        fontVariations: [const FontVariation('wdth', 150)],
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (member['group'] != null && (member['group'] as String).isNotEmpty)
                                      Text(
                                        member['group'],
                                        style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.w700),
                                      ),
                                    if (member['info'] != null && (member['info'] as String).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(member['info']),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                child: Text(
                  AppLocalizations.of(context)!.hallOfFameTip,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
