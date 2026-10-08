# m18_residences_shared

Shared code for the two M18 Residences Flutter web apps (admin: `m18-residences-admin`, tenant: `m18-residences-tenant`):

- **Uploads** (web): `pickFile` (a plain file input that works on iPhone/iPad Safari), `prepareReceipt` (images shrunk to ≤ 1600 px and re-encoded as WebP, JPEG where the browser can't; HEIC decoded by the bundled [heic-to](assets/heic-to/README.md), LGPL-3.0, loaded only when needed; PDFs as-is), `prepareQrPng`, `sniffReceiptType`. Outside a browser they throw `UnsupportedError`.
- **Models** that mirror the API's JSON (`Room`, `Tenant`, `Reading`, `Bill`, `AdditionalCharge`, `SignedFile` = a signed link plus its content type, `PaymentMethod`) and request bodies (`RoomRequest`, `TenantRequest`, `ReadingRequest`, `BillRequest`, `PaymentMethodRequest`).
- **API layer**: `ApiClient` + `AuthApi`, `BillApi`, `RoomApi`, `TenantApi`, `ReadingApi`, `PaymentApi` (payment methods: listed for everyone logged in; the admin adds, edits and deletes them and uploads or removes their QR images, opened with `AuthApi.signedPaymentMethodUrl`). `BillApi.list` filters by `since` (plus every open bill), `year`, `tenantId`, `roomId`; `BillApi.years()`. Bill files open by bill id (`AuthApi.signedBillFileUrl`). Unexpected statuses throw `ApiException`; admin login 401 → `InvalidCredentialsException`, tenant login 404 → `TenantNotFoundException`, either login 429 → `TooManyAttemptsException`, 400/503 → `VerificationFailedException` (the captcha), "no bill" 404 → `null`.
- **Theme**: `AppTheme.light` / `AppTheme.dark` (teal `AppTheme.brand` on slate, Inter bundled as a font asset, SIL OFL: `assets/fonts/inter/OFL.txt`), `StatusColors` (Unpaid / For verification / Paid colors per brightness), `AppTheme.tabularFigures`, `AppTheme.panelColor` / `softPanelColor` / `footerColor` / `modalBandColor`. The light/dark switch: `ThemeModeController.load()` before `runApp`, a `ThemeModeScope` around `MaterialApp` (`themeMode: ThemeModeScope.of(context).value`), and `ThemeModeButton` / `ThemeModeTile` / `RailBrand` where it is switched.
- **Layout**: `AdaptiveScaffold` (bottom bar with "More" on phones, rail on tablets, extended rail on desktops; wrap each kept-alive page in `SelectablePage`), `RailBrand`, `AppSection`, `EmptyState`, `BrandMark`, `MoneyText` / `formatPeso` / `formatCount`.
- **Modals and toasts**: `showAppModal` + `AppModal` (bottom sheet on phones, dialog otherwise; a tinted header band, `AppModalSection`s in the body, a footer strip; use it for every form, details view and confirmation), `AppToast` (top cards; `ToastType.success`/`error`/`info`/`loading`), `CloseCircleButton` (their round close button).
- **Widgets**: `LoadingOverlay`, `CustomTextFormField`, `CustomDropdownForm`, `CustomAppBar`, `ErrorView`, `SignedImageDialog` (shows an image, or offers to open a PDF in a new tab; Save downloads it, WebP/AVIF/GIF as JPEG; Open in new tab; Close), `BillFileButton` ("View receipt" / "View payment": opens the bill's file in `SignedImageDialog`, never shows its name or link), `TurnstileField` + `TurnstileController` (Cloudflare Turnstile on the login pages; site key `TURNSTILE_SITE_KEY` at build time), `BillStatusChip` (`Bill.status`: Unpaid, For verification, Paid), `showSelectableDialog` (a dialog whose text can be selected; pages get the same from `AppTheme`'s `SelectablePageTransitionsBuilder`), and `LogoutScope` (wrap `MaterialApp` in it to give the app bar/error view the app's logout action). Responsive helpers: `WindowSize` (compact < 600 ≤ medium < 1024 ≤ expanded < 1600 ≤ large; `isExpanded` covers large too) and `context.windowSize`, `ResponsiveBuilder` (picks a layout from the parent's width), `ResponsiveCenter` (caps content at 1200 px, 1600 px on large screens).

Server timestamps are UTC without a zone; `Bill.createdAt` and `Reading.createdAt` are parsed as UTC and returned in
local time.

## Configuration

The API base URL is compiled in: `--dart-define-from-file=.env` (a file with `API_URL=http://localhost:50000/api`) or `--dart-define=API_URL=...`. `ApiConfig.baseUrl` throws a clear `StateError` if it is missing.

For browser e2e builds, pass `--dart-define=E2E=true` in the app and give widgets a `semanticsId` (rendered as `flt-semantics-identifier`).

## Using it from an app

```yaml
dependencies:
  m18_residences_shared:
    git:
      url: https://github.com/whatever413y/shared-packages.git
      path: packages/m18_residences_shared
      ref: m18_residences_shared-v0.6.0
```

For local work next to a checkout of this repo, add a gitignored `pubspec_overrides.yaml` to the app:

```yaml
dependency_overrides:
  m18_residences_shared:
    path: ../shared-packages/packages/m18_residences_shared
```

## Development

```sh
flutter pub get
dart format lib test        # 150 columns, configured in analysis_options.yaml
flutter analyze
flutter test
```

`test/fixtures/` holds API responses (synthetic data) for the contract tests. Regenerate them from the server repo when the API changes:
`$env:FIXTURES_OUT='<path-to-this-package>/test/fixtures'; cargo test export_contract_fixtures -- --ignored`.
