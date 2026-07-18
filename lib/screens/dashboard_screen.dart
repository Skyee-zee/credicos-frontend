import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../helpers/api_helper.dart';
import '../models/customer_rank.dart';
import 'add_edit_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'login_screen.dart';

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
      
      if (!mounted) return; 

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() { 
            rankings = (data['data'] as List).map((i) => CustomerRank.fromJson(i)).toList(); 
            isLoading = false; 
          });
        }
      } else if (response.statusCode == 400) {
        setState(() { 
          rankings = []; 
          errorMessage = ''; 
          isLoading = false; 
        });
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
        title: const Text('CrediCos Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Container(
              decoration: BoxDecoration(
                // PERBAIKAN: Menggunakan withValues(alpha: ...)
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: fetchMarcosRankings,
                tooltip: 'Muat Ulang',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 16.0, left: 4.0),
            child: Container(
              decoration: BoxDecoration(
                // PERBAIKAN: Menggunakan withValues(alpha: ...)
                color: Colors.redAccent.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Keluar',
              ),
            ),
          ),
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
    
    if (rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Belum ada data evaluasi nasabah.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

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