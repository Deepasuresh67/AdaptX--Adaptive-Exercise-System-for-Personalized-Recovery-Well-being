import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseProgress {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final int completedReps;
  final int targetReps;
  final Duration completedDuration;
  final Duration targetDuration;
  final DateTime date;
  final String mood;
  final bool isCompleted;
  final Map<String, dynamic>? notes;

  ExerciseProgress({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.completedReps,
    required this.targetReps,
    required this.completedDuration,
    required this.targetDuration,
    required this.date,
    required this.mood,
    required this.isCompleted,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'completedReps': completedReps,
      'targetReps': targetReps,
      'completedDuration': completedDuration.inSeconds,
      'targetDuration': targetDuration.inSeconds,
      'date': Timestamp.fromDate(date),
      'mood': mood,
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }

  factory ExerciseProgress.fromMap(Map<String, dynamic> map, String id) {
    return ExerciseProgress(
      id: id,
      userId: map['userId'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      completedReps: map['completedReps'] ?? 0,
      targetReps: map['targetReps'] ?? 0,
      completedDuration: Duration(seconds: map['completedDuration'] ?? 0),
      targetDuration: Duration(seconds: map['targetDuration'] ?? 0),
      date: (map['date'] as Timestamp).toDate(),
      mood: map['mood'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      notes: map['notes'],
    );
  }

  double get completionPercentage {
    if (targetReps > 0) {
      return (completedReps / targetReps) * 100;
    } else if (targetDuration.inSeconds > 0) {
      return (completedDuration.inSeconds / targetDuration.inSeconds) * 100;
    }
    return 0;
  }

  ExerciseProgress copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? exerciseName,
    int? completedReps,
    int? targetReps,
    Duration? completedDuration,
    Duration? targetDuration,
    DateTime? date,
    String? mood,
    bool? isCompleted,
    Map<String, dynamic>? notes,
  }) {
    return ExerciseProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      completedReps: completedReps ?? this.completedReps,
      targetReps: targetReps ?? this.targetReps,
      completedDuration: completedDuration ?? this.completedDuration,
      targetDuration: targetDuration ?? this.targetDuration,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }
} 