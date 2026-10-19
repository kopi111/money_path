import 'package:flutter/material.dart';

import '../../domain/goals/goal_standing.dart';
import '../../domain/money/money_formatter.dart';
import 'dates.dart';

/// How a status rule is drawn, so status never depends on colour alone.
enum RuleForm { solid, dashed, double }

/// The words, icon and rule form for a goal's standing.
class StandingWords {
  const StandingWords({
    required this.headline,
    required this.detail,
    required this.icon,
    required this.ruleForm,
  });

  factory StandingWords.of(GoalStanding standing, MoneyFormatter money) => switch (standing) {
        AheadOfPlan(:final ahead) => StandingWords(
            headline: 'On track',
            detail: ahead.isZero ? 'Right on plan' : '${money.formatShort(ahead)} ahead',
            icon: Icons.check_circle,
            ruleForm: RuleForm.solid,
          ),
        CurrentPeriodDue(:final due, :final dueBy) => StandingWords(
            headline: 'On track',
            detail: '${money.formatShort(due)} due by ${Dates.dayMonth(dueBy)}',
            icon: Icons.check_circle_outline,
            ruleForm: RuleForm.solid,
          ),
        BehindPlan(:final behind, :final isSlight) => StandingWords(
            headline: isSlight ? 'Slightly behind' : 'Behind',
            detail: '${money.formatShort(behind)} behind',
            icon: isSlight ? Icons.error_outline : Icons.report,
            ruleForm: isSlight ? RuleForm.dashed : RuleForm.double,
          ),
        PastEndDate(:final stillNeeded) => StandingWords(
            headline: 'Past end date',
            detail: '${money.formatShort(stillNeeded)} still needed',
            icon: Icons.report,
            ruleForm: RuleForm.double,
          ),
        TargetReached() => const StandingWords(
            headline: 'Reached',
            detail: 'Target reached',
            icon: Icons.flag,
            ruleForm: RuleForm.solid,
          ),
        NotStartedYet(:final startsOn) => StandingWords(
            headline: 'Not started',
            detail: 'Starts ${Dates.dayMonth(startsOn)}',
            icon: Icons.schedule,
            ruleForm: RuleForm.dashed,
          ),
        PausedGoal() => const StandingWords(
            headline: 'Paused',
            detail: 'No deposits due',
            icon: Icons.pause_circle_outline,
            ruleForm: RuleForm.dashed,
          ),
      };

  final String headline;
  final String detail;
  final IconData icon;
  final RuleForm ruleForm;
}
