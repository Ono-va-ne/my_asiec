import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class HandbookViewScreen extends StatelessWidget {
  final String title;
  final String formula;
  final String description;
  final String imageUrl;
  final String latexHandbook;
  final String tags;

  const HandbookViewScreen({
    super.key,
    required this.title,
    required this.formula,
    required this.description,
    required this.imageUrl,
    required this.latexHandbook,
    required this.tags,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Math.tex(
                  latexHandbook,
                  textStyle: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(description, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
