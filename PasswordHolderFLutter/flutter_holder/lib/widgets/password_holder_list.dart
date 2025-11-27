import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/card_size_option.dart';

class PasswordHolderList extends StatefulWidget {
  const PasswordHolderList({
    super.key,
    required this.entries,
    required this.resolveField,
    required this.resolveIdentifier,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
    this.canEditEntry,
    this.canDeleteEntry,
    this.cardSizeOption = CardSizeOption.normal,
    this.enableReorder = true,
  });

  final List<Map<String, dynamic>> entries;
  final String? Function(Map<String, dynamic> entry, List<String> possibleKeys)
  resolveField;
  final int? Function(Map<String, dynamic> entry) resolveIdentifier;
  final Future<void> Function(Map<String, dynamic> entry) onEdit;
  final Future<void> Function(Map<String, dynamic> entry) onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;
  final bool Function(Map<String, dynamic> entry)? canEditEntry;
  final bool Function(Map<String, dynamic> entry)? canDeleteEntry;
  final CardSizeOption cardSizeOption;
  final bool enableReorder;

  @override
  State<PasswordHolderList> createState() => _PasswordHolderListState();
}

class _PasswordHolderListState extends State<PasswordHolderList> {
  Map<String, dynamic>? _expandedEntry;
  String? _copiedFieldKey;
  Timer? _copyFeedbackTimer;

  @override
  void didUpdateWidget(covariant PasswordHolderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_expandedEntry != null && !widget.entries.contains(_expandedEntry)) {
      _expandedEntry = null;
    }
  }

  @override
  void dispose() {
    _copyFeedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.enableReorder) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: widget.entries.length,
        itemBuilder: (context, index) {
          final item = widget.entries[index];
          final identifier = widget.resolveIdentifier(item);
          final key = ValueKey(
            identifier ?? '${item.hashCode}-$index-${widget.hashCode}',
          );
          return KeyedSubtree(
            key: key,
            child: _buildCard(context, theme, item, index),
          );
        },
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      itemCount: widget.entries.length,
      onReorder: widget.onReorder,
      itemBuilder: (context, index) {
        final item = widget.entries[index];
        final identifier = widget.resolveIdentifier(item);
        final key = ValueKey(
          identifier ?? '${item.hashCode}-$index-${widget.hashCode}',
        );
        return KeyedSubtree(
          key: key,
          child: _buildCard(context, theme, item, index),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> item,
    int index,
  ) {
    final bool isExpanded = identical(_expandedEntry, item);
    final bool canEdit = widget.canEditEntry?.call(item) ?? true;
    final bool canDelete = widget.canDeleteEntry?.call(item) ?? true;
    final double scale = widget.cardSizeOption.scale;

    final name = widget.resolveField(item, const [
      'name',
      'holder_title',
      'holderTitle',
      'holder_name',
      'holderName',
      'title',
    ]);
    final email = widget.resolveField(item, const [
      'email',
      'holder_email',
      'holderEmail',
      'mail',
      'username',
    ]);
    final password = widget.resolveField(item, const [
      'password',
      'holder_password',
      'holderPassword',
      'secret',
    ]);
    final assignedTo = widget.resolveField(item, const [
      'ownerName',
      'user_name',
      'owner_name',
      'assigned_to',
    ])?.trim();
    final title = (name != null && name.isNotEmpty)
        ? name
        : (email != null && email.isNotEmpty ? email : 'Kayıt ${index + 1}');

    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isExpanded
        ? (isDark
              ? const Color(0x4D0061FE) // rgba(0, 97, 254, 0.3)
              : const Color(0x4D0061FE))
        : (isDark
              ? const Color(0x1AFFFFFF) // rgba(255, 255, 255, 0.1)
              : const Color(0x1A000000)); // rgba(0, 0, 0, 0.1)

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        vertical: (isExpanded ? 16 : 10) * scale,
        horizontal: (isExpanded ? 18 : 12) * scale,
      ),
      margin: EdgeInsets.only(bottom: 16 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((isExpanded ? 14 : 12) * scale),
        color: isDark
            ? const Color(0xFF1E1E1E) // darkCardBackground
            : const Color(0xFFF5F5F5), // lightCardBackground
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: isDark
                      ? const Color(0x330061FE) // rgba(0, 97, 254, 0.2)
                      : const Color(0x330061FE),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(isExpanded ? 14 : 10),
            onTap: () {
              setState(() {
                _expandedEntry = isExpanded ? null : item;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  widget.enableReorder
                      ? ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_handle,
                            color: theme.iconTheme.color?.withOpacity(0.5),
                          ),
                        )
                      : Icon(
                          Icons.drag_indicator,
                          color: theme.iconTheme.color?.withOpacity(0.3),
                        ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize:
                            ((theme.textTheme.titleMedium?.fontSize ?? 20) +
                                (isExpanded ? 2 : 0)) *
                            scale,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: child.key == const ValueKey('actions')
                          ? Tween<double>(begin: 0.75, end: 1.0).animate(anim)
                          : Tween<double>(begin: 1.0, end: 0.75).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: isExpanded && (canEdit || canDelete)
                        ? Row(
                            key: const ValueKey('actions'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (canEdit)
                                IconButton(
                                  tooltip: 'Düzenle',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => widget.onEdit(item),
                                ),
                              if (canDelete)
                                IconButton(
                                  tooltip: 'Sil',
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: theme.colorScheme.error,
                                  ),
                                  onPressed: () => widget.onDelete(item),
                                ),
                            ],
                          )
                        : Icon(
                            Icons.expand_more,
                            key: const ValueKey('collapsed'),
                          ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                SizedBox(height: 10 * scale),
                if (assignedTo != null && assignedTo.isNotEmpty)
                  _buildFieldRow(
                    theme: theme,
                    label: 'Atanan',
                    value: assignedTo,
                    fieldKey: 'assigned-$index',
                    enableCopy: false,
                    scale: scale,
                  ),
                _buildFieldRow(
                  theme: theme,
                  label: 'E-posta',
                  value: email ?? '',
                  fieldKey: 'email-$index',
                  enableCopy: true,
                  scale: scale,
                ),
                _buildFieldRow(
                  theme: theme,
                  label: 'Şifre',
                  value: password ?? '',
                  fieldKey: 'password-$index',
                  enableCopy: true,
                  scale: scale,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required ThemeData theme,
    required String label,
    required String value,
    required String fieldKey,
    bool enableCopy = true,
    double scale = 1.0,
  }) {
    final bool isCopied = _copiedFieldKey == fieldKey;
    final Color highlightColor = theme.colorScheme.primary.withOpacity(
      isCopied ? 0.12 : 0.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          vertical: 5 * scale,
          horizontal: 6 * scale,
        ),
        decoration: BoxDecoration(
          color: highlightColor,
          borderRadius: BorderRadius.circular(6 * scale),
        ),
        child: enableCopy
            ? InkWell(
                borderRadius: BorderRadius.circular(6 * scale),
                onTap: value.isEmpty ? null : () => _copyField(value, fieldKey),
                child: Row(
                  children: [
                    SizedBox(
                      width: 78 * scale,
                      child: Text(
                        '$label:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 15 * scale,
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: BoxConstraints(
                        minHeight: 32 * scale,
                        minWidth: 32 * scale,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Kopyala',
                      icon: Icon(
                        isCopied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 18 * scale,
                        color: isCopied
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color,
                      ),
                      onPressed: value.isEmpty
                          ? null
                          : () => _copyField(value, fieldKey),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  SizedBox(
                    width: 78 * scale,
                    child: Text(
                      '$label:',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 15 * scale,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _copyField(String value, String fieldKey) async {
    if (value.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value));
    _copyFeedbackTimer?.cancel();

    setState(() {
      _copiedFieldKey = fieldKey;
    });

    _copyFeedbackTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && _copiedFieldKey == fieldKey) {
        setState(() {
          _copiedFieldKey = null;
        });
      }
    });
  }
}
