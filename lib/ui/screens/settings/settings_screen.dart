import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_services.dart';
import '../../../app/providers.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../domain/money/currency.dart';
import '../../../services/demo_data.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/ruled_page.dart';
import 'backups_section.dart';
import 'categories_screen.dart';
import 'change_pin_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const SettingsScreen());

  static const _autoLockChoices = {30: '30 seconds', 60: '1 minute', 300: '5 minutes', 900: '15 minutes'};
  static const _billDayChoices = [1, 2, 3, 5, 7];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final repository = ref.read(settingsRepositoryProvider);
    final services = ref.read(appServicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: RuledPage(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const PageHeading('Money'),
            LedgerRow(
              title: 'Currency',
              subtitle: settings.currency.name,
              amount: Text(settings.currency.symbol, style: Theme.of(context).textTheme.titleMedium),
              onTap: () => _chooseCurrency(context, repository, settings.currency),
            ),
            LedgerRow(
              title: 'When a goal counts as slightly behind',
              subtitle: 'Up to ${settings.amberThresholdPercent}% of one period\'s amount shows amber. More shows red.',
              amount: const SizedBox.shrink(),
            ),
            Padding(
              padding: RuledPage.writingInset,
              child: Slider(
                value: settings.amberThresholdPercent.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                label: '${settings.amberThresholdPercent}%',
                onChanged: (value) => repository.save(SettingKey.amberThresholdPercent, value.round()),
              ),
            ),
            LedgerRow(
              title: 'Categories',
              subtitle: 'Add your own categories',
              amount: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(CategoriesScreen.route()),
            ),
            const PageHeading('Lock'),
            FutureBuilder<bool>(
              future: services.lock.deviceSupportsBiometrics(),
              builder: (context, supported) => SwitchListTile(
                contentPadding: RuledPage.writingInset,
                title: const Text('Unlock with fingerprint or face'),
                subtitle: Text(supported.data ?? false
                    ? 'Your PIN still works.'
                    : 'This phone has no fingerprint or face unlock set up.'),
                value: settings.biometricsOn && (supported.data ?? false),
                onChanged: supported.data ?? false ? (on) => repository.save(SettingKey.biometricsOn, on) : null,
              ),
            ),
            LedgerRow(
              title: 'Lock after',
              subtitle: _autoLockChoices[settings.autoLockSeconds] ?? '${settings.autoLockSeconds} seconds',
              amount: const Icon(Icons.chevron_right),
              onTap: () => _chooseAutoLock(context, repository),
            ),
            LedgerRow(
              title: 'Change PIN',
              amount: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(ChangePinScreen.route()),
            ),
            LedgerRow(
              title: 'Lock now',
              amount: const Icon(Icons.lock_outline),
              onTap: services.lock.lock,
            ),
            const PageHeading('Reminders'),
            SwitchListTile(
              contentPadding: RuledPage.writingInset,
              title: const Text('Deposit, bill and behind-goal reminders'),
              value: settings.remindersOn,
              onChanged: (on) async {
                await repository.save(SettingKey.remindersOn, on);
                if (on) await services.notifications.askPermission();
                await ref.read(dailyUpkeepProvider).refreshReminders(ref.read(todayProvider));
              },
            ),
            LedgerRow(
              title: 'Remind me about bills',
              subtitle: '${settings.billReminderDays} ${settings.billReminderDays == 1 ? 'day' : 'days'} before they are due',
              amount: const Icon(Icons.chevron_right),
              onTap: () => _chooseBillDays(context, ref, repository),
            ),
            const PageHeading('Backups'),
            const BackupsSection(),
            if (kDebugMode) ...[
              const PageHeading('Testing'),
              LedgerRow(
                title: 'Fill with demo data',
                subtitle: 'Debug builds only. Every record is marked demo.',
                amount: const Icon(Icons.science_outlined),
                onTap: () => DemoData(
                  budget: ref.read(budgetRepositoryProvider),
                  goals: ref.read(goalRepositoryProvider),
                  bills: ref.read(billRepositoryProvider),
                  categories: ref.read(categoryRepositoryProvider),
                ).fill(ref.read(todayProvider)).then((_) => ref.read(dailyUpkeepProvider).run(ref.read(todayProvider))),
              ),
            ],
            const PageHeading('Privacy'),
            const PageText(
              'Everything stays on this phone. The database is encrypted, and its key is kept in the '
              'phone\'s secure keystore. Nothing is sent anywhere unless you export it yourself.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseCurrency(BuildContext context, SettingsRepository repository, Currency current) async {
    final chosen = await showDialog<Currency>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Currency'),
        children: [
          RadioGroup<Currency>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              children: [
                for (final currency in Currency.supported)
                  RadioListTile<Currency>(value: currency, title: Text('${currency.name} (${currency.symbol})')),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null) await repository.save(SettingKey.currency, chosen.code);
  }

  Future<void> _chooseAutoLock(BuildContext context, SettingsRepository repository) async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Lock after'),
        children: [
          for (final choice in _autoLockChoices.entries)
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              onPressed: () => Navigator.pop(context, choice.key),
              child: Text(choice.value),
            ),
        ],
      ),
    );
    if (chosen != null) await repository.save(SettingKey.autoLockSeconds, chosen);
  }

  Future<void> _chooseBillDays(BuildContext context, WidgetRef ref, SettingsRepository repository) async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Days before a bill is due'),
        children: [
          for (final days in _billDayChoices)
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              onPressed: () => Navigator.pop(context, days),
              child: Text('$days ${days == 1 ? 'day' : 'days'}'),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    await repository.save(SettingKey.billReminderDays, chosen);
    await ref.read(dailyUpkeepProvider).refreshReminders(ref.read(todayProvider));
  }
}
