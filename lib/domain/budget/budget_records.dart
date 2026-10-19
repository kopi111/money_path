import '../calendar/calendar_date.dart';
import '../calendar/year_month.dart';
import '../money/money.dart';

enum IncomeKind { earned, carriedForward }

enum LeftoverDestination { nextMonth, goal }

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.monthlyLimit,
  });

  final String id;
  final String name;
  final String iconName;
  final MonthlyLimit monthlyLimit;
}

/// A category's optional spending cap for a month.
sealed class MonthlyLimit {
  const MonthlyLimit();
}

class LimitOf extends MonthlyLimit {
  const LimitOf(this.amount);

  final Money amount;
}

class NoLimit extends MonthlyLimit {
  const NoLimit();
}

class Income {
  const Income({
    required this.id,
    required this.month,
    required this.source,
    required this.amount,
    required this.receivedOn,
    required this.kind,
  });

  final String id;
  final YearMonth month;
  final String source;
  final Money amount;
  final CalendarDate receivedOn;
  final IncomeKind kind;
}

class Expense {
  const Expense({
    required this.id,
    required this.date,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.receipt,
    required this.isFromBill,
  });

  final String id;
  final CalendarDate date;
  final Money amount;
  final String categoryId;
  final String note;
  final Receipt receipt;
  final bool isFromBill;
}

sealed class Receipt {
  const Receipt();
}

class ReceiptPhoto extends Receipt {
  const ReceiptPhoto(this.path);

  final String path;
}

class NoReceipt extends Receipt {
  const NoReceipt();
}

class MonthClosing {
  const MonthClosing({
    required this.month,
    required this.leftover,
    required this.destination,
    required this.goalName,
  });

  final YearMonth month;
  final Money leftover;
  final LeftoverDestination destination;

  /// Empty unless the leftover went into a goal.
  final String goalName;
}

/// Whether a month's leftover has been moved on yet.
sealed class MonthEnd {
  const MonthEnd();
}

class LeftoverMoved extends MonthEnd {
  const LeftoverMoved(this.closing);

  final MonthClosing closing;
}

class MonthStillOpen extends MonthEnd {
  const MonthStillOpen();
}
