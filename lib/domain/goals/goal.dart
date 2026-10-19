import 'savings_schedule.dart';

enum GoalState { active, paused, archived, completed }

enum GoalKind { regular, emergencyFund }

class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.schedule,
    required this.state,
    required this.kind,
  });

  final String id;
  final String name;
  final SavingsSchedule schedule;
  final GoalState state;
  final GoalKind kind;

  bool get isOpen => state == GoalState.active || state == GoalState.paused;
}
