# m18_residences_shared

Shared code for the two M18 Residences Flutter web apps (admin: `m18-residences-admin`, tenant: `m18-residences-tenant`):

- **Uploads** (web): `pickFile` (a plain file input that works on iPhone/iPad Safari), `prepareReceipt` (images shrunk to ≤ 1600 px and re-encoded as WebP, JPEG where the browser can't; HEIC decoded by the bundled [heic-to](assets/heic-to/README.md), LGPL-3.0, loaded only when needed; PDFs as-is), `prepareQrPng`, `sniffReceiptType`. Outside a browser they throw `UnsupportedError`.
- **Models** that mirror the API's JSON (`Room`, `Tenant`, `Reading`, `Bill`, `AdditionalCharge`, `SignedFile` = a signed link plus its content type, `PaymentImage`) and request bodies (`RoomRequest`, `TenantRequest`, `ReadingRequest`, `BillRequest`).
- **API layer**: `ApiClient` + `AuthApi`, `BillApi`, `RoomApi`, `TenantApi`, `ReadingApi`, `PaymentApi` (admin: list and replace the payment QR images). Unexpected statuses throw `ApiException`; admin login 401 → `InvalidCredentialsException`, tenant login 404 → `TenantNotFoundException`, "no bill" 404 → `null`.
- **Widgets**: `AppTheme`, `LoadingOverlay`, `CustomTextFormField`, `CustomDropdownForm`, `CustomAppBar`, `ErrorView`, `SignedImageDialog` (shows an image, or offers to open a PDF in a new tab; Save downloads it, WebP/AVIF/GIF as JPEG; Open in new tab; Close), `BillFileButton` ("View receipt" / "View payment": opens the file in `SignedImageDialog`, never shows its name or link), `BillStatusChip` (`Bill.status`: Unpaid, For verification, Paid), `showSelectableDialog` (a dialog whose text can be selected; pages get the same from `AppTheme`'s `SelectablePageTransitionsBuilder`), and `LogoutScope` (wrap `MaterialApp` in it to give the app bar/error view the app's logout action). Responsive helpers: `WindowSize` (compact < 600 ≤ medium < 1024 ≤ expanded) and `context.windowSize`, `ResponsiveBuilder` (picks a layout from the parent's width), `ResponsiveCenter` (caps content at 1200 px).

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
