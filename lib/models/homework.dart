import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'homework.g.dart';

@HiveType(typeId: 0)
class Homework {
  @HiveField(0)
  String? id;
  @HiveField(1)
  final String discipline;
  @HiveField(2)
  final String group;
  @HiveField(3)
  final String groupId;
  @HiveField(4)
  final String? subgroup;
  @HiveField(5)
  final String task;
  @HiveField(6)
  final DateTime dueDate;
  @HiveField(7)
  final List<String>? photoUrls;
  @HiveField(8)
  final DateTime dateAdded;
  @HiveField(9)
  final bool isLocal;

  Homework({
    this.id,
    required this.discipline,
    required this.group,
    required this.groupId,
    this.subgroup,
    required this.task,
    required this.dueDate,
    this.photoUrls,
    required this.dateAdded,
    this.isLocal = false,
  });
  Map<String, dynamic> toJson() {
    return {
      'discipline': discipline,
      'group': group,
      'groupId': groupId,
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
      groupId: json['groupId'] as String,
      subgroup: json['subgroup'] as String?,
      task: json['task'] as String,
      dueDate: (json['dueDate'] as Timestamp).toDate(),
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.map((item) => item as String).toList(),
      dateAdded: (json['dateAdded'] as Timestamp).toDate(),
      isLocal: false,
    );
  }
}