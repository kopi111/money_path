# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter (Material 3), Android first; iOS later from the same codebase with the same design.
Local SQLite via drift, encrypted with SQLCipher. No backend.

## Users

One person: the owner (kopi), in Jamaica, tracking his own money on his own phone.
He logs expenses as they happen (at the shop counter, after paying a bill), checks
whether his savings goals are on track, and sets up each month's budget on payday.
Sideloaded APK; no store listing and no onboarding for strangers.

## Product Purpose

Make it obvious, at a glance, whether each savings goal is on track and how much
of this month's money is left, and make logging money in or out take three taps
or fewer. Success: he keeps logging every expense because it is faster than not
logging, and he always knows how far ahead or behind each goal is in dollars.

## Positioning

A private, manual, offline ledger that answers one question per goal: "am I ahead
or behind, by how much, and what do I save per period to still make it?" It
shows the variance in dollars, not just a progress bar, and it ties savings
contributions into the monthly budget so the two views never disagree.

## Operating Context

- Payday ritual: enter the month's income (one or more sources), recurring bills
  post automatically (rent, light, water, internet, phone).
- Daily: quick-add an expense one-handed, often standing, often in bright daylight.
- Weekly / fortnightly / monthly: make a goal deposit when the reminder fires.
- Month end: read the summary, roll leftover money into next month or a goal.
- Amounts are Jamaican dollars by default (JMD, "$"); grocery limits run to five
  figures (e.g. $15,000/month), so numbers are wide.

## Capabilities and Constraints

- Savings goals: name, target, start and end date, contribution frequency
  (weekly, fortnightly, monthly); deposits and withdrawals; pause, archive, complete.
- On-track: expected = required per period × periods elapsed; variance = actual − expected;
  green (on track/ahead), amber (behind within a user threshold), red (behind);
  catch-up amount per period; projected finish from the average rate.
- Monthly budget: income sources, expenses by category, category limits with
  80% / 100% warnings, recurring bills with due-date reminders; savings deposits
  count as money out of the month.
- Dashboard, reports (category breakdown, month-to-month, actual vs expected line),
  month-end summary, rollover.
- Reminders, emergency-fund template, quick add, receipt photo, search/filter,
  CSV/PDF export, currency setting (default JMD).
- Money is stored as integer cents; no floating point anywhere in money math.
- Fully offline. Data stays on the device; cloud backup is not built (optional later).
- PIN or biometric lock, encrypted storage, auto-lock after inactivity.
- Calculation logic lives outside the UI and is unit tested.
- Data model uses UUIDs and timestamps so sync or a shared household budget can be
  added later.

## Evidence on Hand

No real transaction data. Any sample data shown must be labelled demo data.

## Product Principles

1. Dollars over percentages: every status says how many dollars ahead or behind.
2. Logging is faster than forgetting: the add-expense path is always within reach.
3. The two views agree: a goal deposit is a budget outflow, every time.
4. Private by default: nothing leaves the phone unless he exports it.
5. Exact or nothing: cents are integers; a displayed total always equals the sum of its rows.

## Accessibility & Inclusion

Large readable numbers, one-handed use, strong text/background contrast, follows the
system font size, works with TalkBack. Status never relies on colour alone
(green/amber/red always paired with a word and an icon).
