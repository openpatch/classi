import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/widgets/empty_state.dart';
import 'webuntis_api.dart';
import 'webuntis_models.dart';

/// Opens the class picker and creates a group for every class the teacher
/// ticks. Returns how many groups were created, or `null` when cancelled.
Future<int?> showWebUntisClassImportSheet({required BuildContext context}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const _WebUntisClassImportSheet(),
  );
}

class _WebUntisClassImportSheet extends ConsumerStatefulWidget {
  const _WebUntisClassImportSheet();

  @override
  ConsumerState<_WebUntisClassImportSheet> createState() =>
      _WebUntisClassImportSheetState();
}

class _WebUntisClassImportSheetState
    extends ConsumerState<_WebUntisClassImportSheet> {
  final _selected = <int>{};
  final _searchController = TextEditingController();

  bool _loading = true;
  bool _importing = false;
  bool _showInactive = false;
  String? _error;
  String _query = '';

  List<WebUntisKlasse> _klassen = const [];
  Map<int, Group> _existingByKlasseId = const {};

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
      final userData = await ref.read(webUntisServiceProvider).loadUserData();
      final existing = await ref
          .read(groupRepositoryProvider)
          .groupsByWebUntisKlasseId();

      if (!mounted) {
        return;
      }
      setState(() {
        _klassen = [...userData.klassen]
          ..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );
        _existingByKlasseId = existing;
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

  /// Classes worth offering: those running today, unless the teacher asks to
  /// see the rest. WebUntis keeps years of retired classes around, and a list
  /// of six hundred is not a picker.
  List<WebUntisKlasse> get _visibleKlassen {
    final today = DateTime.now();
    final query = _query.trim().toLowerCase();

    return _klassen
        .where((klasse) {
          if (!_showInactive && !(klasse.active && klasse.runsOn(today))) {
            return _selected.contains(klasse.id);
          }
          if (query.isEmpty) {
            return true;
          }
          return klasse.name.toLowerCase().contains(query) ||
              klasse.longName.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

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
            Text(
              'webuntis_import_classes'.tr(),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'webuntis_import_classes_hint'.tr(),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.large),
            Expanded(child: _buildBody(theme)),
            const SizedBox(height: AppSpacing.large),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _importing
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text('cancel'.tr()),
                ),
                const SizedBox(width: AppSpacing.medium),
                FilledButton(
                  onPressed: _selected.isEmpty || _importing ? null : _import,
                  child: _importing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'webuntis_import_selected'.tr(
                            namedArgs: {'count': _selected.length.toString()},
                          ),
                        ),
                ),
              ],
            ),
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

    if (_klassen.isEmpty) {
      return EmptyState(
        icon: Icons.school_outlined,
        title: 'webuntis_no_classes'.tr(),
        body: 'webuntis_no_classes_hint'.tr(),
      );
    }

    final visible = _visibleKlassen;

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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _showInactive,
          title: Text('webuntis_show_inactive_classes'.tr()),
          onChanged: (value) => setState(() => _showInactive = value),
        ),
        const Divider(height: 1),
        Expanded(
          child: visible.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: 'webuntis_no_classes'.tr(),
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final klasse = visible[index];
                    final existing = _existingByKlasseId[klasse.id];

                    return CheckboxListTile(
                      value: _selected.contains(klasse.id),
                      title: Text(klasse.displayName),
                      subtitle: existing != null
                          ? Text(
                              'webuntis_class_already_imported'.tr(
                                namedArgs: {'group': existing.name},
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : (klasse.longName.isEmpty ||
                                klasse.longName == klasse.name)
                          ? null
                          : Text(klasse.longName),
                      // A class that already has a group cannot be picked:
                      // importing it again would leave two groups fighting
                      // over one class register.
                      onChanged: existing != null
                          ? null
                          : (checked) => setState(() {
                              if (checked ?? false) {
                                _selected.add(klasse.id);
                              } else {
                                _selected.remove(klasse.id);
                              }
                            }),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _import() async {
    final gradeSystems = ref.read(gradeSystemControllerProvider).systems;
    if (gradeSystems.isEmpty) {
      setState(() => _error = 'webuntis_error_generic'.tr());
      return;
    }

    setState(() => _importing = true);

    final defaultSystem = gradeSystems.first;
    final groupRepository = ref.read(groupRepositoryProvider);
    final schoolYearId = ref.read(activeSchoolYearIdProvider);

    var created = 0;
    try {
      for (final klasse in _klassen.where(
        (klasse) => _selected.contains(klasse.id),
      )) {
        await groupRepository.createGroup(
          name: klasse.displayName,
          gradeScale: defaultSystem.entries,
          schoolYearId: schoolYearId,
          webuntisKlasseId: klasse.id,
        );
        created++;
      }

      if (created > 0) {
        await ref.read(webUntisServiceProvider).markSynced();
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }

    if (mounted) {
      Navigator.of(context).pop(created);
    }
  }
}
