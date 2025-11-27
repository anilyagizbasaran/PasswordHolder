import 'package:flutter/material.dart';

import '../../utils/card_size_option.dart';
import '../../widgets/password_holder_list.dart';

class PasswordHoldersTab extends StatelessWidget {
  const PasswordHoldersTab({
    super.key,
    required this.loading,
    required this.error,
    required this.holders,
    required this.onRefresh,
    required this.onResolveField,
    required this.onResolveIdentifier,
    required this.onEditHolder,
    required this.onDeleteHolder,
    required this.onReorder,
    required this.cardSizeOption,
    this.hasAnyHolder = false,
    this.isSearching = false,
    this.allowReorder = true,
  });

  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> holders;
  final Future<void> Function() onRefresh;
  final String? Function(Map<String, dynamic> entry, List<String> keys)
  onResolveField;
  final int? Function(Map<String, dynamic> entry) onResolveIdentifier;
  final Future<void> Function(Map<String, dynamic> entry) onEditHolder;
  final Future<void> Function(Map<String, dynamic> entry) onDeleteHolder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final CardSizeOption cardSizeOption;
  final bool hasAnyHolder;
  final bool isSearching;
  final bool allowReorder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Builder(
        builder: (context) {
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error != null) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onRefresh,
                  child: const Text('Tekrar dene'),
                ),
              ],
            );
          }
          if (holders.isEmpty) {
            if (isSearching && hasAnyHolder) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  Center(child: Text('Aramanıza uygun kart bulunamadı.')),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                Center(child: Text('Kayıtlı şifre bulunamadı.')),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Şifre Kayıtları',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              PasswordHolderList(
                entries: holders,
                resolveField: onResolveField,
                resolveIdentifier: onResolveIdentifier,
                onEdit: onEditHolder,
                onDelete: onDeleteHolder,
                onReorder: onReorder,
                cardSizeOption: cardSizeOption,
                enableReorder: allowReorder,
              ),
            ],
          );
        },
      ),
    );
  }
}
