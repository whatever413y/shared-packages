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
