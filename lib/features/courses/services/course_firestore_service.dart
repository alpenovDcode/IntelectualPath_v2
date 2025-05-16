import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CourseFirestoreService {
  final _coursesRef = FirebaseFirestore.instance.collection('courses');

  Future<void> addCourse(Course course) async {
    await _coursesRef.doc(course.id).set(course.toJson());
  }

  Future<List<Course>> getAllCourses() async {
    final snapshot = await _coursesRef.get();
    return snapshot.docs.map((doc) => Course.fromJson(doc.data())).toList();
  }

  Future<Course?> getCourseById(String id) async {
    final doc = await _coursesRef.doc(id).get();
    if (!doc.exists) return null;
    return Course.fromJson(doc.data()!);
  }
} 