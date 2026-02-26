import 'package:my_asiec/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        .order('name', ascending: true);
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
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final photoUrl = member['photo_url'] as String?;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 6.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 1.0,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: (photoUrl != null && photoUrl.isNotEmpty) 
                            ? Image.network(photoUrl)
                            : const Icon(Icons.person),
                        ),
                        title: Text(member['name'] ?? 'Без имени'),
                        subtitle: Text('${member['group'] ?? ''}\n${member['info'] ?? ''}'),
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
