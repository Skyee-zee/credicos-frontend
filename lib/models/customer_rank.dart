class CustomerRank {
  final int customerId;
  final String name;
  final String nik;
  final double marcosScore;

  CustomerRank({
    required this.customerId, 
    required this.name, 
    required this.nik, 
    required this.marcosScore
  });

  factory CustomerRank.fromJson(Map<String, dynamic> json) {
    return CustomerRank(
      customerId: json['customer_id'], 
      name: json['name'], 
      nik: json['nik'], 
      marcosScore: (json['marcos_score'] as num).toDouble(),
    );
  }
}