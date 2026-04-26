import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../students/student_sorting.dart';

const _studentSortPreferenceKey = 'student_sort_field';

class StudentSortController extends ChangeNotifier {
  StudentSortField _sortField = StudentSortField.lastName;

  StudentSortField get sortField => _sortField;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _sortField = StudentSortFieldPersistence.fromStorage(
      preferences.getString(_studentSortPreferenceKey),
    );
    notifyListeners();
  }

  Future<void> setSortField(StudentSortField value) async {
    if (_sortField == value) {
      return;
    }

    _sortField = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_studentSortPreferenceKey, value.storageValue);
  }
}
