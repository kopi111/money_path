import 'app_database.dart';

/// Starting categories with fixed ids, so every install has the same ones.
List<CategoriesCompanion> seedCategories(DateTime now) {
  const starters = [
    ('00000000-0000-4000-8000-000000000001', 'Groceries', 'groceries'),
    ('00000000-0000-4000-8000-000000000002', 'Rent', 'rent'),
    ('00000000-0000-4000-8000-000000000003', 'Utilities', 'utilities'),
    ('00000000-0000-4000-8000-000000000004', 'Transport', 'transport'),
    ('00000000-0000-4000-8000-000000000005', 'Phone & internet', 'phone'),
    ('00000000-0000-4000-8000-000000000006', 'Eating out', 'eatingOut'),
    ('00000000-0000-4000-8000-000000000007', 'Health', 'health'),
    ('00000000-0000-4000-8000-000000000008', 'Household', 'household'),
    ('00000000-0000-4000-8000-000000000009', 'Personal', 'personal'),
    ('00000000-0000-4000-8000-000000000010', 'Fun', 'fun'),
    ('00000000-0000-4000-8000-000000000011', 'Other', 'other'),
  ];
  return [
    for (final (index, starter) in starters.indexed)
      CategoriesCompanion.insert(
        id: starter.$1,
        name: starter.$2,
        iconName: starter.$3,
        sortOrder: index,
        createdAt: now,
        updatedAt: now,
      ),
  ];
}
