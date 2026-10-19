---
name: Money Path
description: A household money book for Android, kept the way a Jamaican exercise book keeps it.
colors:
  paper: "#FBFCFA"
  rule: "#C7D6EB"
  margin-red: "#D9483B"
  ballpoint-ink: "#15245C"
  ink-soft: "#475377"
  label-plate: "#FFFFFF"
  cover-blue: "#1D4FB5"
  cover-purple: "#6A3AA8"
  cover-teal: "#0F6E7A"
  cover-plum: "#8A2C6B"
  cover-indigo: "#3B4A9C"
  cover-slate: "#455A64"
  on-cover: "#FFFFFF"
  status-ahead: "#17703F"
  status-slipping: "#8F5B00"
  status-behind: "#B3261E"
  night-paper: "#10172A"
  night-rule: "#34436A"
  night-margin-red: "#E0685C"
  night-ink: "#E9EDF8"
  night-ink-soft: "#AEB7D0"
  night-label-plate: "#1A2440"
  night-cover-blue: "#2F63D0"
  night-cover-purple: "#7D4DBD"
  night-cover-teal: "#13717F"
  night-cover-plum: "#9A3A7C"
  night-cover-indigo: "#4A5BB5"
  night-cover-slate: "#52666F"
  night-status-ahead: "#6FD69C"
  night-status-slipping: "#F2C25B"
  night-status-behind: "#FF8F80"
typography:
  display:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "44px"
    fontWeight: 800
    lineHeight: 1.08
    fontFeature: "tnum"
  headline:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.25
  title:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.25
  title-small:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.25
  body:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.4
  body-small:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.35
  label:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.25
  amount-hero:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "44px"
    fontWeight: 800
    lineHeight: 1.08
    fontFeature: "tnum"
  amount-large:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.25
    fontFeature: "tnum"
  amount-row:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "17px"
    fontWeight: 700
    lineHeight: 1.25
    fontFeature: "tnum"
  amount-small:
    fontFamily: "Atkinson Hyperlegible Next, sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.4
    fontFeature: "tnum"
rounded:
  bar: "2px"
  cover: "6px"
  key: "8px"
  plate: "10px"
spacing:
  margin: "56px"
  writing-inset: "68px"
  gutter: "16px"
  gap: "12px"
  row-min: "64px"
  touch-tall: "56px"
components:
  button-spend:
    backgroundColor: "{colors.ballpoint-ink}"
    textColor: "{colors.paper}"
    typography: "{typography.label}"
    height: "56px"
  button-primary:
    backgroundColor: "{colors.ballpoint-ink}"
    textColor: "{colors.paper}"
    typography: "{typography.label}"
    height: "{spacing.touch-tall}"
  ledger-row:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ballpoint-ink}"
    typography: "{typography.body}"
    height: "{spacing.row-min}"
  goal-cover:
    backgroundColor: "{colors.cover-blue}"
    textColor: "{colors.on-cover}"
    rounded: "{rounded.cover}"
    padding: "16px 16px 18px"
  label-plate:
    backgroundColor: "{colors.label-plate}"
    textColor: "{colors.ballpoint-ink}"
    rounded: "{rounded.plate}"
    padding: "10px 14px"
  status-plate:
    backgroundColor: "{colors.label-plate}"
    typography: "{typography.title-small}"
    rounded: "{rounded.key}"
    padding: "8px 12px 6px 10px"
  keypad-key:
    textColor: "{colors.ballpoint-ink}"
    typography: "{typography.headline}"
    rounded: "{rounded.key}"
    height: "{spacing.touch-tall}"
  category-chip:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ballpoint-ink}"
    typography: "{typography.label}"
---

# Design System: Money Path

## Overview

**Creative North Star: "The Exercise Book"**

Money kept the way a Jamaican household always kept it: on paper, in a school exercise book. Every screen is a page with a red double margin rule down the left, dates written in that margin, words written to the right of it, and sums lined up in the right-hand column. Goals are the books themselves: solid card covers in blue, purple, teal, plum, indigo or slate, each with a white label plate filled in NAME and BY. Ink is ballpoint navy on off-white paper. There is no chrome to speak of; structure comes from rules, not boxes.

The system deliberately refuses the finance-app default of tonal Material cards, a donut chart and wallpaper-driven dynamic colour. Material 3 supplies behaviour (navigation bar, sheets, chips, buttons, snackbars); the Exercise Book supplies every colour role, the type scale and the shapes. Density is generous and one-handed: rows are at least 64px tall, primary actions are 56px tall, and the quick-add keypad sits at the bottom of the screen.

The night book is the same book with the lights off: a deep navy page, pale ink, and label plates that turn dark rather than staying white, because the night status colours are tuned light for a dark ground and would fail on white.

**Key Characteristics:**
- Red double margin rule at 56px on every ruled page; margin holds dates, the writing starts at 68px.
- Each ledger line sits on its own feint blue rule, amount right-aligned in the sum column.
- Totals close under a short double ink rule.
- Goal = solid exercise-book cover + white NAME / BY label plate; cover hue never carries status.
- Status says itself three ways: colour, icon plus word, and rule form (solid, dashed, double).
- One typeface, Atkinson Hyperlegible Next, with tabular figures on every amount.
- One extended FAB, "Spend", opens keypad-first quick add.

## Colors

Ballpoint navy on near-white paper, with a single red margin line and six solid cover hues kept strictly apart from the three status hues.

### Primary
- **Ballpoint Navy** (ballpoint-ink): all body text, headings, amounts, the FAB and filled buttons, focused input underlines, category bars and the "Saved" chart line. Mapped to Material `primary` and `onSurface`.

### Secondary
- **Margin Red** (margin-red): only the vertical margin rule (drawn at 85% opacity, 1.25px, two lines 3px apart) and the margin dates. Mapped to Material `tertiary`. It is not an error colour and never marks a problem.

### Tertiary
- **Exercise-Book Covers** (cover-blue, cover-purple, cover-teal, cover-plum, cover-indigo, cover-slate): solid fills for goals, chosen per goal by a stable hash of its id so a goal keeps its cover across launches. White text and white progress bar sit on them.

### Neutral
- **Paper** (paper): scaffold, app bar, sheets, chips and every page background.
- **Feint Rule** (rule): the rule under each ledger row, dividers, chip borders, chart gridlines, label-plate underlines, selected chip and nav indicator fill. At 35% over paper it tints the navigation bar and keypad keys.
- **Soft Ink** (ink-soft): secondary lines, subtitles, captions, row icons, the "Plan" chart line, the neutral status.
- **Label Plate** (label-plate): the white plate on covers and the status plate on covers.

### Status
- **Ahead** (status-ahead), **Slipping** (status-slipping), **Behind** (status-behind): goal standing and category limits (nearing = slipping, reached = behind). Behind is also Material `error`. Night equivalents are the `night-status-*` tokens.

### Named Rules
**The Covers Are Not Signals Rule.** Cover hues avoid green, amber and red entirely. Status colour appears only on the status line, a limit warning or an amount, never as a cover.

**The Night Plate Rule.** In the night book the label and status plates are `night-label-plate`, not white. Light-tuned status colours on a white plate would lose contrast.

**The One Red Line Rule.** Margin red belongs to the margin. Anything that is actually wrong uses status-behind.

## Typography

**Display Font:** Atkinson Hyperlegible Next (bundled, weights 400 to 800)
**Body Font:** Atkinson Hyperlegible Next
**Label/Mono Font:** none; figures use the `tnum` feature instead of a mono face.

**Character:** One legibility-first family doing every job, with weight (400 to 800) carrying hierarchy. Its distinct slashed zero and open figures read like a careful hand in a ledger.

### Hierarchy
- **Display** (800, 44px, 1.08): hero amounts only (money left this month, a goal's saved amount, the quick-add figure). displayLarge (56px) exists in the theme but is unused.
- **Headline** (700, 26px): large amounts in totals; keypad digits use headlineSmall (22px, 600).
- **Title** (700, 20px): app bar titles, page section headings, quick-add "Spent", the goal name on a label plate. titleMedium (17px, 600) for lead-in lines above hero amounts and margin dates.
- **Body** (400, 17px, 1.4): ledger row titles and empty notes; bodyMedium (15px) for plain page text; body-small (13px) for row subtitles.
- **Label** (600, 15px): buttons, chips; labelSmall (12px, 600) for margin month and the NAME / BY plate labels (tracked 0.8).

### Named Rules
**The Four Sums Rule.** Every amount prints at one of four sizes: hero (44/800), large (26/700), row (17/700), small (15/600). Pick by the job the figure does, never by the space available; a figure that does not fit shrinks to fit its column rather than wrapping or picking a new size.

**The Tabular Figures Rule.** Every amount and every display-size figure uses tabular figures so columns of money line up.

## Layout

A single column on phones. Each ruled page reserves a 56px margin on the left for dates and short notes; content starts at 68px (margin + 12px) and ends 16px from the right edge. Section headings sit 28px below the previous content and 8px above their rows. Ledger rows are full-bleed so their rule runs edge to edge through the margin. Goal covers sit inside the writing column. Hero blocks use 20px top, 12px bottom.

Primary actions in sheets and editors are full width and 56px tall (52px on goal detail). The quick-add sheet is a bottom sheet with 16px side padding, a right-aligned hero amount over a 2px ink underline, wrapping category chips (8px gaps) and a 4 by 3 keypad of 56px keys with 3px gutters.

At 600px wide and above, the bottom navigation bar becomes a navigation rail with labels, separated by a 1px divider. At 1.3 font scale the layout holds: amounts shrink to fit their column, rows grow taller, and status words wrap onto a second line inside their plate rather than truncating.

## Elevation & Depth

Flat. Surfaces are paper, and depth is expressed by rules and solid cover fills, not shadows. Surface tint is switched off on the app bar, sheets and cards. The only shadows are Material's defaults on the extended FAB and the modal sheet's scrim.

### Named Rules
**The Ruled, Not Raised Rule.** Separate things with a rule (feint for rows, ink for totals, margin red for the margin), never with a shadow or a tonal card.

## Shapes

Mostly square-edged paper with small, practical radii: 2px on progress and category bars, 6px on goal covers, 8px on keypad keys and the status plate, 10px on the label plate. Lines are the real shape language: 1px feint rules, 1.25px margin rules, 2px status rules (solid; dashed 6 on 4 off; double, two lines 4px apart), a 2px ink underline for amount entry, and underline-only text fields. Progress bars on covers are an outlined 1.5px white track filled solid white. Buttons, the FAB and chips keep Material 3's default shapes (fully rounded buttons, 16px FAB, 8px chips); bottom sheets keep the default 28px top corners.

## Components

### Buttons
- **Spend FAB:** the signature action. Extended FAB, ballpoint-navy fill, paper text, pencil icon, label "Spend" (16px, 700). Shown on Today and Month; Goals shows "New goal" in the same style; Reports has none. In the night book it inverts to pale ink with navy text.
- **Primary:** Material FilledButton in ballpoint navy, full width, 56px tall.
- **Secondary:** OutlinedButton for the lesser action beside a primary (take out of a goal, export, empty-note first steps).
- **Text:** TextButton for in-header links such as "All goals" and "Add details".

### Chips
- **Category chips:** ActionChips on paper with a feint rule border and a 20px category icon; in quick add, tapping one saves the entry.
- **Choice / filter chips:** selected fill is the feint rule colour.

### Inputs / Fields
- **Style:** underline only, soft-ink underline, soft-ink label; no filled boxes.
- **Focus:** underline turns ballpoint navy at 2px; floating label turns navy.

### Navigation
- Material NavigationBar tinted with the rule colour at 35% over paper; selected indicator is the rule colour; labels at 13px/600. Four tabs: Today, Goals, Month, Reports. Rail at 600px and wider.

### Ledger Row
The core line of the book: full-bleed, at least 64px tall, a feint rule underneath. The margin holds the day number (17px, 700, margin red) over the short month (12px, margin red). Then an optional soft-ink icon (22px), the title (body) with an optional subtitle (13px, soft ink), and the amount at row size in the sum column, 16px from the right. Only the first entry of a day carries the date.

### Total Row
Closes a summary: label at title size on the left, the amount at large size on the right, then two 1px ink lines 120px wide, 2px apart, under the figure, and a 1px ink rule under the whole row. Overspent totals turn status-behind.

### Goal Cover
A solid cover (6px radius, 16px padding) holding the white label plate (NAME: goal name at title size; BY: end date and frequency; each line underlined by a feint rule), the saved amount at hero size in white, "saved of target · %" at title-small, a 10px outlined progress bar and the status plate. The compact **cover strip** on Today keeps the cover, name and row-size amount on one line, a 6px bar and the status plate, without the label plate.

### Status Line
Icon (20px) + bold headline word + " · " + detail, all in the status colour at title-small, over a 96px status rule whose form repeats the message: solid for on track or reached, dashed for slightly behind, not started or paused, double for behind or past end date. On a cover it sits on its own plate so the colour reads against any cover.

### Money Keypad
Big-key number pad (56px keys, 8px radius, rule at 35% fill, navy digits at 22px/600), backspace as an outlined icon, selection-click haptic on every press, long-press on backspace.

### Charts
Category spending is horizontal ink bars (12px, 2px radius), largest first, each with its own icon, name, percent and small amount, so no legend is needed. The goal savings chart is a straight-segment line chart: actual saved as a 3px solid navy line with dots, the plan as a 2px dashed soft-ink line (6 on, 5 off), feint gridlines, no border.

## Do's and Don'ts

### Do:
- **Do** put every page's content inside the ruled page, starting at the 68px writing inset with dates in the 56px margin.
- **Do** end every ledger line on its own feint rule and put its amount in the right-hand sum column.
- **Do** close totals under the double ink rule.
- **Do** say status three ways at once: status colour, icon plus word, and rule form (solid, dashed, double).
- **Do** size money only from the four-step amount ramp (hero, large, row, small) with tabular figures, and let a figure shrink to fit rather than wrap.
- **Do** give each goal a cover from the six cover hues, chosen stably from its id, with a NAME / BY label plate.
- **Do** use dark label and status plates in the night book.
- **Do** keep quick add keypad-first: type the amount, tap a category, saved.

### Don't:
- **Don't** use tonal Material cards, surface tint or shadows to group content; use rules.
- **Don't** draw a donut or pie chart; spending is horizontal bars with their own labels.
- **Don't** turn on dynamic (wallpaper) colour; the palette is fixed.
- **Don't** colour a goal cover green, amber or red, or use a cover hue to signal status.
- **Don't** use margin red for errors or warnings.
- **Don't** show status by colour alone.
- **Don't** introduce a second typeface or a mono face for numbers.
