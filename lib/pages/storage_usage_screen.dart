import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class StorageUsageScreen extends StatefulWidget {
  const StorageUsageScreen({super.key});

  @override
  State<StorageUsageScreen> createState() => _StorageUsageScreenState();
}

class _StorageUsageScreenState extends State<StorageUsageScreen> {
  List<CacheCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheData();
  }

  Future<void> _loadCacheData() async {
    setState(() => _isLoading = true);
    final breakdown = await StorageService.getCacheBreakdown(context);
    setState(() {
      _categories = breakdown;
      _isLoading = false;
    });
  }

  int get _totalBytes =>
      _categories.fold(0, (sum, item) => sum + item.sizeInBytes);

  void _clearSingleCategory(CacheCategory category) async {
    await StorageService.clearCategoryCache(category.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Кэш "${category.title}" очищен')),
    );
    _loadCacheData();
  }

  void _clearAllCache() async {
    await StorageService.clearAllCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Весь кэш приложения очищен')),
    );
    _loadCacheData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Использование памяти'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // ДИАГРАММА-ПОНЧИК TELEGRAM STYLE
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(200, 200),
                          painter: DonutChartPainter(
                            categories: _categories,
                            totalBytes: _totalBytes,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              StorageService.formatBytes(_totalBytes),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Кэш приложения',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Кнопка очистки всего кэша
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('Очистить весь кэш'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      onPressed: _totalBytes > 0 ? _clearAllCache : null,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),

                  // Категории с индивидуальной очисткой
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cat.color.withAlpha(55),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        title: Text(
                          cat.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          StorageService.formatBytes(cat.sizeInBytes),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.grey),
                          tooltip: 'Очистить ${cat.title}',
                          onPressed: cat.sizeInBytes > 0
                              ? () => _clearSingleCategory(cat)
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

// ОТРИСОВКА ДИАГРАММЫ-ПОНЧИКА ЧЕРЕЗ CUSTOMPAINTER
class DonutChartPainter extends CustomPainter {
  final List<CacheCategory> categories;
  final int totalBytes;

  DonutChartPainter({required this.categories, required this.totalBytes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Серая подложка (если кэша нет)
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    canvas.drawCircle(center, radius, bgPaint);

    if (totalBytes <= 0) return;

    double startAngle = -pi / 2; // Начинаем с самого верха (-90 градусов)

    for (var cat in categories) {
      if (cat.sizeInBytes <= 0) continue;

      final sweepAngle = (cat.sizeInBytes / totalBytes) * 2 * pi;

      final catPaint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;

      // Рисуем дугу сектора с зазором
      canvas.drawArc(rect, startAngle + 0.04, sweepAngle - 0.04, false, catPaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}