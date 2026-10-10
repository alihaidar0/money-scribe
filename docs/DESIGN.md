# DESIGN.md: Money Scribe (Navy Trust)

> The design system of Money Scribe: the single source of truth for the Material 3 theme in `lib/app/theme/` and the file to import into a design tool such as Stitch. It answers the requirements in [`design-brief.md`](design-brief.md). Device: mobile (phone portrait first; tablet and desktop variants reuse it). Light and dark mode.

## 0. Quick reference (design-tool settings)

Set these by hand if the tool does not read the whole file.

- Colour mode: Light (also generate Dark variants)
- Custom/seed colour: `#0F3D73`
- Primary: `#1D477D` · Secondary: `#555F71` · Tertiary: `#6F5675` (muted violet, NOT brown or orange) · Neutral: `#74777F` (navy-tinted grey)
- Saturation: low. Colours must look calm, never neon.
- Fonts: Headline Inter, Body Inter, Label Inter
- Roundness: full (pill) for buttons, chips and the nav indicator; 16 dp for cards; 12 dp for text fields; 28 dp for dialogs and sheets

## 1. Overview

Money Scribe is a calm, trustworthy personal-finance tracker for one person (salary calculator, recurring items, transactions, debts, reports). It should feel like a well-kept ledger: numbers are the content, decoration is secondary. No social features; sign-in and sync screens are not designed yet. Currency: Russian ruble (₽) by default; every amount shows its currency symbol.

Visual character: deep navy brand colour, soft blue-tinted neutral surfaces (never pure white, never pure black), flat tonal cards, generous whitespace. Large areas stay low-chroma. Saturated colour appears only in small elements: buttons, amounts, badges. No gradients and no neon inside data screens. Do not use brown or orange anywhere except the "Overdue" warning colour.

## 2. Colours

Brand seed `#0F3D73`. Use exactly these hex values; never approximate.

| Role | Light | Dark |
| --- | --- | --- |
| primary | `#1D477D` | `#A8C8FF` |
| onPrimary | `#FFFFFF` | `#003062` |
| primaryContainer | `#D6E3FF` | `#1D477D` |
| onPrimaryContainer | `#001B3C` | `#D6E3FF` |
| secondary | `#555F71` | `#BDC7DC` |
| onSecondary | `#FFFFFF` | `#273141` |
| secondaryContainer | `#D9E3F8` | `#3E4758` |
| onSecondaryContainer | `#121C2B` | `#D9E3F8` |
| tertiary | `#6F5675` | `#DBBCE1` |
| onTertiary | `#FFFFFF` | `#3E2845` |
| tertiaryContainer | `#F9D8FE` | `#563E5D` |
| onTertiaryContainer | `#28132F` | `#F9D8FE` |
| error | `#BA1A1A` | `#FFB4AB` |
| onError | `#FFFFFF` | `#690005` |
| errorContainer | `#FFDAD6` | `#93000A` |
| onErrorContainer | `#410002` | `#FFDAD6` |
| surface | `#FAF9FD` | `#121316` |
| onSurface | `#1A1C1E` | `#E3E2E6` |
| surfaceVariant | `#E0E2EC` | `#43474E` |
| onSurfaceVariant | `#43474E` | `#C4C6CF` |
| outline | `#74777F` | `#8E9099` |
| outlineVariant | `#C4C6CF` | `#43474E` |
| surfaceDim | `#DAD9DD` | `#121316` |
| surfaceBright | `#FAF9FD` | `#38393C` |
| surfaceContainerLowest | `#FFFFFF` | `#0D0E11` |
| surfaceContainerLow | `#F4F3F7` | `#1A1C1E` |
| surfaceContainer | `#EEEDF1` | `#1E2023` |
| surfaceContainerHigh | `#E9E7EB` | `#292A2D` |
| surfaceContainerHighest | `#E3E2E6` | `#343538` |
| inverseSurface | `#2F3033` | `#E3E2E6` |
| inverseOnSurface | `#F1F0F4` | `#2F3033` |
| inversePrimary | `#A8C8FF` | `#395F97` |

Flutter has deprecated `surfaceVariant`, so the theme leaves it out and uses the surface container roles.

### 2.1 Money colours

Used only for money meaning. Icon circles use the soft container colour with the on-container icon colour (never a saturated fill). Amount text uses the strong colour on `surface` or on a card surface, never on a container fill. Meaning is never carried by colour alone.

- Income: sign "+", icon `south_west` (arrow down-left)
- Expense: sign "−", icon `north_east` (arrow up-right)
- Borrowed: label "Borrowed", icon `call_received`
- Lent: label "Lent", icon `call_made`
- Overdue: label "Overdue", icon `warning`
- Open: label "Open", icon `schedule`, `secondaryContainer` with `onSecondaryContainer`
- Settled: label "Settled", icon `check_circle`, neutral `onSurfaceVariant` colour

Open and Settled are debt states, not money meanings, so they have no token of their own.

| Token | Light colour | Light on-colour | Light container | Light on-container | Dark colour | Dark on-colour | Dark container | Dark on-container |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| income | `#2A7851` | `#FFFFFF` | `#DCF0E0` | `#003920` | `#8FDCAD` | `#00341D` | `#2C3D32` | `#D4E7D7` |
| expense | `#6A2735` | `#FFFFFF` | `#FFE5E7` | `#591928` | `#E18695` | `#531524` | `#4B3336` | `#FFDADD` |
| borrowed | `#544687` | `#FFFFFF` | `#EFE7FE` | `#342565` | `#C7B7FF` | `#302060` | `#3B3748` | `#E7DFF5` |
| lent | `#00696A` | `#FFFFFF` | `#D8F0EF` | `#003737` | `#78DCDD` | `#003232` | `#283D3D` | `#D0E7E7` |
| overdue | `#834416` | `#FFFFFF` | `#FFE6D9` | `#522300` | `#F7A26C` | `#4B2000` | `#4B3427` | `#FFDBC8` |

Progress bars, charts and decorative accents use primary, secondary and tertiary (violet) tones only, never the money colours, unless the bar represents that exact money meaning (for example a debt repayment bar uses primary).

### 2.2 Hero card

Light mode: `primary` fill (`#1D477D`) with `onPrimary` text. Dark mode: `primaryContainer` fill (`#1D477D`) with `onPrimaryContainer` text. Large amount inside, small supporting figures below.

### 2.3 Measured contrast

WCAG 2.2 contrast ratios of the values above. Body text on `surface`: 16.3:1 light, 14.4:1 dark. Money colours on `surface`: at least 5.1:1 light, 7.1:1 dark. Text on filled colours (including the money on-colours): at least 5.3:1. On-container text on its container: at least 8.5:1. Hero card text: 9.3:1 light, 7.2:1 dark. Outline on `surface`: 4.3:1 light, 5.8:1 dark; on card surfaces at least 4.0:1 (UI components need 3:1).

## 3. Typography

Font family: **Inter** (SIL Open Font License). Supports tabular figures, full Cyrillic, ₽ and the true minus sign −. Always use tabular (fixed-width) figures for every amount, and the true minus "−", never a hyphen. Inter has no Arabic glyphs, so Arabic text needs its own font (see 3.1). The font files (weights 400, 500 and 600) are bundled with the app, so text renders the same on first launch and without a connection, and no font request leaves the device.

| Style | Font | Size / line | Weight | Use |
| --- | --- | --- | --- | --- |
| Display small | Inter | 36 / 44 | 600 | Hero amount |
| Headline medium | Inter | 28 / 36 | 600 | Screen titles on wide layouts |
| Title large | Inter | 22 / 28 | 600 | App bar titles, dialog titles |
| Title medium | Inter | 16 / 24 | 600 | List amounts, card headings |
| Body large | Inter | 16 / 24 | 400 | Notes, form values |
| Body medium | Inter | 14 / 20 | 400 | Secondary list text |
| Label large | Inter | 14 / 20 | 600 | Buttons |
| Label medium | Inter | 12 / 16 | 500 | Chips, captions, day headers |

Text must scale to 200% without clipping. Never truncate amounts: allow a long amount such as 1,234,567.89 ₽ to wrap. Allow labels about 40% longer than English (Arabic is right-to-left; see section 3.1).

### 3.1 Arabic (right-to-left)

Arabic is the second language. Layouts mirror in right-to-left mode, and icons that show direction mirror with them (arrows, back, chevrons); amounts keep their own left-to-right order inside Arabic text.

Open decisions, to be settled in the localization step and then written here:

- The Arabic font: open licence, Arabic glyphs with Latin and ₽ support, bundled like Inter, and weights that match the 400, 500 and 600 used above.
- Arabic-Indic (٠١٢) or Western (012) digits for amounts and dates.

## 4. Shape and elevation

| Element | Radius |
| --- | --- |
| Buttons, chips, nav indicator | fully rounded (pill) |
| Cards | 16 dp |
| Dialogs, bottom sheets (top corners) | 28 dp |
| Text fields (outlined) | 12 dp |
| Floating action button | 16 dp |

Flat by default. Cards use `surfaceContainerLow` on `surface`, no shadow. Hierarchy comes from tonal surfaces. Shadow only for dialogs, menus and the FAB. Dividers use `outlineVariant`, 1 dp.

## 5. Icons

Material Symbols Outlined, weight 400, size 24; filled for the selected navigation item. Touch targets at least 48 × 48 dp. Navigation: Overview `dashboard`, Salary `payments`, Transactions `receipt_long`, Debts `handshake`, Reports `bar_chart`, Settings `settings`. Categories: Groceries `shopping_basket`, Dining `restaurant`, Transport `directions_bus`, Housing `home`, Utilities `bolt`, Health `health_and_safety`, Entertainment `movie`, Shopping `shopping_bag`, Education `school`, Travel `flight`, Gifts `redeem`, Subscriptions `autorenew`, Salary `payments`, Scholarship `workspace_premium`, Other `category`.

## 6. Components

- Navigation: bottom navigation bar on phones with five items (Overview, Salary, Transactions, Debts, Reports); navigation rail on tablet and web; selected item has a filled icon in a `secondaryContainer` pill. Settings is an icon in the top app bar.
- Buttons: filled (`primary`), tonal (`secondaryContainer`), outlined (`outline`), text. All pill-shaped, minimum height 48 dp. "Inverted" buttons use `inverseSurface`.
- Icon buttons: tonal `secondaryContainer` for edit and general actions; delete uses `errorContainer` with `onErrorContainer` icon. Never brown.
- Search field: filled `surfaceContainerHigh`, 12 dp radius, leading search icon.
- Amount row: 40 dp tonal circle with the soft container colour and on-container icon, title and note on the left, signed amount right-aligned in tabular figures, date or account as secondary text. Row sits on `surfaceContainerLow`.
- Forms: amount field first, large, numeric keypad, currency shown per locale; primary action pinned at the bottom for one-handed use.
- Debt status badge: label and icon on a soft container colour (Open, Overdue, Settled; see 2.1), text in the on-container colour.
- Progress bar: 4 dp tall, `primary` on `surfaceContainerHighest`.
- Destructive actions ask for confirmation in a dialog with an error-coloured confirm button.
- Empty states: simple outlined illustration with a `primaryContainer` tint, one sentence, one primary action. First launch leads to "Enter your first salary month".
- Loading: skeleton rows. Error: error icon, one-sentence message, "Try again" button.

## 7. Layout

Material 3 window size classes: compact < 600 dp, medium 600 to 839 dp, expanded ≥ 840 dp. Expanded screens use list and detail side by side with a navigation rail. Content max width on web about 1200 dp.

### 7.1 Navigation and screen anatomy

- Five top-level screens: Overview (launch screen), Salary (segments: Month, Fixed items), Transactions, Debts, Reports. Bottom navigation bar on phones, navigation rail on tablet and web. Order is fixed. Settings is a gear icon in the top app bar of every top-level screen.
- Top-level screens: small top app bar, title left-aligned and equal to the screen name (Overview, Salary, Transactions, Debts, Reports); no back arrow; no profile or avatar icon (accounts are not designed yet); bottom bar visible with the current item selected.
- Secondary screens (Salary history, Add/Edit transaction, Add debt, Debt details, Settings): back arrow at the left, title, no bottom bar.
- Arrows (‹ ›) appear only around the month name on Overview. Elsewhere a month is chosen from a chip with a down-chevron.
- Salary history is reached from the History icon on Salary. Fixed items is the second segment on Salary. Debt details opens from a debt card. Add transaction opens from the Add button, the Overview "Add purchase" button, or a row tap (edit).
- Use only the labels and numbers defined in this file and in the design brief; never invent formulas, multipliers, tax names, badges or watermarks. Never truncate text or amounts.

## 8. Do and don't

- Do keep every amount with ₽, a sign and an icon; do keep tabular figures.
- Do mirror layouts for Arabic (right-to-left), including icons that show direction.
- Don't use brown, orange or bright green except as the specified money colours.
- Don't use pure white (`#FFFFFF`) or pure black backgrounds.
- Don't add gradients, photography or decoration inside data areas.
- Don't show social elements; sign-in and sync are not designed yet.

## 9. Sample data for mockups

All figures are invented. Currency ₽. Salary month October 2026: base salary 100,000; working days 1st to 15th: 10; working days in month: 20; food allowance per day 500; working hours 160; extra hours 8; tax rate 13%. Results: food allowance 10,000; extra-hours pay 10,000; income before tax 120,000; tax 15,600; total after tax 104,400; first pay (1st–15th) 43,500; second pay (16th–end) 60,900. Recurring items: Scholarship +5,000; Rent −30,000; Services −4,500; balance after fixed items 74,900. Debts: Sam, lent 10,000, repaid 4,000, remaining 6,000, due 31 Oct (Open); Maria, lent 2,500, repaid 0, remaining 2,500, due 30 Sep (Overdue); Anna, borrowed 3,000, repaid 3,000, remaining 0 (Settled). Owed to the user 8,500; user owes 0. Overview for October 2026: salary +104,400; recurring income +5,000; fixed costs −34,500; purchases −18,250; debt movements +4,000 (repayment from Sam); income +109,400; spent −52,750; balance 60,650 (= 109,400 − 52,750 + 4,000). Category spending for the month, total 52,750: Housing 30,000 (56.9%), Groceries 9,800 (18.6%), Utilities 4,500 (8.5%), Transport 3,400 (6.4%), Dining 3,150 (6.0%), Other 1,900 (3.6%). Salary history: October 104,400 (43,500 / 60,900); September 100,050 (43,500 / 56,550); August 104,400 (43,500 / 60,900).

## 10. Prompt block for design tools

Copy this at the start of any screen prompt if the tool drifts from the design system.

Design for "Money Scribe", a calm personal-finance app (Material 3). Use DESIGN.md exactly: primary #1D477D, secondary #555F71, tertiary #6F5675 (muted violet), neutral #74777F, surface #FAF9FD, cards #F4F3F7, income #2A7851 / expense #6A2735 with soft pale icon circles, no brown, no neon, no gradients. Font Inter with tabular figures. Pill buttons, 16 dp cards, 12 dp fields. Every amount shows ₽ and a +/− sign plus an icon. Dark mode: surface #121316, card #1A1C1E, primary #A8C8FF.
