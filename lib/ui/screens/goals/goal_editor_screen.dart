import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/repositories/goal_repository.dart';
import '../../../domain/calendar/calendar_date.dart';
import '../../../domain/calendar/year_month.dart';
import '../../../domain/goals/contribution_frequency.dart';
import '../../../domain/goals/emergency_fund.dart';
import '../../../domain/goals/goal.dart';
import '../../../domain/goals/savings_schedule.dart';
import '../../format/dates.dart';
import '../../theme/book_palette.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/money_field.dart';
import '../../widgets/ruled_page.dart';

enum _Duration {
  threeMonths('3 months', 3),
  sixMonths('6 months', 6),
  oneYear('1 year', 12),
  twoYears('2 years', 24),
  custom('Pick a date', 0);

  const _Duration(this.label, this.months);

  final String label;
  final int months;
}

class GoalEditorScreen extends ConsumerStatefulWidget {
  const GoalEditorScreen({super.key, this.existing, this.emergencyFund = false});

  static Route<void> route({Goal? existing, bool emergencyFund = false}) => MaterialPageRoute(
        builder: (_) => GoalEditorScreen(existing: existing, emergencyFund: emergencyFund),
      );

  final Goal? existing;
  final bool emergencyFund;

  @override
  ConsumerState<GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends ConsumerState<GoalEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  late CalendarDate _start;
  late CalendarDate _end;
  _Duration _duration = _Duration.oneYear;
  ContributionFrequency _frequency = ContributionFrequency.monthly;
  String _emergencyNote = '';

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _start = ref.read(todayProvider);
    _end = _endAfter(_Duration.oneYear);
    final existing = widget.existing;
    if (existing != null) _fillFrom(existing);
    if (widget.emergencyFund) _prepareEmergencyFund();
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  void _fillFrom(Goal goal) {
    final money = ref.read(moneyFormatterProvider);
    _name.text = goal.name;
    _target.text = money.formatForEditing(goal.schedule.target);
    _start = goal.schedule.start;
    _end = goal.schedule.end;
    _frequency = goal.schedule.frequency;
    _duration = _Duration.custom;
  }

  Future<void> _prepareEmergencyFund() async {
    _name.text = 'Emergency fund';
    const template = EmergencyFundTemplate();
    final spending = await ref
        .read(budgetRepositoryProvider)
        .spendingInMonthsBefore(YearMonth.of(_start), template.monthsToAverage);
    if (!mounted) return;
    final money = ref.read(moneyFormatterProvider);
    setState(() {
      switch (template.suggest(spending)) {
        case SuggestedTarget(:final target, :final averageMonthlySpending, :final monthsAveraged):
          _target.text = money.formatForEditing(target);
          _emergencyNote = 'Three months of your average spending: ${money.formatShort(averageMonthlySpending)} '
              'a month over the last $monthsAveraged ${monthsAveraged == 1 ? 'month' : 'months'}.';
        case NoSpendingHistory():
          _emergencyNote = 'Once you have a full month of spending written down, this can suggest '
              'three months of it. For now, type a target.';
      }
    });
  }

  CalendarDate _endAfter(_Duration duration) => _start.addMonths(duration.months).addDays(-1);

  Future<void> _chooseDuration(_Duration duration) async {
    if (duration == _Duration.custom) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _end.toLocalDateTime(),
        firstDate: _start.addDays(7).toLocalDateTime(),
        lastDate: _start.addMonths(12 * 30).toLocalDateTime(),
        helpText: 'Finish by',
      );
      if (picked == null) return;
      setState(() {
        _duration = duration;
        _end = CalendarDate.fromDateTime(picked);
      });
      return;
    }
    setState(() {
      _duration = duration;
      _end = _endAfter(duration);
    });
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start.toLocalDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Start saving on',
    );
    if (picked == null) return;
    setState(() {
      _start = CalendarDate.fromDateTime(picked);
      if (_duration != _Duration.custom) _end = _endAfter(_duration);
    });
  }

  SavingsSchedule? _previewSchedule() {
    final target = MoneyField.read(_target);
    if (!target.isPositive || !_end.isAfter(_start)) return null;
    return SavingsSchedule(target: target, start: _start, end: _end, frequency: _frequency);
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (!_end.isAfter(_start)) return;
    final draft = GoalDraft(
      name: _name.text.trim(),
      target: MoneyField.read(_target),
      start: _start,
      end: _end,
      frequency: _frequency,
      kind: widget.emergencyFund ? GoalKind.emergencyFund : GoalKind.regular,
    );
    final repository = ref.read(goalRepositoryProvider);
    final existing = widget.existing;
    if (existing == null) {
      await repository.create(draft);
    } else {
      await repository.update(existing.id, draft);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final book = context.book;
    final preview = _previewSchedule();
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Change goal' : widget.emergencyFund ? 'Emergency fund' : 'New goal')),
      body: RuledPage(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: RuledPage.writingInset.copyWith(top: 8),
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'What are you saving for?', hintText: 'Car fund'),
                  style: text.titleLarge,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => (value ?? '').trim().isEmpty ? 'Give the goal a name' : null,
                ),
              ),
              Padding(
                padding: RuledPage.writingInset.copyWith(top: 8),
                child: MoneyField(
                  controller: _target,
                  label: 'Target',
                  helper: _emergencyNote.isEmpty ? null : _emergencyNote,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const PageHeading('When'),
              LedgerRow(
                title: 'Start saving',
                subtitle: Dates.dayMonthYear(_start),
                amount: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickStart,
              ),
              Padding(
                padding: RuledPage.writingInset.copyWith(top: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final duration in _Duration.values)
                      ChoiceChip(
                        label: Text(duration.label),
                        selected: _duration == duration,
                        onSelected: (_) => _chooseDuration(duration),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: RuledPage.writingInset.copyWith(top: 12),
                child: Text('Finish by ${Dates.dayMonthYear(_end)}', style: text.titleMedium),
              ),
              const PageHeading('How often will you put money in?'),
              Padding(
                padding: RuledPage.writingInset,
                child: SegmentedButton<ContributionFrequency>(
                  segments: [
                    for (final frequency in ContributionFrequency.values)
                      ButtonSegment(value: frequency, label: Text(frequency.label)),
                  ],
                  selected: {_frequency},
                  onSelectionChanged: (choice) => setState(() => _frequency = choice.first),
                  showSelectedIcon: false,
                ),
              ),
              const PageHeading('Your plan'),
              if (preview == null)
                const PageText('Type a target to see what to save each week and month.')
              else ...[
                LedgerRow(
                  title: 'Every ${preview.frequency.periodName}',
                  subtitle: '${preview.totalPeriods} ${preview.frequency.periodName}s',
                  amount: AmountText(preview.requiredPerPeriod, size: AmountSize.large),
                ),
                if (preview.frequency != ContributionFrequency.weekly)
                  LedgerRow(title: 'Per week', amount: AmountText(preview.requiredPerWeek)),
                if (preview.frequency != ContributionFrequency.monthly)
                  LedgerRow(title: 'Per month', amount: AmountText(preview.requiredPerMonth)),
              ],
              Padding(
                padding: RuledPage.writingInset.copyWith(top: 24),
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: Text(_isEditing ? 'Save changes' : 'Start this goal'),
                ),
              ),
              if (!_end.isAfter(_start))
                PageText('The finish date must be after the start.', style: text.bodyMedium?.copyWith(color: book.behind)),
            ],
          ),
        ),
      ),
    );
  }
}

