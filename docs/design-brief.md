# Design brief

This brief describes Money Scribe for whoever designs its colours, typography and
screens. It explains what the app is for, which screens it needs, what each screen
shows, the fixed constraints, and what the design work should hand back. Every
amount and name below is invented sample data.

## 1. The app

**Money Scribe: Budget & Expense Tracker** is a personal finance tracker for one
person managing their own money. It replaces a monthly salary spreadsheet and adds
what a spreadsheet handles poorly: everyday purchases and debts.

- **Offline-first:** no account, no sign-in, no ads. All data stays on the device;
  backup is an explicit export.
- **Precise:** amounts are exact to the minor unit (kopecks, cents), and the user
  must be able to trust every number on screen.
- **Private:** an optional app lock protects the data.

The feel should be calm, clear and trustworthy, like a well-kept ledger: numbers are
the main content, decoration stays secondary.

## 2. Platforms and layout

- Android, iOS and web, built with Flutter and **Material 3**.
- Phone portrait first; tablet and web use wider layouts (for example list and detail
  side by side).
- Material 3 window size classes: compact (< 600 dp), medium (600–839 dp), expanded
  (≥ 840 dp).
- Light and dark mode, following the system setting by default.

## 3. Screens

Suggested main navigation: a bottom navigation bar on phones and a navigation rail on
wider screens, with **Overview**, **Salary**, **Transactions**, **Debts** and
**Reports**. Settings is reached from the top app bar. The designer may propose a
better structure.

### 3.1 Monthly salary calculator

The user enters one month's figures and the app calculates the pay. Each month is
saved and can be reopened from a history list.

Inputs, with sample values:

| Field | Sample |
| --- | --- |
| Base salary | 100,000 |
| Working days, 1st–15th | 10 |
| Working days in the month | 20 |
| Food allowance per day | 500 |
| Working hours in the month | 160 |
| Extra hours | 8 |
| Tax rate | 13% |

Results, with the values these inputs produce:

| Result | Sample |
| --- | --- |
| Food allowance | 10,000 |
| Extra-hours pay | 10,000 |
| Income before tax | 120,000 |
| Tax | 15,600 |
| Total after tax | 104,400 |
| First pay (1st–15th) | 43,500 |
| Second pay (16th–end) | 60,900 |

The two pay dates and the total after tax are the numbers the user looks for first.
The history list shows one row per saved month (month, total after tax, both pays).

### 3.2 Recurring monthly items

Fixed income and expenses that repeat each month, added on top of the salary. The
user can add their own items.

| Item | Sample |
| --- | --- |
| Scholarship | +5,000 |
| Rent | −30,000 |
| Services | −4,500 |
| **Balance after fixed items** | **74,900** |

### 3.3 Transactions and purchases

Everyday spending and income: amount, date, category, note and account.

- A list grouped by day, newest first, with a search and filters (category, account,
  date range).
- An add/edit form that is fast to fill in with one hand; amount first.
- Deleting asks for confirmation.

### 3.4 Debts

Money borrowed from others and money lent to others.

- Each debt: direction (borrowed or lent), person, amount, start date, optional due
  date, note.
- Partial repayments, each with an amount and date; the remaining amount is shown.
- States: open, overdue (past the due date) and settled.
- Sample: lent 10,000 to *Sam*, repaid 4,000, remaining 6,000, due at the end of the
  month.

### 3.5 Monthly overview

The home screen: one month at a glance, with month switching.

- Income (salary and recurring income), fixed costs, purchases, debt movements and the
  resulting balance.
- Shortcuts to add a purchase or a repayment.

### 3.6 Reports

- Spending by category (for one month or a range).
- Month over month comparison.
- Debts summary: total owed to the user, total the user owes, overdue items.

### 3.7 Settings

Default currency, theme (system, light, dark), app lock, backup and CSV
export/import, language.

### 3.8 States every screen needs

Empty (first use, with a clear first action), loading, and error. First launch should
lead the user to enter their first salary month.

## 4. Fixed constraints

- **Currency:** Russian ruble (₽) by default; other currencies are possible, and every
  amount always shows its currency. Formatting follows the locale, so the symbol may
  come before or after the number. Layouts must fit long amounts such as
  1,234,567.89 ₽ without truncation.
- **Numbers:** use tabular (fixed-width) figures for amounts so columns line up.
- **Language:** English first. Other languages follow later, including right-to-left
  ones, so layouts must mirror cleanly and allow text about 40% longer than English.
- **No sign-in, sync or social features** in the design for now.

## 5. Accessibility

- Contrast of at least 4.5:1 for body text and 3:1 for large text and UI components
  (WCAG 2.2 AA), in both light and dark mode.
- **Never colour alone:** income and expense also differ by sign (+/−) and icon;
  overdue and settled debts also differ by label or icon.
- Text scales up to 200% without clipping; touch targets are at least 48 × 48 dp.
- Every icon-only control has a clear label for screen readers.

## 6. What to deliver

1. **Colour:** a seed colour and the full Material 3 colour scheme for light and dark
   mode (every role: primary, on-primary, primary container, …, surface containers,
   outline, error), as hex values.
2. **Extra semantic colours**, each with its "on" colour, for light and dark mode:
   income, expense, borrowed, lent, overdue/warning.
3. **Typography:** a font family with an open licence (for example from Google Fonts)
   and any changes to the Material 3 type scale; confirm it has tabular figures and
   Cyrillic support.
4. **Shape and elevation:** corner radii for cards, dialogs, buttons and input fields.
5. **Icons:** a Material Symbols style (outlined, rounded or sharp) and an icon per
   default category.
6. **App icon:** a concept that works as an Android adaptive icon (foreground,
   background and monochrome) and on iOS.
7. **Screens:** mockups or wireframes of the screens in section 3 on a phone in light
   and dark mode, plus one tablet or web layout, including the empty states.
8. **Recommendation:** whether Android dynamic colour (wallpaper-based) should be
   offered as an option or the brand scheme should always be used.

Colours and type scales are easiest to apply as a table or JSON of named roles and hex
values; mockups can be images or a link to a design file.
