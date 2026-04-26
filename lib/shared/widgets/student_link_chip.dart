import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../utils/formatting.dart';
import 'student_avatar.dart';

class StudentLinkChip extends StatelessWidget {
  const StudentLinkChip({
    required this.student,
    this.avatarSize = 20,
    super.key,
  });

  final Student student;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: StudentAvatar(student: student, size: avatarSize),
      label: Text(
        studentDisplayName(
          firstName: student.firstName,
          lastName: student.lastName,
        ),
      ),
      onPressed: () => context.push('/students/${student.id}'),
    );
  }
}
