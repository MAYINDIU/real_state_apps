import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FlatSalePage extends StatefulWidget {
  const FlatSalePage({super.key});

  @override
  State<FlatSalePage> createState() => _FlatSalePageState();
}

class _FlatSalePageState extends State<FlatSalePage> {
  List<dynamic> sales = [];
  List<dynamic> filteredSales = [];
  String? authToken;
  int compId = 1;
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    compId = prefs.getInt('comp_id') ?? 1;
    await fetchFlatSales();
  }

  Future<void> fetchFlatSales() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse(
        'https://darktechteam.com/realestate/api/all_flat_sale?compId=$compId',
      ),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        sales = jsonData['data'];
        filteredSales = sales;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load flat sales')),
      );
    }
  }

  void _filterSales(String query) {
    setState(() {
      filteredSales = sales.where((sale) {
        final flatId = sale['flat_id'].toString();
        final clientId = sale['client_id'].toString();
        return flatId.contains(query) || clientId.contains(query);
      }).toList();
    });
  }

  Future<void> deleteFlatSale(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this sale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await http.delete(
        Uri.parse('http://localhost:5002/api/plat_sale_delete/$id'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        await fetchFlatSales();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete sale')));
      }
    }
  }

  void _showAddEditBottomSheet({Map? sale}) {
    final isEdit = sale != null;

    final clientIdController = TextEditingController(
      text: sale?['client_id']?.toString() ?? '',
    );
    final flatIdController = TextEditingController(
      text: sale?['flat_id']?.toString() ?? '',
    );
    final sizeController = TextEditingController(
      text: sale?['f_size']?.toString() ?? '',
    );
    final rateController = TextEditingController(
      text: sale?['rate_psqf']?.toString() ?? '',
    );
    final discAmtController = TextEditingController(
      text: sale?['disc_amt']?.toString() ?? '',
    );
    final bookingAmtController = TextEditingController(
      text: sale?['booking_amt']?.toString() ?? '',
    );
    final downAmtController = TextEditingController(
      text: sale?['down_amt']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  isEdit ? 'Edit Flat Sale' : 'Add Flat Sale',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _formInput('Client ID', clientIdController),
                _formInput('Flat ID', flatIdController),
                _formInput('Flat Size', sizeController, number: true),
                _formInput('Rate/Sq.Ft.', rateController, number: true),
                _formInput('Discount Amount', discAmtController, number: true),
                _formInput(
                  'Booking Amount',
                  bookingAmtController,
                  number: true,
                ),
                _formInput('Down Payment', downAmtController, number: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final fSize = int.tryParse(sizeController.text) ?? 0;
                    final rate = int.tryParse(rateController.text) ?? 0;
                    final discAmt = int.tryParse(discAmtController.text) ?? 0;
                    final totalAmt = fSize * rate;
                    final netAmt = totalAmt - discAmt;

                    final payload = {
                      'client_id': int.tryParse(clientIdController.text),
                      'flat_id': int.tryParse(flatIdController.text),
                      'f_size': fSize,
                      'rate_psqf': rate,
                      'disc_amt': discAmt,
                      'booking_amt': int.tryParse(bookingAmtController.text),
                      'down_amt': int.tryParse(downAmtController.text),
                      'total_amt': totalAmt,
                      'net_amt': netAmt,
                      'comp_id': compId,
                    };

                    http.Response response;
                    if (isEdit) {
                      response = await http.patch(
                        Uri.parse(
                          'http://localhost:5002/api/plat_sale_update/${sale!['id']}',
                        ),
                        headers: {
                          'Authorization': 'Bearer $authToken',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(payload),
                      );
                    } else {
                      response = await http.post(
                        Uri.parse(
                          'https://darktechteam.com/realestate/api/create_flat_sale',
                        ),
                        headers: {
                          'Authorization': 'Bearer $authToken',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(payload),
                      );
                    }

                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      Navigator.pop(context);
                      await fetchFlatSales();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Updated successfully'
                                : 'Created successfully',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to save sale')),
                      );
                    }
                  },
                  child: Text(isEdit ? 'UPDATE' : 'SAVE'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _formInput(
    String label,
    TextEditingController controller, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSaleCard(Map sale) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        title: Text(
          'Flat ID: ${sale['flat_id']} | Client: ${sale['client_id']}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Net: ${sale['net_amt']} | Total: ${sale['total_amt']}'),
            Text(
              'Booking Date: ${sale['booking_date']?.toString().substring(0, 10) ?? ''}',
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showAddEditBottomSheet(sale: sale),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteFlatSale(sale['id']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flat Sales')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSales,
                    decoration: const InputDecoration(
                      labelText: 'Search by Flat ID / Client ID',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchFlatSales,
                    child: ListView.builder(
                      itemCount: filteredSales.length,
                      itemBuilder: (context, index) {
                        return _buildSaleCard(filteredSales[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBottomSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
