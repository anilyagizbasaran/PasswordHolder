import 'package:flutter/material.dart';

typedef UserSelectionChanged = void Function(Set<int> selection);

class UserAssignmentField extends StatefulWidget {
  const UserAssignmentField({
    super.key,
    required this.users,
    required this.selectedUserIds,
    required this.onSelectionChanged,
    required this.canSelectMultiple,
    this.labelText = 'Kullanıcı Seç',
    this.validator,
  });

  final List<Map<String, dynamic>> users;
  final Set<int> selectedUserIds;
  final UserSelectionChanged onSelectionChanged;
  final bool canSelectMultiple;
  final String labelText;
  final FormFieldValidator<Set<int>>? validator;

  @override
  State<UserAssignmentField> createState() => _UserAssignmentFieldState();
}

class _UserAssignmentFieldState extends State<UserAssignmentField> {
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    if (widget.canSelectMultiple) {
      return _buildMultiSelectField(context);
    }
    return _buildSingleSelectField();
  }

  Widget _buildSingleSelectField() {
    final int? currentValue =
        widget.selectedUserIds.isEmpty ? null : widget.selectedUserIds.first;

    return DropdownButtonFormField<int>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
      ),
      items: _filteredUsers()
          .map(
            (user) => DropdownMenuItem<int>(
              value: user['id'] as int,
              child: Text(_buildUserLabel(user)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) {
          widget.onSelectionChanged(<int>{});
        } else {
          widget.onSelectionChanged(<int>{value});
        }
      },
      validator: (value) {
        final Set<int> selection =
            value == null ? <int>{} : <int>{value};
        final customMessage = widget.validator?.call(selection);
        if (customMessage != null) {
          return customMessage;
        }
        if (widget.users.isEmpty) {
          return 'Önce kullanıcı oluşturun';
        }
        if (selection.isEmpty) {
          return 'Bir kullanıcı seçin';
        }
        return null;
      },
    );
  }

  Widget _buildMultiSelectField(BuildContext context) {
    final keySignature =
        '${widget.selectedUserIds.length}-${widget.selectedUserIds.hashCode}-${widget.users.length}-$_searchTerm';

    return FormField<Set<int>>(
      key: ValueKey(keySignature),
      validator: (value) {
        final selection = value ?? widget.selectedUserIds;
        final customMessage = widget.validator?.call(selection);
        if (customMessage != null) {
          return customMessage;
        }
        if (widget.users.isEmpty) {
          return 'Önce kullanıcı oluşturun';
        }
        if (selection.isEmpty) {
          return 'En az bir kullanıcı seçin';
        }
        return null;
      },
      builder: (field) {
        final selectedChips = _sortedUsersByName()
            .where((user) => widget.selectedUserIds.contains(user['id']))
            .map(
              (user) => InputChip(
                label: Text(user['name'] as String? ?? 'Kullanıcı'),
                onDeleted: () {
                  final updated = Set<int>.from(widget.selectedUserIds)
                    ..remove(user['id'] as int);
                  widget.onSelectionChanged(updated);
                  field.didChange(updated);
                },
              ),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: widget.labelText,
                border: const OutlineInputBorder(),
                errorText: field.errorText,
                contentPadding: const EdgeInsets.all(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...selectedChips,
                      IconButton(
                        tooltip: 'Kullanıcı ekle',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () async {
                          final result = await _openSelectionDialog(context);
                          if (result != null) {
                            widget.onSelectionChanged(result);
                            field.didChange(result);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Set<int>?> _openSelectionDialog(BuildContext context) async {
    final tempSelection = Set<int>.from(widget.selectedUserIds);

    return showDialog<Set<int>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              title: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Kullanıcıları seç'),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Kullanıcı ara',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            _searchTerm = value.trim().toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _filteredUsers().length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers()[index];
                            final userId = user['id'] as int;
                            return CheckboxListTile(
                              value: tempSelection.contains(userId),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    tempSelection.add(userId);
                                  } else {
                                    tempSelection.remove(userId);
                                  }
                                });
                              },
                              title: Text(_buildUserLabel(user)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext)
                        .pop(Set<int>.from(tempSelection));
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _sortedUsersByName() {
    final usersCopy = List<Map<String, dynamic>>.from(widget.users);
    usersCopy.sort((a, b) {
      final aName = (a['name'] ?? '').toString();
      final bName = (b['name'] ?? '').toString();
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });
    return usersCopy;
  }

  String _buildUserLabel(Map<String, dynamic> user) {
    final parts = <String>[];
    final name = (user['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) {
      parts.add(name);
    }
    final email = (user['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) {
      parts.add('($email)');
    }
    final departmentName = (user['departmentName'] as String?)?.trim();
    if (departmentName != null && departmentName.isNotEmpty) {
      parts.add('• $departmentName');
    }
    return parts.isEmpty ? 'Kullanıcı ${(user['id'])}' : parts.join(' ');
  }

  List<Map<String, dynamic>> _filteredUsers() {
    final sorted = _sortedUsersByName();
    if (_searchTerm.isEmpty) {
      return sorted;
    }
    return sorted.where((user) {
      final label = _buildUserLabel(user).toLowerCase();
      return label.contains(_searchTerm);
    }).toList();
  }
}

