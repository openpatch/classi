import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../utils/avatar_preview.dart';
import '../utils/formatting.dart';

class StudentAvatar extends ConsumerWidget {
  const StudentAvatar({
    required this.student,
    this.size = 40,
    this.onEdit,
    super.key,
  });

  final Student student;
  final double size;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);
    final avatarSvg = avatarSvgFromJson(student.avatarJson);
    final hasStoredAvatarData =
        student.avatarJson != null && student.avatarJson!.isNotEmpty;
    final hueSeed = hasStoredAvatarData
        ? student.avatarJson.hashCode
        : student.id * 41;
    final hue = hueSeed.abs() % 360;
    final backgroundColor = HSLColor.fromAHSL(
      1,
      hue.toDouble(),
      hasStoredAvatarData ? 0.52 : 0.45,
      hasStoredAvatarData ? 0.64 : 0.72,
    ).toColor();
    final foregroundColor = HSLColor.fromAHSL(
      1,
      hue.toDouble(),
      0.45,
      0.18,
    ).toColor();

    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor,
      child: avatarSvg == null
          ? Text(
              studentInitials(
                firstName: student.firstName,
                lastName: student.lastName,
              ),
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.32,
              ),
            )
          : Padding(
              padding: EdgeInsets.all(size * 0.04),
              child: SvgPicture.string(
                avatarSvg,
                width: size * 0.92,
                height: size * 0.92,
                fit: BoxFit.contain,
                semanticsLabel: studentDisplayName(
                  firstName: student.firstName,
                  lastName: student.lastName,
                  sortField: sortField,
                ),
              ),
            ),
    );

    if (onEdit == null) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: Padding(
                padding: EdgeInsets.all(size * 0.12),
                child: Icon(
                  Icons.edit,
                  size: size * 0.24,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
