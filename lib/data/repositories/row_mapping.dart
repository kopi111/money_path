import '../../domain/budget/budget_records.dart';
import '../../domain/budget/recurring_bill.dart';
import '../../domain/calendar/calendar_date.dart';
import '../../domain/calendar/year_month.dart';
import '../../domain/money/money.dart';
import '../app_database.dart';

Category toCategory(CategoryRow row) => Category(
      id: row.id,
      name: row.name,
      iconName: row.iconName,
      monthlyLimit: switch (row.monthlyLimitCents) {
        final int cents => LimitOf(Money.cents(cents)),
        null => const NoLimit(),
      },
    );

Income toIncome(IncomeRow row) => Income(
      id: row.id,
      month: YearMonth.parse(row.month),
      source: row.source,
      amount: Money.cents(row.amountCents),
      receivedOn: CalendarDate.parse(row.receivedOn),
      kind: row.kind,
    );

Expense toExpense(ExpenseRow row) => Expense(
      id: row.id,
      date: CalendarDate.parse(row.date),
      amount: Money.cents(row.amountCents),
      categoryId: row.categoryId,
      note: row.note,
      receipt: switch (row.receiptPath) {
        final String path => ReceiptPhoto(path),
        null => const NoReceipt(),
      },
      isFromBill: row.recurringBillId != null,
    );

RecurringBill toBill(RecurringBillRow row) => RecurringBill(
      id: row.id,
      name: row.name,
      amount: Money.cents(row.amountCents),
      categoryId: row.categoryId,
      dueDay: row.dueDay,
    );
