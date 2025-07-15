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
  int maxInstNo = 1;
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
      final maxInst = collections
          .map((c) => c['inst_no'] ?? 0)
          .fold<int>(0, (a, b) => a > b ? a : b);
      maxInstNo = maxInst + 1;
    });
  }

  Future<bool> submitCollection(Map<String, dynamic> data) async {
    final url = Uri.parse(
      'https://darktechteam.com/realestate/api/create_collection',
    );

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(data),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final responseBody = jsonDecode(res.body);
        if (responseBody.containsKey('id')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseBody['message'] ?? 'Collection added successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          return true;
        } else {
          final errorMsg = responseBody['message'] ?? "Unknown error";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
          return false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${res.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
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
      "p_id": findFlat['pId'],
      "f_id": findFlat['fId'],
      "inst_no": payType == 1 ? maxInstNo : 0,
      "inst_date": instDate,
      "p_type": payType,
      "mr_no": maxMrNo,
      "mr_date": mrDate,
      "mr_amt": int.parse(amount),
      "comp_id": compId,
    };

    final success = await submitCollection(payload);

    setState(() => loading = false);

    if (success) {
      setState(() {
        collections.add(payload);
        amount = "";
        mrInputValue = "";
        payType = 1;
        instDate = DateTime.now().toIso8601String().split("T")[0];
        mrDate = DateTime.now().toIso8601String().split("T")[0];
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        Navigator.pop(context); // 👈 Navigate back
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectController = TextEditingController(
      text: "${findFlat['pId'] ?? ''} - ${findFlat['pName'] ?? ''}",
    );
    final flatController = TextEditingController(
      text: "${findFlat['fId'] ?? ''} - ${findFlat['fLoc'] ?? ''}",
    );
    final dueController = TextEditingController(text: remainingDue.toString());
    final installmentController = TextEditingController(
      text: "${findFlat['amt_per_inst'] ?? ''}",
    );
    final paymentModeController = TextEditingController(
      text: "${findFlat['payMode'] ?? ''}",
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Collection Entry"),
        backgroundColor: Colors.teal[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildClientDropdown(),
                  if (findFlat.isNotEmpty)
                    _buildForm(
                      projectController,
                      flatController,
                      dueController,
                      installmentController,
                      paymentModeController,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildClientDropdown() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<int>(
          value: selectedClient,
          items: clients
              .map<DropdownMenuItem<int>>(
                (c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(
                    "${c['client_id']} - ${c['name']} - ${c['mobile']}",
                  ),
                ),
              )
              .toList(),
          onChanged: updateClientDetails,
          decoration: InputDecoration(
            labelText: "Select Client",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    TextEditingController projectController,
    TextEditingController flatController,
    TextEditingController dueController,
    TextEditingController installmentController,
    TextEditingController paymentModeController,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _readOnlyFieldWithController("Project", projectController),
            _readOnlyFieldWithController("Flat", flatController),
            _readOnlyFieldWithController("Due", dueController),
            _readOnlyFieldWithController("Installment", installmentController),
            _readOnlyFieldWithController("Payment Mode", paymentModeController),
            DropdownButtonFormField<int>(
              value: payType,
              decoration: InputDecoration(
                labelText: "Payment Type",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text("Installment")),
                DropdownMenuItem(value: 2, child: Text("Booking Money")),
                DropdownMenuItem(value: 3, child: Text("Down Payment")),
              ],
              onChanged: (val) => setState(() => payType = val ?? 1),
            ),
            const SizedBox(height: 16),
            if (payType == 1) _readOnlyField("Inst. No", "$maxInstNo"),
            _textField(
              "Inst. Date",
              instDate,
              (val) => setState(() => instDate = val),
            ),
            _readOnlyField("MR No", maxMrNo),
            _textField(
              "MR Amount",
              amount,
              (val) => setState(() => amount = val),
              type: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: loading ? null : handleSubmit,
                  child: Text(loading ? "Saving..." : "Submit"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      amount = "";
                      mrInputValue = "";
                      payType = 1;
                      instDate = DateTime.now().toIso8601String().split("T")[0];
                      mrDate = DateTime.now().toIso8601String().split("T")[0];
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Cancel"),
                ),
              ],
            ),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        readOnly: true,
        initialValue: value,
      ),
    );
  }

  Widget _readOnlyFieldWithController(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        keyboardType: type,
        initialValue: value,
        onChanged: onChanged,
      ),
    );
  }
}
