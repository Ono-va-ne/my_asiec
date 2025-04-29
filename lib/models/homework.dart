import 'package:cloud_firestore/cloud_firestore.dart';

class Homework {
  String? id;
  final String discipline;
  final String group;
  final String? subgroup;
  final String task;
  final DateTime dueDate;
  final List<String>? photoUrls;
  final DateTime dateAdded;

  Homework({
    this.id,
    required this.discipline,
    required this.group,
    this.subgroup,
    required this.task,
    required this.dueDate,
    this.photoUrls,
    required this.dateAdded,
  });
  Map<String, dynamic> toJson() {
    return {
      'discipline': discipline,
      'group': group,
      'subgroup': subgroup,
      'task': task,
      'dueDate': Timestamp.fromDate(dueDate),
      'photoUrls': photoUrls,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }

  factory Homework.fromJson(Map<String, dynamic> json, String id) {
    return Homework(
      id: id,
      discipline: json['discipline'] as String,
      group: json['group'] as String,
      subgroup: json['subgroup'] as String?,
      task: json['task'] as String,
      dueDate: (json['dueDate'] as Timestamp).toDate(),
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.map((item) => item as String).toList(),
      dateAdded: (json['dateAdded'] as Timestamp).toDate()
    );
  }
}