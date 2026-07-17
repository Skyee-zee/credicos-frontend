import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CredicosApp());
}

// URL API Global (Ubah sesuai environment Anda)
const String baseUrl = 'http://10.0.2.2:8000/api';

class CredicosApp extends StatelessWidget {
  const CredicosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrediCos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(elevation: 0, backgroundColor: Colors.indigo, centerTitle: true),
      ),
      home: const SplashScreen(), // Memulai dari Pengecekan Login
    );
  }
}

// ==========================================
// 1. SPLASH SCREEN (Cek Status Login)
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    await Future.delayed(const Duration(seconds: 2)); // Efek loading sebentar
    
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.real_estate_agent, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text('CrediCos', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Sistem Keputusan Kredit MARCOS', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. LOGIN SCREEN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Simpan token ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['access_token']);
        
        if (!mounted) return; // Tambahan aman
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Login Gagal'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Koneksi Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text('Login Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 40),
              _isLoading 
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _login,
                      child: const Text('Masuk', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. FUNGSI HELPER UNTUK HEADER API
// ==========================================
Future<Map<String, String>> getApiHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token', 
  };
}

// ==========================================
// 4. DATA MODEL & DASHBOARD SCREEN
// ==========================================
class CustomerRank {
  final int customerId;
  final String name;
  final String nik;
  final double marcosScore;

  CustomerRank({required this.customerId, required this.name, required this.nik, required this.marcosScore});

  factory CustomerRank.fromJson(Map<String, dynamic> json) {
    return CustomerRank(
      customerId: json['customer_id'], name: json['name'], nik: json['nik'], marcosScore: (json['marcos_score'] as num).toDouble(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<CustomerRank> rankings = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchMarcosRankings();
  }

  Future<void> fetchMarcosRankings() async {
    setState(() { isLoading = true; errorMessage = ''; });
    try {
      final headers = await getApiHeaders();
      final response = await http.get(Uri.parse('$baseUrl/marcos/calculate'), headers: headers);
      
      // PERBAIKAN: Mencegah error build_context_synchronously di baris 116
      if (!mounted) return; 

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() { rankings = (data['data'] as List).map((i) => CustomerRank.fromJson(i)).toList(); isLoading = false; });
        }
      } else if (response.statusCode == 401) {
        _forceLogout(); 
      } else {
        setState(() { errorMessage = 'Error: ${response.statusCode}'; isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { errorMessage = 'Koneksi gagal: $e'; isLoading = false; });
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      final headers = await getApiHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/customers/$id'), headers: headers);
      if (!mounted) return;
      if (response.statusCode == 200) {
        fetchMarcosRankings();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nasabah dihapus'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus'), backgroundColor: Colors.red));
    }
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  Future<void> _logout() async {
    try {
      final headers = await getApiHeaders();
      await http.post(Uri.parse('$baseUrl/logout'), headers: headers);
    } catch (e) { /* Abaikan error koneksi saat logout */ }
    _forceLogout();
  }

  void _showDeleteDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Nasabah?'), content: Text('Apakah Anda yakin ingin menghapus data $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(onPressed: () { Navigator.pop(ctx); deleteCustomer(id); }, child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CrediCos Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchMarcosRankings),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditCustomerScreen()));
          if (result == true) fetchMarcosRankings();
        },
        backgroundColor: Colors.indigo, child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage.isNotEmpty) return Center(child: Text(errorMessage));
    if (rankings.isEmpty) return const Center(child: Text('Belum ada data.'));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final customer = rankings[index];
        final isTopRank = index == 0;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: isTopRank ? 4 : 1,
          shape: RoundedRectangleBorder(side: isTopRank ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0, right: 4.0),
            leading: CircleAvatar(
              backgroundColor: isTopRank ? Colors.amber : Colors.indigo[100],
              foregroundColor: isTopRank ? Colors.white : Colors.indigo,
              radius: 25, child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('Skor: ${customer.marcosScore.toStringAsFixed(4)}'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerDetailScreen(customerId: customer.customerId, marcosScore: customer.marcosScore)));
            },
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditCustomerScreen(customerId: customer.customerId)));
                  if (result == true) fetchMarcosRankings();
                } else if (value == 'delete') {
                  _showDeleteDialog(customer.customerId, customer.name);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Data')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus Data', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 5. ADD / EDIT CUSTOMER SCREEN
// ==========================================
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
      appBar: AppBar(title: Text(widget.customerId == null ? 'Tambah Nasabah' : 'Edit Nasabah')),
      body: _isLoadingData ? const Center(child: CircularProgressIndicator()) : _buildForm(),
    );
  }

  Widget _buildForm() {
    return _isSubmitting ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profil Nasabah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            _buildTextField(_nameController, 'Nama Lengkap', Icons.person),
            _buildTextField(_nikController, 'NIK', Icons.badge, isNumber: true),
            _buildTextField(_phoneController, 'No. HP', Icons.phone, isNumber: true),
            const SizedBox(height: 24),
            const Text('Data Evaluasi Kredit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            _buildTextField(_incomeController, 'Pendapatan per Bulan (Juta)', Icons.attach_money, isNumber: true),
            _buildTextField(_dpController, 'Uang Muka / DP (Juta)', Icons.account_balance_wallet, isNumber: true),
            _buildTextField(_dependentsController, 'Jumlah Tanggungan (Orang)', Icons.family_restroom, isNumber: true),
            _buildTextField(_installmentController, 'Sisa Cicilan Lain (Juta)', Icons.credit_card, isNumber: true),
            _buildTextField(_latePayController, 'Riwayat Telat Bayar (Bulan)', Icons.history, isNumber: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo), onPressed: _submitData, child: const Text('Simpan Data', style: TextStyle(fontSize: 16, color: Colors.white))),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.indigo), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white),
        validator: (value) => (value == null || value.isEmpty) ? '$label tidak boleh kosong' : null,
      ),
    );
  }
}

// ==========================================
// 6. CUSTOMER DETAIL SCREEN
// ==========================================
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