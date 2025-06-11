import 'package:flutter/material.dart';

class ReminderModel {
  final int id;
  final String content;
  final DateTime createdAt;
  final bool enabled;
  final TimeOfDay alarm;
  final String userId;

  ReminderModel({
  required this.id,
  required this.content,
  required this.alarm,
  required this.createdAt,
  required this.enabled,
  required this.userId,
  });
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    final alarmString = json['alarm'] as String;
    final alarmParts = alarmString.split(':');
    final hour = int.parse(alarmParts[0]);
    final minute = int.parse(alarmParts[1]);

    return ReminderModel(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      enabled: json['enabled'],
      createdAt: DateTime.parse(json['created_at']),
      alarm: TimeOfDay(hour: hour, minute: minute),
    );
  }
}