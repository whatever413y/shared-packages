## 0.1.0

* Initial release, extracted from the M18 Residences admin and tenant apps:
  * Models matching the API JSON: `Room`, `Tenant`, `Reading`, `Bill` (with nested reading), `AdditionalCharge`, plus request bodies.
  * API layer: `ApiClient` (one auth-header path, `ApiException` on unexpected statuses), `AuthApi`, `BillApi`, `RoomApi`, `TenantApi`, `ReadingApi`, `TokenStore`; base URL from `--dart-define API_URL`.
  * Widgets: `AppTheme`, `LoadingOverlay`, `CustomTextFormField`, `CustomDropdownForm`, `CustomAppBar`, `ErrorView`, `LogoutScope`, `SignedImageDialog`, `ReceiptLink`.
