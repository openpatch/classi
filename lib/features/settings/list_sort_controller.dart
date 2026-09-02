import 'package:flutter/foundation.dart';

import '../../core/storage/project_settings_store.dart';
import '../lists/list_sorting.dart';

const _listSortPath = ['lists', 'sortField'];
const _listItemSortPath = ['lists', 'itemSortField'];

/// Remembers how the lists screen is sorted.
///
/// Kept in the library's own settings rather than on the device, the way the
/// student sort is: the order a teacher wants belongs to the library they open,
/// not to the machine they happen to open it on.
class ListSortController extends ChangeNotifier {
  ListSortController({ProjectSettingsStore? projectSettingsStore})
    : _projectSettingsStore = projectSettingsStore ?? ProjectSettingsStore();

  final ProjectSettingsStore _projectSettingsStore;
  ListSortField _sortField = ListSortField.name;
  ListItemSortField _itemSortField = ListItemSortField.entered;

  /// How the lists themselves are ordered.
  ListSortField get sortField => _sortField;

  /// How the entries inside a list are ordered.
  ListItemSortField get itemSortField => _itemSortField;

  Future<void> initialize() async {
    final settings = await _projectSettingsStore.read();
    _sortField = ListSortFieldPersistence.fromStorage(
      ProjectSettingsStore.stringAt(settings, _listSortPath),
    );
    _itemSortField = ListItemSortFieldPersistence.fromStorage(
      ProjectSettingsStore.stringAt(settings, _listItemSortPath),
    );
    notifyListeners();
  }

  Future<void> setSortField(ListSortField value) async {
    if (_sortField == value) {
      return;
    }

    _sortField = value;
    notifyListeners();

    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(settings, _listSortPath, value.storageValue);
      return settings;
    });
  }

  Future<void> setItemSortField(ListItemSortField value) async {
    if (_itemSortField == value) {
      return;
    }

    _itemSortField = value;
    notifyListeners();

    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(
        settings,
        _listItemSortPath,
        value.storageValue,
      );
      return settings;
    });
  }
}
