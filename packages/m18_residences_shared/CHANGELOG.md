## 0.7.0

* **Breaking (redesign):** `AppTheme.lightTheme` and `AppColors` are replaced by `AppTheme.light` and `AppTheme.dark` (deep teal `AppTheme.brand` on slate surfaces, Material 3 `ColorScheme`s, flat bordered cards). Use both with `themeMode: ThemeMode.system`. The font is Inter (SIL OFL), bundled as a subset (Latin, punctuation, ₱; ~60 KB per weight).
* `StatusColors` (a `ThemeExtension`): the Unpaid / For verification / Paid colors for light and dark; `BillStatusChip` uses them (new `large`, `BillStatusChip.icon`).
* New widgets: `AdaptiveScaffold` + `AdaptiveDestination` (bottom bar with a "More" sheet on phones, a rail on tablets, an extended rail on desktops; badges), `AppSection`, `EmptyState`, `BrandMark`, `MoneyText`; `formatPeso` and `formatCount`.
* `SelectablePage`: a page of a navigation shell's `IndexedStack` with its own selection area, so a drag over the visible page never selects a hidden page's text.
* `CustomAppBar` takes its colors from the theme and has `showLeading` (off for pages inside a navigation shell); `ErrorView`, `LoadingOverlay` and `CustomDropdownForm` follow the theme too.

## 0.6.0

* Tenants' payment images (proof of payment): `Bill.paymentUrl`, `hasPayment` and `status` (`BillStatus.unpaid` / `forVerification` / `paid`, with `label`); `BillApi.uploadPayment` (multipart `payment_file`) and `clearPayment`; `AuthApi.signedTenantPaymentUrl`. Contract fixtures regenerated (`payment_url`).
* **Breaking:** `ReceiptLink` is replaced by `BillFileButton` (`kind: BillFileKind.receipt|payment`): a "View receipt" / "View payment" button instead of a link showing the file name or storage key. New `BillStatusChip`.
* The upload helpers moved here from the admin app so both apps use them: `pickFile`, `prepareReceipt`, `prepareQrPng`, `sniffReceiptType`, `PreparedReceipt`, `ReceiptException`; the HEIC decoder is now this package's asset `assets/heic-to/`.
* `ApiClient.delete` returns the decoded body (for `DELETE` routes that answer with JSON).

## 0.5.0

* **Breaking:** `SelectableApp` is gone: one selection area around the whole Navigator also picked up the text of the hidden pages underneath, so text in tables and dialogs couldn't be selected. Instead `AppTheme.lightTheme` gives every page its own `SelectionArea` (`SelectablePageTransitionsBuilder`), and `showSelectableDialog` does the same for dialogs (`SignedImageDialog` uses it).

## 0.4.0

* Responsive helpers: `WindowSize` (compact < 600 ≤ medium < 1024 ≤ expanded), `context.windowSize`, `ResponsiveBuilder`, `ResponsiveCenter` (caps content at 1200 px).
* `SignedImageDialog` has a header with the file's name, Save (downloads it; WebP, AVIF and GIF are converted to JPEG in the browser), Open in new tab and Close; new optional `fileName`, `saveName` and `saveFile`. `saveSignedFile` does the download.
* `ReceiptLink`: `showFullName` shows the whole storage key (`receipts/<tenant>/<file>`); the dialog saves as `receipt-<tenant>-<file>`.
* `SelectableApp`: use as `MaterialApp.builder` to make every text selectable and copyable, dialogs included.
* `PaymentApi` (`list`, `upload`) and `PaymentImage` for the admin's payment QR images (`GET/PUT /api/payments`); contract fixture `payments.json`.
* `Bill.createdAt` and `Reading.createdAt` are parsed as UTC (the server sends UTC without a zone) and returned in local time, instead of being read as local time (8 h off).

## 0.3.0

* For the Workers + D1 server. **Breaking:**
  * `AuthApi.signedReceiptUrl` / `signedPaymentUrl` return a `SignedFile` (`url`, `contentType`, `isPdf`), read from the new `content_type` field.
  * `SignedImageDialog` takes `fetchFile` (a `SignedFile`) instead of `fetchUrl`; `ReceiptLink` takes `fetchSignedFile`. A PDF shows an "Open PDF" button that opens it in a new browser tab; images are shown as before.
  * `BillApi.uploadReceipt` takes the file's `contentType` instead of guessing JPEG/PNG from the file name.
* Contract fixtures regenerated from the new server (whole-second timestamps, `content_type` on signed links).

## 0.2.0

* Renamed from `m18_shared` to `m18_residences_shared` (import `package:m18_residences_shared/m18_residences_shared.dart`; tags `m18_residences_shared-vX.Y.Z`).
* `BillRequest.toMultipartFields()` no longer sends an empty `receipt_url` when there is no receipt (the server treated `''` as a receipt and marked the bill paid).

## 0.1.0

* Initial release, extracted from the M18 Residences admin and tenant apps:
  * Models matching the API JSON: `Room`, `Tenant`, `Reading`, `Bill` (with nested reading), `AdditionalCharge`, plus request bodies.
  * API layer: `ApiClient` (one auth-header path, `ApiException` on unexpected statuses), `AuthApi`, `BillApi`, `RoomApi`, `TenantApi`, `ReadingApi`, `TokenStore`; base URL from `--dart-define API_URL`.
  * Widgets: `AppTheme`, `LoadingOverlay`, `CustomTextFormField`, `CustomDropdownForm`, `CustomAppBar`, `ErrorView`, `LogoutScope`, `SignedImageDialog`, `ReceiptLink`.
