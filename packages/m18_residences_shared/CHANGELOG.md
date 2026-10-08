## 0.9.0

* **Breaking:** bill files are opened by bill id: `AuthApi.signedBillFileUrl(billId, kind)` replaces `signedReceiptUrl` and `signedTenantPaymentUrl`, so a renamed tenant or a bill moved to another tenant keeps its files. `BillFileButton` takes `billId` and a `fetchSignedFile(billId, kind)`; `tenantName` is now optional (the dialog's title and the saved file's name). `BillFileKind` moved to the models (`subject` only); its icon is the `BillFileKindIcon` extension, so `kind.icon` still works.
* Logins: `adminLogin` and `tenantLogin` take an optional `turnstileToken`. The server's login guards map to `TooManyAttemptsException` (HTTP 429, too many attempts from this client) and `VerificationFailedException` (400: the captcha wasn't accepted; 503, `unavailable`: Cloudflare couldn't be reached).
* Cloudflare Turnstile: `TurnstileField` (always visible, flexible width, 65 px high, light or dark with the app; test id `turnstile`) with a `TurnstileController` (`token`, single use: `reset()` after every attempt; `error` when the widget can't load). The site key is `TurnstileConfig.siteKey`, the build's `TURNSTILE_SITE_KEY` (a clear `StateError` when missing). The widget's script loads from challenges.cloudflare.com when a login page shows it.
* Bills: `BillApi.list({since, year, tenantId, roomId})` (every filter given must match; `since` also returns every bill without a receipt) and `BillApi.years()`; `ApiClient.get` takes `query` parameters. Contract fixture `bill_years.json`.

## 0.8.0

* Modals: `showAppModal` shows an `AppModal` as a bottom sheet on phones (lifted above the keyboard) and as a centered dialog on wider windows, its text selectable either way. `AppModal` has a tinted header band (`tint`, default the primary color; optional icon tile, overline, title, subtitle, trailing widget, and the only "Close" button, with the sheet's drag handle), a scrolling body and a footer strip for actions. `AppModalSection` groups a body's content under a label on a soft panel.
* `CloseCircleButton`: the round close button of modals, toasts ("Dismiss") and `SignedImageDialog` (a soft filled circle with a thin X, darker on hover, a focus ring, a 48 px target).
* **Breaking:** payment methods replace the fixed payment images. `PaymentMethod` (`id`, `name`, `accountName`, `accountNumber`, `sortOrder`, `hasImage`, `slug`) replaces `PaymentImage`; `PaymentApi` lists (for everyone logged in), creates, updates and deletes them, and uploads and removes their QR images (`PaymentMethodRequest`); `AuthApi.signedPaymentMethodUrl(id)` replaces `signedPaymentUrl(name)`. Contract fixtures `payment_methods.json` and `payment_method.json` replace `payments.json`.
* Light/dark switch: `ThemeModeController` (saved in the browser as `theme_mode`; follows the system until switched, and again once switched back to the system's look), `ThemeModeScope`, `ThemeModeButton` (test id `theme-toggle`), `ThemeModeTile`, and `RailBrand` (the logo, the app's name and the switch for an `AdaptiveScaffold` rail).
* Large screens: `WindowSize.large` (from 1600 px; `isExpanded` stays true) and `WindowSize.contentMaxWidth`; `ResponsiveCenter` caps content at 1200 px, or 1600 px on large screens, unless given a `maxWidth`.
* A disabled `FilledButton`/`ElevatedButton` (e.g. Save before anything changed) has a visible fill and outline in both themes. `BillFileButton` has `iconOnly` and `label`. `prepareQrPng` puts QR images on white (a transparent QR code would vanish on a dark panel).
* Toasts: `AppToast.show(context, message, type: ToastType.success|error|info|loading, title:)` / `AppToast.hide()`: a card at the top (top-right on wider windows), one at a time, announced to screen readers. Success and info close after 4 s (paused on hover), loading toasts when replaced, errors only when dismissed. The unused `snackBarTheme` is gone.
* `SignedImageDialog` restyled (icon and title header, the image on a neutral panel, max 760 px wide); the "More" sheet has a title; `AppTheme` styles the date picker.

## 0.7.0

* **Breaking (redesign):** `AppTheme.lightTheme` and `AppColors` are replaced by `AppTheme.light` and `AppTheme.dark` (deep teal `AppTheme.brand` on slate surfaces, Material 3 `ColorScheme`s, flat bordered cards). Use both with `themeMode: ThemeMode.system`. The font is Inter (SIL OFL), bundled as a subset (Latin, punctuation, ₱; ~60 KB per weight).
* `StatusColors` (a `ThemeExtension`): the Unpaid / For verification / Paid colors for light and dark; `BillStatusChip` uses them (new `large`, `BillStatusChip.icon`).
* New widgets: `AdaptiveScaffold` + `AdaptiveDestination` (bottom bar with a "More" sheet on phones, a rail on tablets, an extended rail on desktops; badges), `AppSection`, `EmptyState`, `BrandMark`, `MoneyText`; `formatPeso` and `formatCount`.
* `BrandMark` draws the apps' logo (the roofline M: two house gables) instead of the text "M18"; the apps' web icons use the same mark.
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
