import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../helpers/api_helper.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final int? customerId; 
  const AddEditCustomerScreen({super.key, this.customerId});
  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isLoadingData = false;

  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _incomeController = TextEditingController(); 
  final _dpController = TextEditingController();     
  final _dependentsController = TextEditingController(); 
  final _installmentController = TextEditingController(); 
  final _latePayController = TextEditingController();     

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    setState(() { _isLoadingData = true; });
    try {
      final headers = await getApiHeaders();
      final response = await http.get(Uri.parse('$baseUrl/customers/${widget.customerId}'), headers: headers);
      if (!mounted) return; 
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final cust = data['customer'];
        final evals = data['evaluations'];

        _nameController.text = cust['name'];
        _nikController.text = cust['nik'];
        _phoneController.text = cust['phone'] ?? '';
        _incomeController.text = evals['1']?.toString() ?? '0';
        _dpController.text = evals['2']?.toString() ?? '0';
        _dependentsController.text = evals['3']?.toString() ?? '0';
        _installmentController.text = evals['4']?.toString() ?? '0';
        _latePayController.text = evals['5']?.toString() ?? '0';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      if (mounted) setState(() { _isLoadingData = false; });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; });

    final payload = {
      'name': _nameController.text, 'nik': _nikController.text, 'phone': _phoneController.text,
      'evaluations': {
        '1': double.tryParse(_incomeController.text) ?? 0, '2': double.tryParse(_dpController.text) ?? 0,
        '3': double.tryParse(_dependentsController.text) ?? 0, '4': double.tryParse(_installmentController.text) ?? 0,
        '5': double.tryParse(_latePayController.text) ?? 0,
      }
    };

    try {
      final headers = await getApiHeaders();
      http.Response response;
      if (widget.customerId == null) {
        response = await http.post(Uri.parse('$baseUrl/customers'), headers: headers, body: json.encode(payload));
      } else {
        response = await http.put(Uri.parse('$baseUrl/customers/${widget.customerId}'), headers: headers, body: json.encode(payload));
      }

      if (!mounted) return; 

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data disimpan!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorData['message'] ?? 'Error'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error jaringan: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        title: Text(widget.customerId == null ? 'Tambah Nasabah Baru' : 'Edit Data Nasabah', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingData ? const Center(child: CircularProgressIndicator()) : _buildForm(),
    );
  }

  Widget _buildForm() {
    return _isSubmitting ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              widget.customerId == null ? Icons.person_add_alt_1 : Icons.manage_accounts, 
              size: 64, 
              // PERBAIKAN: Menggunakan withValues(alpha: ...)
              color: Colors.indigo.withValues(alpha: 0.8)
            ),
            const SizedBox(height: 16),
            Text(
              widget.customerId == null ? 'Lengkapi Data Nasabah' : 'Perbarui Data Nasabah',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 32),

            _buildSectionCard(
              title: 'Profil Identitas',
              icon: Icons.badge_outlined,
              children: [
                _buildTextField(_nameController, 'Nama Lengkap (Sesuai KTP)', Icons.person),
                _buildTextField(_nikController, 'Nomor Induk Kependudukan (NIK)', Icons.credit_card, isNumber: true),
                _buildTextField(_phoneController, 'Nomor Handphone', Icons.phone_android, isNumber: true),
              ],
            ),
            
            const SizedBox(height: 24),

            _buildSectionCard(
              title: 'Penilaian Finansial (MARCOS)',
              icon: Icons.analytics_outlined,
              children: [
                _buildTextField(_incomeController, 'Pendapatan Bersih / Bulan (Juta)', Icons.account_balance_wallet, isNumber: true),
                _buildTextField(_dpController, 'Kesanggupan Uang Muka / DP (Juta)', Icons.savings, isNumber: true),
                _buildTextField(_dependentsController, 'Jumlah Tanggungan Keluarga (Orang)', Icons.family_restroom, isNumber: true),
                _buildTextField(_installmentController, 'Sisa Cicilan di Tempat Lain (Juta)', Icons.receipt_long, isNumber: true),
                _buildTextField(_latePayController, 'Riwayat Telat Bayar (Total Bulan)', Icons.history_edu, isNumber: true),
              ],
            ),

            const SizedBox(height: 32),

            Container(
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  // PERBAIKAN: Menggunakan withValues(alpha: ...)
                  BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitData,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text('Simpan & Analisis Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller, 
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.indigo[300]),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          filled: true, 
          fillColor: Colors.grey.shade50,
        ),
        validator: (value) => (value == null || value.isEmpty) ? '$label tidak boleh kosong' : null,
      ),
    );
  }
}