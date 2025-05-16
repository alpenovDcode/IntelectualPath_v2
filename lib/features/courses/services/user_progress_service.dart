import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgressService {
  final _progressRef = FirebaseFirestore.instance.collection('user_progress');

  Future<void> saveProgress({
    required String userId,
    required String courseId,
    required Map<String, dynamic> progressData,
  }) async {
    await _progressRef.doc(userId).set({
      'courseProgress.$courseId': progressData,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getProgress({
    required String userId,
    required String courseId,
  }) async {
    final doc = await _progressRef.doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return (data['courseProgress'] ?? {})[courseId] as Map<String, dynamic>?;
  }
} 