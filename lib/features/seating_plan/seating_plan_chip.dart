import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/student_avatar.dart';

/// A draggable chip that represents a student on the seating plan canvas.
///
/// Shows a [StudentAvatar] above the student's name. In lesson mode, pass
/// [lessonOverlay] to paint extra feedback (e.g. absence badge) on top of the
/// avatar.
class SeatingPlanChip extends ConsumerWidget {
  const SeatingPlanChip({
    required this.student,
    required this.onTap,
    this.lessonOverlay,
    super.key,
  });

  final Student student;

  /// Called when the chip is tapped.
  final VoidCallback onTap;

  /// Optional widget layered over the avatar (e.g. absence indicator).
  final Widget? lessonOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);
    final name = studentDisplayName(
      firstName: student.firstName,
      lastName: student.lastName,
      sortField: sortField,
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _chipWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                StudentAvatar(student: student, size: _avatarSize),
                ?lessonOverlay,
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Visual width of the chip.
const double _chipWidth = 80.0;

/// Avatar diameter.
const double _avatarSize = 44.0;

/// Total height of a chip (avatar + gap + two lines of text).
const double chipHeight = _avatarSize + 4 + 32.0;
