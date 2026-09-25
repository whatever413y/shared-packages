# m18_shared

Shared code for the two M18 Residences Flutter web apps (admin: `M18-Residences-Admin`, tenant: `M18-Residences`):

- **Models** that mirror the API's JSON (`Room`, `Tenant`, `Reading`, `Bill`, `AdditionalCharge`) and request bodies (`RoomRequest`, `TenantRequest`, `ReadingRequest`, `BillRequest`).
- **API layer**: `ApiClient` + `AuthApi`, `BillApi`, `RoomApi`, `TenantApi`, `ReadingApi`. Unexpected statuses throw `ApiException`; admin login 401 → `InvalidCredentialsException`, tenant login 404 → `TenantNotFoundException`, "no bill" 404 → `null`.
- **Widgets**: `AppTheme`, `LoadingOverlay`, `CustomTextFormField`, `CustomDropdownForm`, `CustomAppBar`, `ErrorView`, `SignedImageDialog`, `ReceiptLink`, and `LogoutScope` (wrap `MaterialApp` in it to give the app bar/error view the app's logout action).

## Configuration

The API base URL is compiled in: `--dart-define-from-file=.env` (a file with `API_URL=http://localhost:50000/api`) or `--dart-define=API_URL=...`. `ApiConfig.baseUrl` throws a clear `StateError` if it is missing.

For browser e2e builds, pass `--dart-define=E2E=true` in the app and give widgets a `semanticsId` (rendered as `flt-semantics-identifier`).

## Using it from an app

```yaml
dependencies:
  m18_shared:
    git:
      url: https://github.com/whatever413y/shared-packages.git
      path: packages/m18_shared
      ref: m18_shared-v0.1.0
```

For local work next to a checkout of this repo, add a gitignored `pubspec_overrides.yaml` to the app:

```yaml
dependency_overrides:
  m18_shared:
    path: ../shared-packages/packages/m18_shared
```

## Development

```sh
flutter pub get
dart format lib test        # 150 columns, configured in analysis_options.yaml
flutter analyze
flutter test
```

`test/fixtures/` holds real API responses for the contract tests. Regenerate them from the server repo when the API changes:
`$env:FIXTURES_OUT='<path-to-this-package>/test/fixtures'; cargo test export_contract_fixtures -- --ignored`.
