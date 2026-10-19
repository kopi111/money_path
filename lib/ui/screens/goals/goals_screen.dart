import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/goals/goal.dart';
import '../../../domain/money/money.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/empty_note.dart';
import '../../widgets/goal_cover.dart';
import '../../widgets/ruled_page.dart';
import 'goal_detail_screen.dart';
import 'goal_editor_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(goalViewsProvider).valueOrNull ?? const <GoalView>[];
    final open = views.where((view) => view.record.goal.isOpen).toList();
    final closed = views.where((view) => !view.record.goal.isOpen).toList();
    final totalSaved = Money.sum(views.map((view) => view.record.saved));
    return RuledPage(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text('Goals')),
          SliverList.list(children: [
            Padding(
              padding: RuledPage.writingInset.copyWith(top: 12, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saved across all goals', style: Theme.of(context).textTheme.titleMedium),
                  FittedAmount(child: AmountText(totalSaved, size: AmountSize.large)),
                ],
              ),
            ),
            if (open.isEmpty) ...[
              const SizedBox(height: 12),
              EmptyNote(
                message: 'Pick something to save for, a target and a finish date. '
                    'Money Path works out what to put away each week or month.',
                actionLabel: 'Start a goal',
                onAction: () => Navigator.of(context).push(GoalEditorScreen.route()),
              ),
              EmptyNote(
                message: 'Or begin with an emergency fund: three months of your usual spending.',
                actionLabel: 'Emergency fund',
                onAction: () => Navigator.of(context).push(GoalEditorScreen.route(emergencyFund: true)),
              ),
            ],
            for (final view in open) _cover(context, view),
            if (closed.isNotEmpty) const PageHeading('Finished and archived'),
            for (final view in closed) _cover(context, view),
            const SizedBox(height: 96),
          ]),
        ],
      ),
    );
  }

  Widget _cover(BuildContext context, GoalView view) => Padding(
        padding: RuledPage.writingInset.copyWith(top: 12),
        child: Opacity(
          opacity: view.record.goal.state == GoalState.archived ? 0.7 : 1,
          child: GoalCover(
            view,
            onTap: () => Navigator.of(context).push(GoalDetailScreen.route(view.record.goal.id)),
          ),
        ),
      );
}
