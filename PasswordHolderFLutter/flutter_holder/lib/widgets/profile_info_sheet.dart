import 'package:flutter/material.dart';

class ProfileInfoSheet extends StatelessWidget {
  const ProfileInfoSheet({
    super.key,
    required this.profileFuture,
    required this.email,
    this.department,
  });

  final Future<Map<String, dynamic>> profileFuture;
  final String email;
  final String? department;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 360,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<Map<String, dynamic>>(
          future: profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return _buildError(theme, snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return _buildError(theme, 'Profil bilgileri alınamadı.');
            }
            final name = _resolveName(snapshot.data!);
            return _buildCard(theme, name);
          },
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.errorContainer,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ThemeData theme, String name) {
    final initials = _initialsFromName(name);
    final departmentLabel = department?.trim().isEmpty ?? true
        ? null
        : department!.trim();
    return SizedBox(
      width: 312,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              initials,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          if (departmentLabel != null) ...[
            const SizedBox(height: 16),
            Chip(
              avatar: const Icon(Icons.apartment, size: 18),
              label: Text(
                departmentLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _resolveName(Map<String, dynamic> data) {
    const keys = [
      'name',
      'full_name',
      'fullName',
      'display_name',
      'displayName',
    ];
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'İsimsiz Kullanıcı';
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\\s+'))
        .where((segment) => segment.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final word = parts.first.trim();
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }
      return word.substring(0, 1).toUpperCase();
    }
    final first = parts.first.trim();
    final last = parts.last.trim();
    final firstInitial = first.isNotEmpty ? first[0] : '';
    final lastInitial = last.isNotEmpty ? last[0] : '';
    final combined = '$firstInitial$lastInitial';
    return combined.isEmpty ? '?' : combined.toUpperCase();
  }
}

