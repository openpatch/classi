import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../utils/formatting.dart';
import 'student_avatar.dart';

class StudentLinkChip extends ConsumerWidget {
  const StudentLinkChip({
    required this.student,
    this.avatarSize = 20,
    super.key,
  });

  final Student student;
  final double avatarSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);
    return ActionChip(
      avatar: StudentAvatar(student: student, size: avatarSize),
      label: Text(
        studentDisplayName(
          firstName: student.firstName,
          lastName: student.lastName,
          callName: student.callName,
          sortField: sortField,
        ),
      ),
      onPressed: () => context.push('/students/${student.id}'),
    );
  }
}
