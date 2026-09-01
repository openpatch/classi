import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/widgets/empty_state.dart';
import 'webuntis_api.dart';
import 'webuntis_models.dart';

/// Asks which WebUntis class a group corresponds to.
///
/// Shown the first time a group that was not imported from WebUntis is synced,
/// so the link is established once instead of on every sync.
Future<WebUntisKlasse?> showWebUntisKlassePicker({
  required BuildContext context,
}) {
  return showModalBottomSheet<WebUntisKlasse>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const _WebUntisKlassePicker(),
  );
}

class _WebUntisKlassePicker extends ConsumerStatefulWidget {
  const _WebUntisKlassePicker();

  @override
  ConsumerState<_WebUntisKlassePicker> createState() =>
      _WebUntisKlassePickerState();
}

class _WebUntisKlassePickerState extends ConsumerState<_WebUntisKlassePicker> {
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _query = '';
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
      final userData = await ref.read(webUntisServiceProvider).loadUserData();
      if (!mounted) {
        return;
      }
      final today = DateTime.now();
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? _klassen
        : _klassen
              .where(
                (klasse) =>
                    klasse.name.toLowerCase().contains(query) ||
                    klasse.longName.toLowerCase().contains(query),
              )
              .toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xxLarge,
        right: AppSpacing.xxLarge,
        top: AppSpacing.xxLarge,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxLarge,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('webuntis_pick_class'.tr(), style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.small),
            Text(
              'webuntis_pick_class_hint'.tr(),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.large),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error case final message?)
              Expanded(
                child: Center(
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
                ),
              )
            else ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: 'search'.tr(),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: AppSpacing.small),
              Expanded(
                child: visible.isEmpty
                    ? EmptyState(
                        icon: Icons.school_outlined,
                        title: 'webuntis_no_classes'.tr(),
                      )
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final klasse = visible[index];
                          return ListTile(
                            title: Text(klasse.displayName),
                            subtitle:
                                klasse.longName.isEmpty ||
                                    klasse.longName == klasse.name
                                ? null
                                : Text(klasse.longName),
                            onTap: () => Navigator.of(context).pop(klasse),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
