/// The two files a bill can have.
enum BillFileKind {
  /// The owner's receipt; makes the bill paid.
  receipt('receipt'),

  /// The tenant's proof of payment.
  payment('payment');

  /// Used in texts ("View receipt", "Error loading payment: ..."), saved file names and the API path
  /// (`/signed-urls/bills/<id>/<subject>`).
  final String subject;

  const BillFileKind(this.subject);
}
