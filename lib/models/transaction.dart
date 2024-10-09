class Transaction {
  final String id;
  final String date;
  final double totalAmount;
  final String paymentMethod;
  final String status;

  Transaction({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
  });

  // Factory method to create a Transaction from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      date: json['date'],
      totalAmount: json['totalAmount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      status: json['status'],
    );
  }
}
