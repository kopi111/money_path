import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_services.dart';
import '../../../app/providers.dart';
import '../../../services/backup_service.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/ruled_page.dart';

class BackupsSection extends ConsumerStatefulWidget {
  const BackupsSection({super.key});

  @override
  ConsumerState<BackupsSection> createState() => _BackupsSectionState();
}

class _BackupsSectionState extends ConsumerState<BackupsSection> {
  static final _stamp = DateFormat('d MMM yyyy, h:mm a');

  BackupService get _backups => ref.read(appServicesProvider).session.backups;

  Future<void> _backUpNow() async {
    await _backups.backUpNow(ref.read(databaseProvider));
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backed up')));
  }

  Future<void> _restore(BackupFile backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go back to this backup?'),
        content: Text('Everything changes back to how it was on ${_stamp.format(backup.takenAt)}. '
            'A backup of how things are now is taken first, so you can undo this.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final restore = ref.read(appServicesProvider).restore;
    Navigator.of(context).popUntil((route) => route.isFirst);
    try {
      await restore(backup);
      messenger.showSnackBar(const SnackBar(content: Text('Backup restored')));
    } on StateError catch (problem) {
      messenger.showSnackBar(SnackBar(content: Text(problem.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final backups = _backups.list();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageText('A copy is taken automatically once a day and the last 7 are kept. '
            'Copies are encrypted and can only be opened on this phone.'),
        LedgerRow(title: 'Back up now', amount: const Icon(Icons.backup_outlined), onTap: _backUpNow),
        for (final backup in backups)
          LedgerRow(
            title: _stamp.format(backup.takenAt),
            subtitle: 'Tap to restore',
            amount: const Icon(Icons.restore),
            onTap: () => _restore(backup),
          ),
        if (backups.isEmpty) const PageText('No backups yet.'),
        Padding(padding: RuledPage.writingInset, child: const SizedBox(height: 8)),
      ],
    );
  }
}
