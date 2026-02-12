// Clean, complete implementation of homework view screen
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/homework.dart';
import 'homework_edit_screen.dart';

class HomeworkViewScreen extends StatelessWidget {
  final Homework homeworkEntry;

  const HomeworkViewScreen({super.key, required this.homeworkEntry});

  Widget _buildPhotoWidget(BuildContext context, String photoPathOrUrl) {
    if (homeworkEntry.isLocal) {
      final File localFile = File(photoPathOrUrl);
      return FutureBuilder<bool>(
        future: localFile.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data == true) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _FullScreenImageViewer(imagePath: localFile.path, isLocal: true),
                ));
              },
              child: Image.file(
                localFile,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            );
          } else {
            return const SizedBox(
              width: 100,
              height: 100,
              child: Icon(Icons.broken_image, color: Colors.grey),
            );
          }
        },
      );
    } else {
      if (photoPathOrUrl.isNotEmpty) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _FullScreenImageViewer(imagePath: photoPathOrUrl, isLocal: false),
            ));
          },
          child: Image.network(
            photoPathOrUrl,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: 100,
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: 100,
                height: 100,
                child: Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Домашнее задание'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeworkEditScreen(homeworkEntry: homeworkEntry)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              '${homeworkEntry.discipline}${homeworkEntry.subgroup != null ? ' / ${homeworkEntry.subgroup}' : ''}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Срок сдачи: ${DateFormat('dd.MM.yyyy').format(homeworkEntry.due_date)} ${homeworkEntry.isLocal ? '(Локально)' : ''}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Задание:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4.0),
            Text(homeworkEntry.task, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16.0),
            if (homeworkEntry.photo_urls != null && homeworkEntry.photo_urls!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Фотографии:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: homeworkEntry.photo_urls!.map((photoPathOrUrl) => _buildPhotoWidget(context, photoPathOrUrl)).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Full screen viewer with zoom/pan
class _FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final bool isLocal;

  const _FullScreenImageViewer({Key? key, required this.imagePath, required this.isLocal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: SizedBox.expand( // <-- Добавляем SizedBox.expand
            child: isLocal
                ? Image.file(
                    File(imagePath),
                    fit: BoxFit.contain, // <-- Добавляем fit: BoxFit.contain
                  )
                : Image.network(
                    imagePath,
                    fit: BoxFit.contain, // <-- Добавляем fit: BoxFit.contain
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 48));
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
