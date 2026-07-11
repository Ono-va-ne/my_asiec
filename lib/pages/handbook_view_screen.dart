import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class HandbookViewScreen extends StatelessWidget {
  final String title;
  final String type;
  final String formula;
  final String description;
  final String imageUrl;
  final String latexHandbook;
  final String tags;
  final String primaryTags;

  const HandbookViewScreen({
    super.key,
    required this.title,
    required this.type,
    required this.formula,
    required this.description,
    required this.imageUrl,
    required this.latexHandbook,
    required this.tags,
    required this.primaryTags
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            if (imageUrl.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // LaTeX Handbook
            if (type == 'formula')
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(
                      latexHandbook,
                      textStyle: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),

            // Description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(description, style: const TextStyle(fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0, // Горизонтальный отступ между чипами
                runSpacing: 4.0, // Вертикальный отступ между строками чипов
                children: [
                  if (primaryTags.isNotEmpty)
                    ...primaryTags.split(',').map((tag) => Chip(
                          label: Text(tag.trim()),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        )),
                  if (tags.isNotEmpty)
                    ...tags.split(',').map((tag) => Chip(
                          label: Text(tag.trim()),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
