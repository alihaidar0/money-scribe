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

Money Scribe is a calm, trustworthy personal-finance tracker for one person (salary calculator, recurring items, transactions, debts, reports). It should feel like a well-kept ledger: numbers are the content, decoration is secondary. No social features; sign-in screens are not designed yet. Currency: Russian ruble (₽) by default; every amount shows its currency symbol.

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

- Income: sign "+", icon `arrow-down-left`
- Expense: sign "−", icon `arrow-up-right`
- Borrowed: label "Borrowed", icon `arrow-down-left`
- Lent: label "Lent", icon `arrow-up-right`
- Overdue: label "Overdue", icon `triangle-alert`
- Open: label "Open", icon `clock`, `secondaryContainer` with `onSecondaryContainer`
- Settled: label "Settled", icon `circle-check`, neutral `onSurfaceVariant` colour

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

Font family: **Inter** (SIL Open Font License). Supports tabular figures, full Cyrillic, ₽ and the true minus sign −. Always use tabular (fixed-width) figures for every amount, and the true minus "−", never a hyphen. Inter has no Arabic glyphs, so Arabic text uses its own font, IBM Plex Sans Arabic (see 3.1). The font files (weights 400, 500 and 600 of each font) are bundled with the app, so text renders the same on first launch and without a connection, and no font request leaves the device.

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

The table shows the English type scale; Arabic uses the same sizes, lines and weights in IBM Plex Sans Arabic (see 3.1).

Text must scale to 200% without clipping. Never truncate amounts: allow a long amount such as 1,234,567.89 ₽ to wrap. Allow labels about 40% longer than English (Arabic is right-to-left; see section 3.1).

### 3.1 Arabic (right-to-left)

Arabic is the second language. Layouts mirror in right-to-left mode, and icons that show direction mirror with them (arrows, back, chevrons); amounts keep their own left-to-right order inside Arabic text.

- **Font:** IBM Plex Sans Arabic (SIL Open Font License), weights 400, 500 and 600, bundled like Inter. It has Arabic and Latin letters, digits, ₽ and the true minus −, but no Cyrillic.
- **Where it applies:** the whole UI uses it while the language shown is Arabic, with the same sizes, lines and weights as the table in section 3. Inter is its fallback, so Cyrillic text (for example a person's name) still shows. In the English UI, Inter stays the font and IBM Plex Sans Arabic is the fallback, so Arabic text typed by the user (for example a name) shows in it.
- **Digits:** always Western (0123456789), in every language and for every number: amounts, dates, counts and percentages. Arabic-Indic digits (٠١٢) are never used. IBM Plex Sans Arabic has fixed-width digits by default, so amounts line up in columns without extra settings.
- **Mirroring:** use start and end values (`EdgeInsetsDirectional`, `AlignmentDirectional`), never left and right. The back arrow sits at the start (on the right in Arabic) and the Settings icon at the end (on the left).

Amounts: the number comes first and the currency symbol after it (`60,650.00 ₽`) in every language, always with the kopecks. In Arabic text each amount is wrapped in Unicode left-to-right isolates by `MoneyFormatter`, so its sign, number and symbol keep their order.

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

Lucide (the `lucide_icons_flutter` package, names below in Lucide's kebab-case), regular stroke, size 24; the selected navigation item is marked by its pill, since Lucide has no filled style. Icons that show direction (chevrons, sign in and out) use the package's `Dir` variants, which mirror in right-to-left. Touch targets at least 48 × 48 dp. Navigation: Overview `layout-dashboard`, Salary `banknote`, Transactions `receipt-text`, Debts `handshake`, Reports `chart-column`, Settings `settings`. Categories: Groceries `shopping-basket`, Dining `utensils`, Transport `bus`, Housing `house`, Utilities `zap`, Health `heart-pulse`, Entertainment `clapperboard`, Shopping `shopping-bag`, Education `graduation-cap`, Travel `plane`, Gifts `gift`, Subscriptions `refresh-cw`, Salary `banknote`, Scholarship `award`, Other `shapes`.

App icon: a fountain-pen nib (the scribe) in a light circle on a blue background cut by two diagonal facets. Colours: background `#0F3D73` with facets `#0B3264` and `#154983`; circle `#D6E3FF`; nib `#0F3D73` and `#1D477D`. The Android adaptive icon keeps the mark inside the 66 dp safe zone and has a one-colour version for themed icons. The staging app uses the same icon with an amber badge (`#FFB300`): a dot at the lower right of the Android adaptive icon and a diagonal band across the top-right corner of the square icon; the badge is for the icon only and does not change the colours of the app. The SVG sources are in `assets/icon/`.

## 6. Components

- Navigation: a floating bar on phones (a rounded `surfaceContainerHigh` bar, 64 dp high, at most 400 dp wide, inset from the screen edges) with five items (Overview, Salary, Transactions, Debts, Reports). The selected item grows into a `secondaryContainer` pill with its icon (a heavier stroke) and its label; the other items show their icon only and keep a semantic label and a tooltip, so no label ever wraps. A navigation rail on tablet and web, in a rounded card to match. Settings is an icon in the top app bar.
- Buttons: filled (`primary`), tonal (`secondaryContainer`), outlined (`outline`), text. All pill-shaped, minimum height 48 dp. "Inverted" buttons use `inverseSurface`.
- Icon buttons: tonal `secondaryContainer` for edit and general actions; delete uses `errorContainer` with `onErrorContainer` icon. Never brown.
- Search field: filled `surfaceContainerHigh`, 12 dp radius, leading search icon.
- Amount row: 40 dp tonal circle with the soft container colour and on-container icon, title and note on the left, signed amount right-aligned in tabular figures, date or account as secondary text. Row sits on `surfaceContainerLow`.
- Settings: the language is a row with the flag of the current language and its name, which opens a bottom sheet with a card for each language: System default (a globe, the default), English (United Kingdom flag) and العربية (Saudi Arabia flag). Each language is written in its own language, so it can be found whatever language the app shows, and the selected card has a primary outline and a check. A tap applies the choice at once and closes the sheet; it is remembered. A new language is added to the list by giving it a name and a flag. Below the language, a Notifications section (shown only where push is available) has one row, "Show notifications", with its state as the subtitle (Allowed, Not allowed yet, or Blocked with a pointer to the system settings) and a tonal "Allow" button while the app can still ask. Staging builds add a "Copy push token" row for test messages; production builds never show it.
- Forms: amount field first, large, numeric keypad, currency shown per locale; primary action pinned at the bottom for one-handed use.
- Debt status badge: label and icon on a soft container colour (Open, Overdue, Settled; see 2.1), text in the on-container colour.
- Progress bar: 4 dp tall, `primary` on `surfaceContainerHighest`.
- Session row (Where you are signed in): a 40 dp tonal circle with a device icon (`smartphone`, `tablet`, `computer` by platform), the device name as the title, the system and app version as a second line, and the dates as a third line (`bodySmall`, `onSurfaceVariant`); the session of this device carries a "This device" tonal badge and sits first. The whole row opens the details sheet; a chevron shows it. Previous sessions are grouped under the device name, and the end of a session is a line with the reason in words, never a code.
- Timeline item (Security activity): a day heading in `labelLarge`, then rows on `surfaceContainerLow`, each with a 40 dp tonal circle whose icon follows the type (`login`, `logout`, `devices_off`, `key`, `lock_reset`, `mail`, `fingerprint`, `download`, `upload`), a title, a second line with the device, and the time at the end in tabular figures. A warning entry (an old sign-in used again) uses `errorContainer` with `warning` and one sentence and an action; nothing else in the list uses the error colour.
- Notice banner: `secondaryContainer`, an `info` icon, one sentence ("Records in another currency are not shown here."), no action; it sits under the month control and is not dismissible.
- Reference line (Something went wrong): "Reference" in `labelSmall`, the code in tabular figures that may wrap, and a text button "Copy"; the code is left to right in Arabic too.
- Destructive actions ask for confirmation in a dialog with an error-coloured confirm button.
- Empty states: simple outlined illustration with a `primaryContainer` tint, one sentence, one primary action. First launch leads to "Enter your first salary month".
- Loading: skeleton rows. Error: error icon, one-sentence message, "Try again" button. No connection uses the same pattern with the `cloud_off` icon.

## 7. Layout

Material 3 window size classes: compact < 600 dp, medium 600 to 839 dp, expanded ≥ 840 dp. Expanded screens use list and detail side by side with a navigation rail. Content max width on web about 1200 dp.

Adaptive layouts (built; the phone layout is never changed, a wider window only adds room):

- **One rule:** a screen is one column on a phone. From 600 dp (medium) a screen pushed above the navigation is **framed**: the whole screen, app bar included, is one centred column on a tinted canvas (`WideFrame`: 560 dp for a short form or a list of settings, 720 dp for a form, details or a list, 1040 dp for a page with two columns of its own). From 840 dp (expanded) the five top-level screens and Settings use the room.
- **List and detail** (Transactions, Debts): the list on one side and the chosen item on the other, with its buttons (the newest transaction, or the first debt, is chosen first). Cards and rows select instead of opening.
- **Two columns** (Overview, Salary, Reports): the figures or the chart on one side and the rows or the inputs on the other (`TwoColumns`, from 720 dp of content). The controls above (view switch, month, part) keep the width of a phone.
- **Sections** (Settings): a list of the five sections on one side and the rows of the chosen one on the other.
- **Authentication**: the page splits into a brand panel (app icon, name, tagline; the hero card colours in both themes) and the form in a card. The Welcome screen shows the brand itself and does not split.

### 7.1 Navigation and screen anatomy

- Five top-level screens: Overview (launch screen), Salary (segments: Month, Fixed items), Transactions, Debts, Reports. Bottom navigation bar on phones, navigation rail on tablet and web. Order is fixed. Settings is a gear icon in the top app bar of every top-level screen.
- Top-level screens: small top app bar, title left-aligned and equal to the screen name (Overview, Salary, Transactions, Debts, Reports); no back arrow; no profile or avatar icon (the account is reached from Settings); bottom bar visible with the current item selected.
- Secondary screens (Salary history, Add/Edit transaction, Add debt, Debt details, Settings): back arrow at the left, title, no bottom bar.
- Arrows (‹ ›) appear only around the month name on Overview. Elsewhere a month is chosen from a chip with a down-chevron.
- Salary history is reached from the History icon on Salary. Fixed items is the second segment on Salary. Debt details opens from a debt card. Add transaction opens from the Add button, the Overview "Add purchase" button, or a row tap (edit).
- Use only the labels and numbers defined in this file and in the design brief; never invent formulas, multipliers, tax names, badges or watermarks. Never truncate text or amounts.

### 7.2 Account, sign-in and the waits the server asks for

- **Account screen** (Settings, Account): a 96 dp circle with the first letter of the name on `primaryContainer`, the name in `headlineSmall`, the email below it in `onSurfaceVariant` (an address always reads left to right, also in Arabic), then list tiles with a leading icon and a chevron that mirrors in Arabic: Edit name, Change email, Change password, Sign out. A divider, then Delete account with the error colour for icon and text.
- **Dialogs** for one short question (Sign out, Delete account, Edit name, the password prompt before a new email code): `AlertDialog`, Cancel as a text button and the action as a filled button; a failure is a `MessageBanner` above the field, a wrong password is the error text under the password field. A delete is a filled button in `error`. The dialog stays open while the server answers and shows a spinner in the button.
- **Forms** that change something about the account (Change password, Change email): a normal secondary screen with a back arrow, the fields, and the action in the pinned button bar at the bottom. What was typed stays when a failure view is shown.
- **The code page** (verify email, reset code, new email): an icon circle, the title, the address the code went to (isolated left to right), six large rounded boxes, "Resend code in 0:42" as muted text that becomes a text button, a filled Verify button, and text buttons for the ways back. A wrong code is red text under the boxes with the tries left.
- **A wait the server asks for** is never a constant: the button label becomes "Try again in M:SS" (disabled) and counts down; the screen never says why more than one short sentence. A busy server (`503`) is the "The service is busy" state with "Please try again shortly."
- **Sessions and Security activity** (Settings, Security) are secondary screens. "Where you are signed in" has two tabs under the app bar (Active, Previous; Material secondary tabs), a list of session rows, and under the Active list an outlined "Sign out of all other devices" button (shown only when another session exists) with one sentence above it. A session opens a modal bottom sheet with label and value rows and, for another active device, "End this session" (outlined, error colour); the confirmation is a dialog. "Sign out of all other devices" is a dialog with a password field, like Delete account. A wait ("Try again in 14:32") counts down on the confirm button.
- **Waits for any request.** A `429` on any call counts down on the control that caused it in the same way as the authentication waits; the screen keeps what the person typed.
- Every account screen has its loading (skeleton), error, no connection and busy states, English and Arabic, light and dark.

## 8. Do and don't

- Do keep every amount with ₽, a sign and an icon; do keep tabular figures.
- Do mirror layouts for Arabic (right-to-left), including icons that show direction.
- Don't use brown, orange or bright green except as the specified money colours.
- Don't use pure white (`#FFFFFF`) or pure black backgrounds.
- Don't add gradients, photography or decoration inside data areas.
- Don't show social elements; sign-in is not designed yet.

## 9. Sample data for mockups

All figures are invented. Currency ₽. Salary month October 2026: base salary 100,000; working days 1st to 15th: 10; working days in month: 20; food allowance per day 500; working hours 160; extra hours 8; tax rate 13%. Results: food allowance 10,000; extra-hours pay 10,000; income before tax 120,000; tax 15,600; total after tax 104,400; first pay (1st–15th) 43,500; second pay (16th–end) 60,900. Recurring items: Scholarship +5,000; Rent −30,000; Services −4,500; balance after fixed items 74,900. Debts: Sam, lent 10,000, repaid 4,000, remaining 6,000, due 31 Oct (Open); Maria, lent 2,500, repaid 0, remaining 2,500, due 30 Sep (Overdue); Anna, borrowed 3,000, repaid 3,000, remaining 0 (Settled). Owed to the user 8,500; user owes 0. Overview for October 2026: salary +104,400; recurring income +5,000; other income +1,500; fixed costs −34,500; purchases −18,250; debt movements +4,000 (repayment from Sam); income +110,900; spent −52,750; balance 62,150 (= 110,900 − 52,750 + 4,000). Spending for the month, total 52,750: Fixed costs 34,500 (65.4%), Groceries 9,800 (18.6%), Transport 3,400 (6.4%), Dining 3,150 (6.0%), Other 1,900 (3.6%); the purchases by category add up to 18,250. Sessions: this phone (Android 15, signed in 20 Oct, with fingerprint) and Chrome on Windows (signed in 22 Oct, with password); a previous session on Chrome on Windows ended 14 Oct because the password was changed. Salary history: October 104,400 (43,500 / 60,900); September 100,050 (43,500 / 56,550); August 104,400 (43,500 / 60,900).

## 10. Prompt block for design tools

Copy this at the start of any screen prompt if the tool drifts from the design system.

Design for "Money Scribe", a calm personal-finance app (Material 3). Use DESIGN.md exactly: primary #1D477D, secondary #555F71, tertiary #6F5675 (muted violet), neutral #74777F, surface #FAF9FD, cards #F4F3F7, income #2A7851 / expense #6A2735 with soft pale icon circles, no brown, no neon, no gradients. Font Inter with tabular figures. Pill buttons, 16 dp cards, 12 dp fields. Every amount shows ₽ and a +/− sign plus an icon. Dark mode: surface #121316, card #1A1C1E, primary #A8C8FF.
