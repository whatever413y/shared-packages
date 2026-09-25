/// A line item added to a bill on top of room and electricity charges (negative amounts are discounts).
class AdditionalCharge {
  final int amount;
  final String description;

  const AdditionalCharge({required this.amount, required this.description});

  factory AdditionalCharge.fromJson(Map<String, dynamic> json) =>
      AdditionalCharge(amount: (json['amount'] as num).toInt(), description: json['description'] as String);

  Map<String, dynamic> toJson() => {'amount': amount, 'description': description};
}
