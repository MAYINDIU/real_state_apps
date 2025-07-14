import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CollectionEntryPage extends StatefulWidget {
  const CollectionEntryPage({super.key});

  @override
  State<CollectionEntryPage> createState() => _CollectionEntryPageState();
}

class _CollectionEntryPageState extends State<CollectionEntryPage> {
  int? selectedClient;
  int payType = 1;
  int maxInstNo = 5;
  String instDate = DateTime.now().toIso8601String().split("T")[0];
  String mrDate = DateTime.now().toIso8601String().split("T")[0];
  String amount = "";
  String mrInputValue = "";
  bool loading = false;

  bool isLoading = true;
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> flats = [];
  List<Map<String, dynamic>> allCollections = [];

  Map<String, dynamic> findFlat = {};
  List<Map<String, dynamic>> collections = [];

  String? authToken;
  int? compId;

  String get maxMrNo => "MR-${collections.length + 10001}";
  String get prevMrNo => "MR-${collections.length + 10000}";
  String get mrPrint => mrInputValue.isEmpty ? prevMrNo : mrInputValue;

  int get remainingDue {
    final totalCollected = collections.fold<num>(
      0,
      (sum, item) => sum + (item['mr_amt'] ?? 0),
    );
    return (findFlat['total_due'] ?? 0) - totalCollected.toInt();
  }

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    compId = prefs.getInt('comp_id');

    if (compId != null) {
      await Future.wait([fetchClients(), fetchFlats(), fetchCollections()]);
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchClients() async {
    final res = await http.get(
      Uri.parse(
        'https://darktechteam.com/realestate/api/all_client?compId=$compId',
      ),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      clients = List<Map<String, dynamic>>.from(data['data']);
    }
  }

  Future<void> fetchFlats() async {
    final res = await http.get(
      Uri.parse(
        'https://darktechteam.com/realestate/api/all_flat_sale?compId=$compId',
      ),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      flats = List<Map<String, dynamic>>.from(data['data']);
    }
  }

  Future<void> fetchCollections() async {
    final res = await http.get(
      Uri.parse(
        'https://darktechteam.com/realestate/api/all_collection?compId=$compId',
      ),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      allCollections = List<Map<String, dynamic>>.from(data['data']);
    }
  }

  void updateClientDetails(int? clientId) {
    setState(() {
      selectedClient = clientId;
      findFlat = flats.firstWhere(
        (flat) => flat['client_id'] == clientId,
        orElse: () => {},
      );
      collections = allCollections
          .where((c) => c['client_id'] == clientId)
          .toList();
    });
  }

  Future<void> handleSubmit() async {
    if (selectedClient == null ||
        amount.isEmpty ||
        int.tryParse(amount) == null ||
        int.parse(amount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete the form.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text('Are you sure you want to add this collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => loading = true);

    final payload = {
      "client_id": selectedClient,
      "p_id": findFlat['p_id'],
      "f_id": findFlat['f_id'],
      "inst_no": payType == 1 ? maxInstNo : 0,
      "inst_date": instDate,
      "p_type": payType,
      "mr_no": maxMrNo,
      "mr_date": mrDate,
      "mr_amt": int.parse(amount),
    };

    // API submission logic here
    await Future.delayed(const Duration(seconds: 1)); // Simulated

    setState(() {
      collections.add(payload);
      amount = "";
      mrInputValue = "";
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Collection added successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Collection Entry")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedClient,
                    items: clients.map<DropdownMenuItem<int>>((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(
                          "${c['client_id']} - ${c['name']} (${c['mobile']})",
                        ),
                      );
                    }).toList(),
                    onChanged: updateClientDetails,
                    decoration: const InputDecoration(
                      labelText: "Select Client",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (findFlat.isNotEmpty) ...[
                    _readOnlyField(
                      "Project",
                      "${findFlat['pId']} - ${findFlat['pName']}",
                    ),
                    _readOnlyField(
                      "Flat",
                      "${findFlat['fId']} - ${findFlat['fLoc']}",
                    ),
                    _readOnlyField("Due", "$remainingDue"),
                    _readOnlyField(
                      "Installment",
                      "${findFlat['amt_per_inst']}",
                    ),
                    _readOnlyField("Payment Mode", "${findFlat['payMode']}"),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "Payment Type",
                        border: OutlineInputBorder(),
                      ),
                      value: payType,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("Installment")),
                        DropdownMenuItem(
                          value: 2,
                          child: Text("Booking Money"),
                        ),
                        DropdownMenuItem(value: 3, child: Text("Down Payment")),
                      ],
                      onChanged: (val) => setState(() => payType = val ?? 1),
                    ),
                    const SizedBox(height: 16),

                    if (payType == 1)
                      _readOnlyField("Installment No", "$maxInstNo"),

                    _textField(
                      "Installment Date",
                      instDate,
                      (val) => instDate = val,
                    ),
                    _readOnlyField("MR No", maxMrNo),
                    _textField(
                      "MR Amount",
                      amount,
                      (val) => amount = val,
                      type: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loading ? null : handleSubmit,
                      child: Text(loading ? "Saving..." : "Submit"),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        readOnly: true,
        initialValue: value,
      ),
    );
  }

  Widget _textField(
    String label,
    String value,
    Function(String) onChanged, {
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: type,
        initialValue: value,
        onChanged: onChanged,
      ),
    );
  }
}
