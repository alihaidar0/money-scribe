# Money data, reports, sessions and CSV (agreed with the backend)

The second API step after authentication ([`backend-api.md`](backend-api.md), section 7) and after the
salary step: accounts, categories, transactions, debts, reports, the Overview, active sessions with the
security activity, and the CSV export and import. It was agreed with the backend developer in a written
exchange and is recorded in the backend repository as issues #63 to #69
(`alihaidar0/money-scribe-backend`).

**Status: agreed, not built.** No endpoint of this page is in a pinned contract yet. The app keeps reading
invented data from its fake repositories until the backend tells the app that an endpoint has merged and
gives the commit to pin. **When a contract is pinned, the contract wins over this page.** Nothing here
contains real data; every example uses invented values.

| Issue | What it adds | Order |
| --- | --- | --- |
| #63 | Hardening: request id, `no-store`, text rules, per-user limits, a size cap | 1 |
| #64 | Accounts and categories | 2 |
| #65 | Transactions and day totals | 3 |
| #66 | Debts and repayments | 4 |
| #67 | Month report, debts report and the Overview | 5 |
| #68 | Active and previous sessions, security activity | 6 |
| #69 | CSV export and import | 7 |

## 1. Rules for every call

These come with the hardening issue and hold for every signed-in call.

- **Request id.** Every response, errors included, carries `X-Request-ID`. The generated client does not
  return headers, so the data layer reads it from the failed response and the "Something went wrong" screen
  shows it as a reference the person can copy. The app never sends its own.
- **`Cache-Control: no-store`** on every `/api/v1/` response. Nothing to do in the app.
- **Text.** Every text field is trimmed and normalised (NFC) by the server. It rejects control characters (a
  newline and a tab included) and the bidirectional override, embedding and isolate characters (U+202A to
  U+202E, U+2066 to U+2069) with `400 invalid_characters` on the field. The direction marks and the joiners
  that Arabic needs stay allowed. The app removes the rejected characters from every text field before it
  sends, on typing and on paste (a line break becomes a space; a single-line field drops it before the app
  sees it), because it wraps amounts in exactly
  those isolates in Arabic and a copied amount must not become an error. Imported CSV cells are **not**
  stripped: the server reports the row.
- **Limits per signed-in user,** shared by all the devices of one person. Each call belongs to exactly one
  group:

  | Group | Limit |
  | --- | --- |
  | Reads | 300 a minute |
  | Writes | 60 a minute |
  | Reports, Overview, day totals | 60 a minute |
  | Lists with `search` | 30 a minute |
  | Export | 5 an hour |
  | Import (dry runs included) | 120 calls an hour |
  | Session actions | 30 an hour |

  A limited call is `429 throttled` with `Retry-After` (whole seconds, at least 1, always present). Any `429`
  is handled with `Retry-After`: the control that caused it is disabled with a countdown. A full-screen failure
  counts down on its Try again button, and the message of a failed action shows the time left with no Retry
  button. The search box waits about half a second after the last key and cancels the call still in flight.
- **Size.** A body over 256 KB is `400 request_too_large` (the CSV import has 1 MB); a person should never meet it.
- **`503 service_unavailable`** (with `Retry-After`) only for export, import and "sign out of all other
  devices", when the limit store is down. Plain reads and writes keep working.
- **`404`.** A record that does not exist, or belongs to another person, answers the JSON error `not_found`.
  A path that does not exist is Django's own HTML page. The app treats a `404` as "the record is gone" (for
  example a second delete) **only** when the body is the JSON with `code: not_found`; any other `404` is a
  failure (this is how an older staging server shows itself).
- **Links to the next page.** A list answer has the cursor envelope (`next`, `previous`, `results`). The app
  follows `next` only when its origin is the API address it was built with, because it sends the access token
  with every call.
- **New ids** are UUIDs. Writing rules (`Idempotency-Key`, `If-Match`, `412`) are those of
  [`backend-api.md`](backend-api.md), *Writing safely*.

## 2. Accounts and categories

- **Accounts** (`/api/v1/accounts/`): `id`, `name` (1 to 30), `kind` (`card`, `cash`, `other`), `version`.
  At most 20. A name already used is `400 name_taken`, the 21st is `409 account_limit_reached`, and an account
  that has transactions cannot be deleted: `409 account_has_transactions`. The server creates "Card" and
  "Cash" when the email is verified, in the account's language (Arabic: بطاقة and نقدًا, the words of the
  app's own kind labels); lists are ordered by creation, so "Card" comes first and is preselected.
- **Categories** (`/api/v1/categories/`): `id`, `name`, `icon`, `kind`, `is_custom`, `key`, `version`.
  - Seven **built-in** categories are read-only (`403 category_is_builtin`) and carry a stable `key`
    (`groceries`, `dining`, `transport`, `housing`, `utilities`, `scholarship`, `other`). The app shows its
    own English or Arabic name for a key; `name` is only an English fallback. Kinds: `scholarship` is income,
    `other` is both, the rest are expenses.
  - A **custom** category has `key: null`, kind `both` (set by the server), a name of 1 to 30 and one of eight
    icons (`gifts`, `health`, `entertainment`, `shopping`, `education`, `travel`, `subscriptions`, `other`;
    `400 invalid_choice` otherwise). At most 50 (`409 category_limit_reached`).
  - A custom name cannot equal a built-in key or English name (`400 name_taken`). The server does not know
    the Arabic words, so **the app also checks the typed name against its own built-in names** before sending.
  - Deleting a custom category answers `204` and moves its transactions to `other`; those transactions get a
    new `version`, so an edit that was open on one of them ends in `412` and is read again.
  - The response `icon` is a plain slug; an unknown one is shown with the `other` icon.
- Both lists are asked with `limit=100`, so one call returns the whole list.

## 3. Transactions and day totals

- **Transactions** (`/api/v1/transactions/`): `id`, `kind` (`expense`, `income`), `amount` (a decimal string,
  always positive), `currency`, `date` (`YYYY-MM-DD`, 2000-01-01 to 2099-12-31), `category_id`, `account_id`,
  `note` (0 to 100), `version`. `currency` is required on create and **cannot be changed**: the app never
  sends it on an edit (`400 read_only`, even with the stored value). The category must allow the kind
  (`400 category_not_allowed`); an unknown or foreign `category_id` or `account_id` is `400 does_not_exist`
  on that field. At most 100,000 (`409 transaction_limit_reached`). Delete is a hard delete.
- **List filters:** `date_from`, `date_to`, `category_id` and `account_id` (repeatable, at most 20 values),
  `kind`, `search`. Order: `-date`, `-created_at`, `-id` (the last added first within a day). `search`
  matches the **note only**, 2 to 100 characters, so the search box says so; the filter sheet covers the
  category and the account. A call with `search` counts in the search group.
- **Day totals** (`GET /api/v1/reports/day-totals/`): one item per day that has records, newest first, with its
  currencies inside: `date` and `totals[]` of `{currency, total}`, `total` being a signed decimal (income minus
  expenses). The same filters as the list, without `search`; `date_from` and `date_to` are optional;
  paginated by days (`limit` 50, at most 100), so a day always arrives complete.
- **How the list and the totals are read together.** The list is read in cursor pages of about 50 as the person
  scrolls. The app keeps a map from day to totals, and each time it loads a page of the list it reads pages of
  totals until the map reaches the oldest day of the list; both use the same filters and the same order, so
  they stay level however sparse the data is. A list with words in the search box has no day totals and does
  not call the endpoint. A change to a record reloads the list and drops the map.
- **The search** waits half a second after the last key and asks the server only when it has two letters or
  more; a newer search drops the answer to an older one. The part of a two-payment month (1st-15th or
  16th-end) is not a filter of the server: the app cuts it from the pages it has and loads more pages when a
  part shows too little. A filter takes at most 20 categories, and the Filters sheet stops at 20.

## 4. Debts and repayments

- **Debts** (`/api/v1/debts/`): `id`, `direction` (`lent`, `borrowed`), `person` (1 to 50), `amount`,
  `currency`, `start_date`, `due_date` (or `null`), `note` (0 to 100), and the read-only `repaid`, `remaining`,
  `status` (`open`, `overdue`, `settled`) and `repayments[]`, then `version`. `direction` and `currency` are
  fixed after creation (`400 read_only`): the edit screen shows them as fixed. `PATCH {"due_date": null}`
  clears the due date and `{"note": ""}` the note. At most 500 debts.
- **Status** is counted in the person's day, from the time zone in the settings; the app does not send `today`
  and shows the status the server sent (a status it does not know is worked out on the device).
- **List:** filters `direction`, `status` (repeatable), `search` (the person, 2 to 50). The repayments come
  with each debt (up to 200). The app reads every page (`limit=100`, at most 5 calls) and sorts the debts
  itself: those still to be repaid first, then the settled ones, each oldest first. The totals are added up
  per currency; the default currency is shown, with a notice when debts in another currency exist.
- **Repayments** are a sub-resource: `POST /debts/{id}/repayments/`, `PATCH` and `DELETE` of one. Every
  repayment call answers with **the whole debt** (`201` for a create, `200` otherwise). The `ETag` of such an
  answer is **the debt's version**; a repayment write does not change it. The repayment's own version is in
  `repayments[].version` and goes in `If-Match` on that repayment only. Repayments are shown in the server's
  order (by date, then id).
- **Rules and codes:** `exceeds_remaining` (`attr` `amount`, and the error item carries `remaining`),
  `amount_below_repaid`, `due_before_start`, `repayment_before_start`, `start_after_repayment`,
  `debt_limit_reached`, `repayment_limit_reached`. The app checks the first rules on the form before it
  sends (a repayment cannot be dated before the debt starts, the amount cannot go below what was repaid, the
  start date cannot move after a repayment); the server's code is the last word.
- **Two devices.** A change or a delete of a debt sends the debt's `version`, and one of a repayment sends
  the repayment's own. A `412` (or a `404` on a change) means another device got there first: nothing is
  changed, the debt is read again and the screen says so. A delete that finds the record already gone
  (`404 not_found`) counts as done. An `exceeds_remaining` shows the `remaining` of the answer and reads the
  debt again.
- **A new debt** is in the default currency of the settings, which is also the currency of the totals; the
  direction and the currency are fixed afterwards. The start-day picker of a debt with repayments stops at its
  last repayment, and the picker of a repayment starts at the day the debt starts.
- **The due day** is taken away with `{"due_date": null}`, so that one request goes through a copy of the HTTP
  client that keeps `null` fields (see `docs/architecture.md`).

## 5. Reports and the Overview

Every amount is a decimal string in one currency; sums are never added across currencies. The app sends
`currency` (the default currency of the settings) on every call. A month outside 2000-01 to 2099-12 is not a
route.

| Screen | Reads |
| --- | --- |
| Overview | `GET /api/v1/overview/months/{month}/` |
| Reports, Categories | the month report, and the Overview's `fixed_costs` as one more slice |
| Reports, Month vs month and Part vs part | the Overview (two calls) |
| Reports, Debts | `GET /api/v1/reports/debts/` |
| Overview, "Add repayment" | the debts report (the unsettled debts) |

- **Overview:** `month`, `currency`, `has_data`, `currencies`, and the blocks `total`, `first_part`,
  `second_part` (the last two are `null` for a month paid once). Each block: `salary`, `recurring_income`,
  `fixed_costs`, `income_transactions`, `purchases`, `debt_repayments_received`, `debt_repayments_made` (all
  positive) and `balance`, signed: `salary + recurring_income + income_transactions - fixed_costs - purchases +
  debt_repayments_received - debt_repayments_made`. The server sends the balance and the app shows it.
  Income transactions have their own line. The salary and the fixed lines count only when the saved month is
  in the report currency. Creating a debt is not a movement, only repayments are; they and the transactions
  are placed by their date, in the halves 1st to 15th and 16th to the end.
- **Month report:** `income_transactions`, `purchases` and `categories[]` (the **spending** by category, from
  expense transactions only, biggest first: `category_id`, `category_key`, `name`, `icon`, `amount`), for the
  month and for `first_part` and `second_part`. `categories[]` adds up to `purchases`, which equal the
  Overview's line of the same name; the two calls are not one transaction, so the app reads both together
  and does not treat a small difference as an error. The Categories chart adds the Overview's `fixed_costs`
  as a slice "Fixed costs" (fixed items have no category), so the chart adds up to the Overview's spending.
- **Debts report:** `has_data` and `by_currency[]`, one block per currency with `owed_to_you`, `you_owe`, and
  the unsettled debts as `overdue[]` and `open[]`.
- **`has_data` and `currencies`.** An empty month is `200` with zeros and `has_data: false`. `currencies`
  lists every currency with data in the month; when it holds more than the report currency, the Overview and
  Reports say that records in other currencies are not shown.
- **How the app uses them.** Every call sends the default currency of the settings, and the amounts are in
  it. The Overview shows "Other income" (the income transactions) as its own row and counts it in the income;
  the balance shown is the one the server sends. A month of the Reports is read from the Overview and the
  month report together, so its income and spending are the Overview's, and its categories get one more slice,
  "Fixed costs", which opens the fixed items instead of the transactions. A built-in category is named by the
  app from its `key`, in the language of the app; a custom one shows its own name. The debts report is shown for
  the default currency, and the "Add repayment" sheet of the Overview lists the unsettled debts of every
  currency. A month outside 2000 to 2099 is not asked and has no data. A month with `has_data: false` keeps
  the month controls, so another month can be chosen, and the debts do not depend on the month.
- There is no year or custom-period report and no comparison endpoint.

## 6. Sessions and security activity

- **Sessions** (`GET /api/v1/auth/sessions/?status=active|ended`): `id`, `device_id`, `device_name`,
  `platform`, `os_version`, `app_version`, `signed_in_at`, `last_active_at`, `expires_at`, `is_current`,
  `sign_in_method` (`password`, `device_key`, `email_code`), `network` (the address cut to its network, for
  example `203.0.113.0/24`, or `null`; never a full address) and, for an ended session, `ended_at` and
  `end_reason` (`signed_out`, `revoked_by_user`, `expired`, `session_limit`, `password_changed`,
  `password_reset`, `email_changed`, `token_reuse`, `replaced`; an unknown value reads as "ended").
  - **Active** is one page of at most 10, the current one first. A session that has not refreshed for 30
    days, or reached its 90-day limit, is ended (`expired`), not active.
  - **Ended** is paginated, newest sign-in first, kept 90 days after it ended. A device that signed in five
    times shows five rows; the app groups them by `device_id`. The person cannot delete an ended session.
- **End one session:** `DELETE /api/v1/auth/sessions/{id}/` (`204`). Ending **another** device also removes
  that device's fingerprint key and push token, with no opt-out, so the confirmation says so and the list of
  phones with fingerprint sign-in is read again. The current session is ended with sign-out, not with this call.
- **Sign out of all other devices:** `POST /api/v1/auth/sessions/revoke-others/` with `current_password`;
  answers `{ended, device_keys_removed}` and removes every fingerprint key except this device's. A wrong
  password is `400 invalid_password`; too many are `429 password_attempts_exceeded` with the countdown.
- At most 10 active sessions: a new sign-in at the limit ends the least recently active one, and that device
  gets `401 session_limit_reached`, a final sign-out reason with its own message. A sign-in from a device that
  already has a session ends the older one (`session_signed_out`).
- **Security activity** (`GET /api/v1/auth/session-history/`): cursor-paginated, newest first, kept 90 days.
  Entries: `id`, `type`, `occurred_at`, `device_name`, `platform`, `app_version`, `sign_in_method` (on
  `signed_in`), `session_id` (or `null`), and `kinds` and `count` (on data events). Types: `signed_in`,
  `signed_out`, `session_revoked`, `session_limit_reached`, `password_changed`, `password_reset`,
  `email_changed`, `device_key_added`, `device_key_removed`, `token_reuse_detected`, `data_exported`,
  `data_imported`. An unknown type, platform or method is shown with a generic wording. For
  `session_revoked`, `session_limit_reached` and `token_reuse_detected` the device is the one that was ended.
  Failed sign-ins and account deletion are not entries.
- **Imports in the activity.** The server writes one `data_imported` entry for each real import call, so a
  long file is several entries. The app shows consecutive entries of the same session, less than 15 minutes
  apart, as one (the counts added, the kinds joined), and reads the next page before it shows a group that
  touches the end of the page.
- A sign-in from a device with no session in the last 90 days sends the account owner an email (no link).

## 7. CSV export and import

- **Export:** `POST /api/v1/exports/` with `kinds` (`transactions`, `debts`, `salary_months`), a period
  (`from` and `to`, both left out for all time; "this year" is sent as dates) and `current_password`. The
  answer is a CSV file for one kind, or a zip with one file per kind. The app asks for the password in a
  dialog first, saves the file in its private cache, shares it and deletes it afterwards. The server also
  sends the owner an email that an export was made. A wrong password is `400 invalid_password`, then the
  shared countdown; five exports an hour.
- **Files:** UTF-8 with a byte order mark, `,` as the separator, a fixed header, dates `YYYY-MM-DD`, amounts
  as decimal strings, an empty cell means none, oldest first. Columns: `transactions` has `date`, `kind`,
  `amount`, `currency`, `category_key`, `category_name`, `account_name`, `note` (a built-in category has its
  key and no name, a custom one the reverse); `debts` has `direction`, `person`, `amount`, `currency`,
  `start_date`, `due_date`, `note` and `repayments` (a JSON cell); `salary_months` has the month's inputs,
  `extra_hours` and `tax_rate` with two decimals, and `fixed_items` (a JSON cell).
- **Formula injection.** A text cell that starts with `=`, `+`, `-`, `@`, a tab, a carriage return, a line
  feed, or with `'` followed by one of those, is written with one `'` in front. The import removes exactly one
  `'` in that case. Amounts, dates and the JSON cells are never changed.
- **Import:** the app reads the file and sends rows as JSON: `POST /api/v1/imports/` with `dataset`,
  `dry_run` and up to 500 `rows`, each with a `row` number (its line in the file). It accepts a `.csv`, or a
  `.zip` with the three files in the order transactions, debts, salary months (with a cap on the size after
  unzipping); it reads the byte order mark, accepts `,` and `;` as the separator, sends only the columns of
  the dataset, refuses a file with a missing header before any call, and fills trailing zeros of a number
  (`12.5` becomes `12.50`) without ever rounding. Each chunk is first sent as a **dry run** (a figure that is
  an estimate), then for real with its own `Idempotency-Key`; a 10,000-row file is 40 calls of the 120 an hour.
- **Answer:** `imported`, `skipped` and `problems[]` of `{row, code, attr}`. A skipped row is always listed.
  The app words the codes it knows (`required` on `date` is "the date is missing", `invalid_amount`,
  `duplicate`, `unknown_category`, `unknown_account`, the limit codes) and shows any other as a generic reason
  with the row number. An import never creates an account or a category, and a record equal to an existing
  one is skipped as `duplicate`, counted by multiplicity.

## 8. For the privacy policy and the store forms

New data the server keeps, to add to the wording of [`backend-api.md`](backend-api.md), section 7:

- **Transactions, debts and their notes:** amounts, dates, notes, categories and accounts; the name of a
  **third party** in a debt (`person`). They are deleted with the account, which deletes everything for good.
- **Sessions:** the device name (a model name, never a name the person gave), platform, system and app
  versions, how the session started, and the **network of the sign-in cut to /24 (IPv4) or /48 (IPv6)**,
  never a full address and no user agent. An active session lives at most 90 days and an ended one is kept 90
  days after it ended, so 180 days in the worst case.
- **Security activity:** account events (sign-ins, password and email changes, fingerprint keys, exports and
  imports) with the device label, no address, amounts or notes; kept 90 days.
- **Export:** the owner is told by email that an export was made. Nothing of the content is logged.

## 9. New codes the app words

| Code | Where | What the app does |
| --- | --- | --- |
| `throttled` | any call | countdown from `Retry-After` on the control |
| `request_too_large` | any write | generic failure with the reference |
| `invalid_characters` | text field | message under the field (the app strips these characters first) |
| `name_taken`, `*_limit_reached` | forms | message under the name, or a limit message |
| `account_has_transactions`, `category_is_builtin` | accounts, categories | explanatory message |
| `category_not_allowed`, `does_not_exist`, `date_out_of_range` | transaction form | message under the field |
| `exceeds_remaining`, `amount_below_repaid`, `due_before_start`, `repayment_before_start`, `start_after_repayment` | debt forms | message under the field, with the remaining amount for the first |
| `session_limit_reached` | any call | final: sign-in with the reason "too many devices" |
| `unknown_category`, `unknown_account`, `duplicate` | import result | reason beside the row number |

The to-do lines are the "Money data step" block in section 7 of [`steps.md`](steps.md).
