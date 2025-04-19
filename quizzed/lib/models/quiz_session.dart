import 'package:cloud_firestore/cloud_firestore.dart';

class QuizSession {
  final String? id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final bool isActive;
  final int
  validationThreshold; // Percentage required for open answer validation

  QuizSession({
    this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.isActive,
    this.validationThreshold = 50, // Default is 50%
  });

  // Convert a Firestore document to a QuizSession object
  factory QuizSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return QuizSession(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? false,
      validationThreshold: data['validationThreshold'] ?? 50,
    );
  }

  // Convert a QuizSession object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
      'validationThreshold': validationThreshold,
    };
  }
}
