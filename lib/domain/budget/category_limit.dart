import '../money/money.dart';

enum LimitLevel {
  /// Under 80% of the limit.
  comfortable,

  /// 80% or more.
  nearing,

  /// 100% or more.
  reached,
}

/// How one category's spending compares with its monthly limit.
class CategoryLimitCheck {
  CategoryLimitCheck({required this.spent, required this.limit}) {
    if (!limit.isPositive) {
      throw ArgumentError.value(limit, 'limit', 'must be more than zero');
    }
  }

  static const nearingPercent = 80;
  static const reachedPercent = 100;

  final Money spent;
  final Money limit;

  int get percentUsed => spent.isPositive ? spent.percentOf(limit) : 0;

  Money get leftUnderLimit => limit - spent;

  LimitLevel get level {
    if (spent >= limit) return LimitLevel.reached;
    if (spent.cents * 100 >= limit.cents * nearingPercent) return LimitLevel.nearing;
    return LimitLevel.comfortable;
  }
}
