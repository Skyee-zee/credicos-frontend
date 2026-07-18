import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../helpers/api_helper.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final double marcosScore;

  const CustomerDetailScreen({super.key, required this.customerId, required this.marcosScore});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Map<String, dynamic>? customerData;
  Map<String, dynamic>? evaluations;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final headers = await getApiHeaders();
      final response = await http.get(Uri.parse('$baseUrl/customers/${widget.customerId}'), headers: headers);
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() { customerData = data['customer']; evaluations = data['evaluations']; isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat detail: $e')));
        setState(() { isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rincian Nasabah')),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : customerData == null ? const Center(child: Text('Data tidak ditemukan.')) : _buildDetailContent(),
    );
  }

  Widget _buildDetailContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profil Lengkap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const Divider(),
                  _buildDetailRow('Nama', customerData!['name']), _buildDetailRow('NIK', customerData!['nik']), _buildDetailRow('No. HP', customerData!['phone'] ?? '-'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Skor (MARCOS):', style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)),
                        child: Text(widget.marcosScore.toStringAsFixed(4), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rincian Evaluasi Kredit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const Divider(),
                  _buildEvaluationRow('Pendapatan per Bulan', '${evaluations!['1']} Juta', Icons.attach_money),
                  _buildEvaluationRow('Uang Muka / DP', '${evaluations!['2']} Juta', Icons.account_balance_wallet),
                  _buildEvaluationRow('Jumlah Tanggungan', '${evaluations!['3']} Orang', Icons.family_restroom),
                  _buildEvaluationRow('Sisa Cicilan Lain', '${evaluations!['4']} Juta', Icons.credit_card),
                  _buildEvaluationRow('Riwayat Telat Bayar', '${evaluations!['5']} Bulan', Icons.history),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))), const Text(': '), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)))]));
  }
  Widget _buildEvaluationRow(String label, String value, IconData icon) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [Icon(icon, color: Colors.indigo[300], size: 20), const SizedBox(width: 10), Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));
  }
}