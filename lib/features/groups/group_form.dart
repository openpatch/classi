import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../settings/grade_system_controller.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';

typedef GroupFormResult = ({
  String name,
  String colorHex,
  List<GradeScaleEntry> gradeScale,
  List<GradeCategory> gradeCategories,
});

Future<GroupFormResult?> showGroupFormSheet({
  required BuildContext context,
  required List<GradeSystemDefinition> gradeSystems,
  String? initialName,
  String? initialGroupColorHex,
  List<GradeScaleEntry>? initialGradeScale,
  List<GradeCategory>? initialGradeCategories,
  String? title,
}) {
  return showModalBottomSheet<GroupFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _GroupFormSheet(
      gradeSystems: gradeSystems,
      initialName: initialName,
      initialGroupColorHex: initialGroupColorHex,
      initialGradeScale: initialGradeScale,
      initialGradeCategories: initialGradeCategories,
      title: title,
    ),
  );
}

class _GroupFormSheet extends StatefulWidget {
  const _GroupFormSheet({
    required this.gradeSystems,
    this.initialName,
    this.initialGroupColorHex,
    this.initialGradeScale,
    this.initialGradeCategories,
    this.title,
  });

  final List<GradeSystemDefinition> gradeSystems;
  final String? initialName;
  final String? initialGroupColorHex;
  final List<GradeScaleEntry>? initialGradeScale;
  final List<GradeCategory>? initialGradeCategories;
  final String? title;

  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<_EditableGradeCategory> _categories;
  late String _selectedGradeSystemId;
  late String _selectedGroupColorHex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _categories = [
      for (final category
          in widget.initialGradeCategories ?? defaultGradeCategories)
        _EditableGradeCategory.fromCategory(category),
    ];
    final initialScale = widget.initialGradeScale ?? defaultGradeScaleEntries;
    final matchingSystem = _matchingGradeSystem(initialScale);
    _selectedGradeSystemId =
        matchingSystem?.id ??
        (widget.gradeSystems.isEmpty
            ? 'default-1-6'
            : widget.gradeSystems.first.id);
    _selectedGroupColorHex = normalizeColorHex(
      widget.initialGroupColorHex,
      fallback: groupColorPalette.first,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final category in _categories) {
      category.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'add_group'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'group_name'.tr()),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'group_name'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGradeSystemId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'grade_scale'.tr(),
                  helperText: 'grade_scale_hint'.tr(),
                ),
                items: [
                  for (final system in widget.gradeSystems)
                    DropdownMenuItem<String>(
                      value: system.id,
                      child: Text(
                        '${system.name} - '
                        '${system.entries.map((entry) => entry.label).join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedGradeSystemId = value);
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickGroupColor,
                  icon: Icon(
                    Icons.circle,
                    color: colorFromHex(_selectedGroupColorHex),
                  ),
                  label: Text('group_color'.tr()),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'grade_categories'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < _categories.length; index++) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _categories[index].nameController,
                                decoration: InputDecoration(
                                  labelText: 'category_name'.tr(),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'category_name'.tr()
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _categories[index].weightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'category_weight'.tr(),
                                ),
                                validator: (value) {
                                  final parsed = double.tryParse(
                                    (value ?? '').trim(),
                                  );
                                  if (parsed == null || parsed <= 0) {
                                    return 'category_weight'.tr();
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _categories.length > 1
                                  ? () => _removeCategory(index)
                                  : null,
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'delete'.tr(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => _pickCategoryColor(index),
                            icon: Icon(
                              Icons.circle,
                              color: colorFromHex(_categories[index].colorHex),
                            ),
                            label: Text('category_color'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: Text('add_category'.tr()),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr()),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _save, child: Text('save'.tr())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      colorHex: _selectedGroupColorHex,
      gradeScale: _selectedGradeSystem.entries,
      gradeCategories: _parseCategories(),
    ));
  }

  Future<void> _pickGroupColor() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('group_color'.tr()),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final colorHex in groupColorPalette)
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.of(context).pop(colorHex),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: colorFromHex(colorHex),
                  child: _selectedGroupColorHex == colorHex
                      ? Icon(
                          Icons.check,
                          color: onColorForBackground(colorFromHex(colorHex)),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
    if (selected == null) {
      return;
    }

    setState(() => _selectedGroupColorHex = selected);
  }

  List<GradeCategory> _parseCategories() {
    final usedIds = <String>{};
    return _categories
        .map((category) {
          final id = _uniqueCategoryId(
            baseName: category.nameController.text.trim(),
            usedIds: usedIds,
            id: category.id,
          );
          usedIds.add(id);
          return GradeCategory(
            id: id,
            name: category.nameController.text.trim(),
            weight: double.parse(category.weightController.text.trim()),
            colorHex: category.colorHex,
          );
        })
        .toList(growable: false);
  }

  void _addCategory() {
    setState(() {
      _categories.add(
        _EditableGradeCategory.newCategory(
          colorHex: fallbackCategoryColorHex('', _categories.length),
        ),
      );
    });
  }

  void _removeCategory(int index) {
    final category = _categories.removeAt(index);
    category.dispose();
    setState(() {});
  }

  String _uniqueCategoryId({
    required String baseName,
    required Set<String> usedIds,
    required String id,
  }) {
    if (id.isNotEmpty && !usedIds.contains(id)) {
      return id;
    }

    final normalizedBase = _normalizeCategoryId(baseName);
    var candidate = normalizedBase;
    var suffix = 2;
    while (usedIds.contains(candidate)) {
      candidate = '$normalizedBase-$suffix';
      suffix++;
    }
    return candidate;
  }

  String _normalizeCategoryId(String name) {
    final lowercase = name.toLowerCase();
    final buffer = StringBuffer();
    var previousDash = false;
    for (final rune in lowercase.runes) {
      final char = String.fromCharCode(rune);
      final mapped = switch (char) {
        'ä' => 'ae',
        'ö' => 'oe',
        'ü' => 'ue',
        'ß' => 'ss',
        _ => char,
      };
      for (final mappedRune in mapped.runes) {
        final mappedChar = String.fromCharCode(mappedRune);
        final isAlphaNumeric =
            (mappedChar.codeUnitAt(0) >= 97 &&
                mappedChar.codeUnitAt(0) <= 122) ||
            (mappedChar.codeUnitAt(0) >= 48 && mappedChar.codeUnitAt(0) <= 57);
        if (isAlphaNumeric) {
          buffer.write(mappedChar);
          previousDash = false;
        } else if (!previousDash && buffer.isNotEmpty) {
          buffer.write('-');
          previousDash = true;
        }
      }
    }

    final result = buffer.toString().replaceAll(RegExp(r'-+$'), '');
    return result.isEmpty ? 'kategorie' : result;
  }

  Future<void> _pickCategoryColor(int index) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('category_color'.tr()),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final colorHex in gradeCategoryColorPalette)
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.of(context).pop(colorHex),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: colorFromHex(colorHex),
                  child: _categories[index].colorHex == colorHex
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
    if (selected == null) {
      return;
    }

    setState(() => _categories[index].colorHex = selected);
  }

  GradeSystemDefinition get _selectedGradeSystem {
    for (final system in widget.gradeSystems) {
      if (system.id == _selectedGradeSystemId) {
        return system;
      }
    }
    return widget.gradeSystems.first;
  }

  GradeSystemDefinition? _matchingGradeSystem(List<GradeScaleEntry> entries) {
    for (final system in widget.gradeSystems) {
      if (sameGradeScaleEntries(system.entries, entries)) {
        return system;
      }
    }
    return null;
  }
}

class _EditableGradeCategory {
  _EditableGradeCategory({
    required this.id,
    required this.nameController,
    required this.weightController,
    required this.colorHex,
  });

  factory _EditableGradeCategory.fromCategory(GradeCategory category) {
    return _EditableGradeCategory(
      id: category.id,
      nameController: TextEditingController(text: category.name),
      weightController: TextEditingController(
        text: category.weight.toStringAsFixed(
          category.weight == category.weight.roundToDouble() ? 0 : 1,
        ),
      ),
      colorHex: category.colorHex,
    );
  }

  factory _EditableGradeCategory.newCategory({required String colorHex}) {
    return _EditableGradeCategory(
      id: '',
      nameController: TextEditingController(),
      weightController: TextEditingController(text: '1'),
      colorHex: colorHex,
    );
  }

  final String id;
  final TextEditingController nameController;
  final TextEditingController weightController;
  String colorHex;

  void dispose() {
    nameController.dispose();
    weightController.dispose();
  }
}
