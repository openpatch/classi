import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

typedef ListEditorResult = ({
  String name,
  int? groupId,
  bool populateFromGroupStudents,
});

Future<ListEditorResult?> showListEditorDialog({
  required BuildContext context,
  required List<Group> groups,
  required String title,
  required String actionLabel,
  int? initialGroupId,
  String? initialName,
  bool allowGroupSelection = true,
  String? fixedGroupName,
}) {
  return showDialog<ListEditorResult>(
    context: context,
    builder: (context) => _ListEditorDialog(
      groups: groups,
      title: title,
      actionLabel: actionLabel,
      initialGroupId: initialGroupId,
      initialName: initialName,
      allowGroupSelection: allowGroupSelection,
      fixedGroupName: fixedGroupName,
    ),
  );
}

class _ListEditorDialog extends StatefulWidget {
  const _ListEditorDialog({
    required this.groups,
    required this.title,
    required this.actionLabel,
    required this.allowGroupSelection,
    this.initialGroupId,
    this.initialName,
    this.fixedGroupName,
  });

  final List<Group> groups;
  final String title;
  final String actionLabel;
  final int? initialGroupId;
  final String? initialName;
  final bool allowGroupSelection;
  final String? fixedGroupName;

  @override
  State<_ListEditorDialog> createState() => _ListEditorDialogState();
}

class _ListEditorDialogState extends State<_ListEditorDialog> {
  late final TextEditingController _nameController;
  late int? _selectedGroupId;
  bool _populateFromGroupStudents = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedGroupId = widget.initialGroupId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.allowGroupSelection)
            DropdownButtonFormField<int?>(
              initialValue: _selectedGroupId,
              decoration: InputDecoration(labelText: 'list_scope'.tr()),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('global_list'.tr()),
                ),
                for (final group in widget.groups)
                  DropdownMenuItem<int?>(
                    value: group.id,
                    child: Text(group.name),
                  ),
              ],
              onChanged: (value) => setState(() {
                _selectedGroupId = value;
                if (value == null) {
                  _populateFromGroupStudents = false;
                }
              }),
            )
          else if (widget.fixedGroupName != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.groups_outlined),
              title: Text(widget.fixedGroupName!),
              subtitle: Text('groups'.tr()),
            ),
          if (!widget.allowGroupSelection && widget.fixedGroupName != null)
            const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'new_list'.tr()),
          ),
          if (_selectedGroupId != null) ...[
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _populateFromGroupStudents,
              onChanged: (value) =>
                  setState(() => _populateFromGroupStudents = value ?? false),
              title: Text('create_items_for_group_students'.tr()),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              return;
            }
            Navigator.of(context).pop((
              name: name,
              groupId: _selectedGroupId,
              populateFromGroupStudents: _populateFromGroupStudents,
            ));
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
