import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import 'webuntis_api.dart';
import 'webuntis_link.dart';
import 'webuntis_models.dart';

/// What the teacher chose in [showWebUntisLinkPicker].
sealed class WebUntisLinkChoice {
  const WebUntisLinkChoice();
}

/// Link the group to this course or class.
class WebUntisLinkTo extends WebUntisLinkChoice {
  const WebUntisLinkTo(this.link);

  final WebUntisGroupLink link;
}

/// Take the group's link away.
class WebUntisUnlink extends WebUntisLinkChoice {
  const WebUntisUnlink();
}

/// Asks what a group stands for in WebUntis: one of the teacher's courses or
/// a whole class. Returns `null` when the teacher backs out.
///
/// Courses come first because they are what most groups are: a course holds
/// exactly its own students, whether that is half a class or students from
/// several. [linked] offers a way to remove an existing link.
Future<WebUntisLinkChoice?> showWebUntisLinkPicker({
  required BuildContext context,
  bool linked = false,
}) {
  return showModalBottomSheet<WebUntisLinkChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _WebUntisLinkPicker(linked: linked),
  );
}

/// When a course meets, e.g. `Mon 08:00 · Thu 09:45`.
String webUntisCourseSchedule(BuildContext context, WebUntisCourse course) {
  final locale = context.locale.toLanguageTag();
  return course.slots
      .map(
        (slot) =>
            '${DateFormat.E(locale).format(slot)} ${DateFormat.Hm(locale).format(slot)}',
      )
      .join(' · ');
}

class _WebUntisLinkPicker extends ConsumerStatefulWidget {
  const _WebUntisLinkPicker({required this.linked});

  final bool linked;

  @override
  ConsumerState<_WebUntisLinkPicker> createState() =>
      _WebUntisLinkPickerState();
}

class _WebUntisLinkPickerState extends ConsumerState<_WebUntisLinkPicker> {
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _query = '';
  List<WebUntisCourse> _courses = const [];
  List<WebUntisKlasse> _klassen = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(webUntisServiceProvider);
      final courses = await service.loadCourses();
      final userData = await service.loadUserData();
      if (!mounted) {
        return;
      }
      final today = DateTime.now();
      setState(() {
        _courses = courses;
        _klassen =
            userData.klassen
                .where((klasse) => klasse.active && klasse.runsOn(today))
                .toList()
              ..sort(
                (a, b) => a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                ),
              );
        _loading = false;
      });
    } on WebUntisException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.translationKey.tr();
          _loading = false;
        });
      }
    }
  }

  bool _matches(String text) =>
      text.toLowerCase().contains(_query.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xxLarge,
        right: AppSpacing.xxLarge,
        top: AppSpacing.xxLarge,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxLarge,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('webuntis_link_title'.tr(), style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.small),
            Text('webuntis_link_hint'.tr(), style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.large),
            Expanded(child: _buildBody(theme)),
            if (widget.linked) ...[
              const SizedBox(height: AppSpacing.medium),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(const WebUntisUnlink()),
                icon: const Icon(Icons.link_off),
                label: Text('webuntis_unlink'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error case final message?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.large),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    final courses = _courses
        .where((course) => _matches(course.displayName))
        .toList(growable: false);
    final klassen = _klassen
        .where((klasse) => _matches(klasse.name) || _matches(klasse.longName))
        .toList(growable: false);

    Widget header(String key) => Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.medium,
        bottom: AppSpacing.xSmall,
      ),
      child: Text(
        key.tr(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: 'search'.tr(),
            isDense: true,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        Expanded(
          child: ListView(
            children: [
              header('webuntis_your_courses'),
              if (courses.isEmpty)
                Text(
                  'webuntis_no_courses'.tr(),
                  style: theme.textTheme.bodySmall,
                )
              else
                for (final course in courses)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.groups_2_outlined),
                    title: Text(course.displayName),
                    subtitle: Text(webUntisCourseSchedule(context, course)),
                    onTap: () => Navigator.of(context).pop(
                      WebUntisLinkTo(
                        WebUntisGroupLink.course(course.lessonIds),
                      ),
                    ),
                  ),
              header('webuntis_whole_classes'),
              for (final klasse in klassen)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.school_outlined),
                  title: Text(klasse.displayName),
                  subtitle:
                      klasse.longName.isEmpty || klasse.longName == klasse.name
                      ? null
                      : Text(klasse.longName),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(WebUntisLinkTo(WebUntisGroupLink.klasse(klasse.id))),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
