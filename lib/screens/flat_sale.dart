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
  int? compId;
  String? token;

  List clients = [];
  List projects = [];
  List flats = [];
  List sales = [];

  @override
  void initState() {
    super.initState();
    loadInitial();
  }

  Future<void> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    compId = prefs.getInt('comp_id');

    await Future.wait([
      fetchClients(),
      fetchProjects(),
      fetchFlats(),
      fetchSales(),
    ]);
  }

  Future<void> fetchClients() async {
    final res = await http.get(
      Uri.parse(
        "https://darktechteam.com/realestate/api/all_client?compId=$compId",
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() {
        clients = jsonDecode(res.body)['data'];
      });
    }
  }

  Future<void> fetchProjects() async {
    final res = await http.get(
      Uri.parse(
        "https://darktechteam.com/realestate/api/all_project?compId=$compId",
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() {
        projects = jsonDecode(res.body)['data'];
      });
    }
  }

  Future<void> fetchFlats() async {
    final res = await http.get(
      Uri.parse(
        "https://darktechteam.com/realestate/api/all_flat_plot?compId=$compId",
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() {
        flats = jsonDecode(res.body)['data'];
      });
    }
  }

  Future<void> fetchSales() async {
    final res = await http.get(
      Uri.parse(
        "https://darktechteam.com/realestate/api/all_flat_sale?compId=$compId",
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() {
        sales = jsonDecode(res.body)['data'];
      });
    }
  }

  void openForm({Map? initialData}) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FlatSaleForm(
          token: token!,
          compId: compId!,
          clients: clients,
          projects: projects,
          flats: flats,
          initialData: initialData,
          onSuccess: () async {
            Navigator.pop(context);
            await fetchSales();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flat Sales")),
      body: sales.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final s = sales[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      "Flat: ${s['flat_id']}, Client: ${s['client_id']}",
                    ),
                    subtitle: Text(
                      "Total: ${s['total_amt']} - Due: ${s['total_due']}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => openForm(initialData: s),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FlatSaleForm extends StatefulWidget {
  final String token;
  final int compId;
  final List clients, projects, flats;
  final Map? initialData;
  final VoidCallback onSuccess;

  const FlatSaleForm({
    super.key,
    required this.token,
    required this.compId,
    required this.clients,
    required this.projects,
    required this.flats,
    this.initialData,
    required this.onSuccess,
  });

  @override
  State<FlatSaleForm> createState() => _FlatSaleFormState();
}

class _FlatSaleFormState extends State<FlatSaleForm> {
  final _formKey = GlobalKey<FormState>();

  int? selectedClient;
  int? selectedProject;
  int? selectedFlat;
  String projectLocation = '';
  String bookingDate = '';
  String deliveryDate = '';

  final sizeCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final garageCtrl = TextEditingController();
  final utilityCtrl = TextEditingController();
  final commonCtrl = TextEditingController();
  final othersCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  final bookingCtrl = TextEditingController();
  final downCtrl = TextEditingController();
  final installmentCtrl = TextEditingController();
  final bookingDateCtrl = TextEditingController();
  final deliveryDateCtrl = TextEditingController();
  final projectLocationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().toIso8601String().split('T')[0];
    bookingDate = today;
    deliveryDate = today;
    bookingDateCtrl.text = today;
    deliveryDateCtrl.text = today;
    projectLocationCtrl.text = projectLocation;

    if (widget.initialData != null) {
      final d = widget.initialData!;
      selectedClient = d['client_id'];
      selectedProject = d['project_id'];
      selectedFlat = d['flat_id'];
      sizeCtrl.text = d['f_size'].toString();
      rateCtrl.text = d['rate_psqf'].toString();
      garageCtrl.text = d['garage_chrg'].toString();
      utilityCtrl.text = d['utility_chrg'].toString();
      commonCtrl.text = d['common_chrg'].toString();
      othersCtrl.text = d['others_chrg'].toString();
      discountCtrl.text = d['disc_amt'].toString();
      bookingCtrl.text = d['booking_amt'].toString();
      downCtrl.text = d['down_amt'].toString();
      installmentCtrl.text = d['inst_no'].toString();
      bookingDate = d['booking_date'] ?? today;
      deliveryDate = d['deliv_date'] ?? today;
      bookingDateCtrl.text = bookingDate;
      deliveryDateCtrl.text = deliveryDate;
      projectLocationCtrl.text =
          widget.projects.firstWhere(
            (p) => p['id'] == selectedProject,
            orElse: () => {'location': ''},
          )['location'] ??
          '';
    }
  }

  @override
  void dispose() {
    sizeCtrl.dispose();
    rateCtrl.dispose();
    garageCtrl.dispose();
    utilityCtrl.dispose();
    commonCtrl.dispose();
    othersCtrl.dispose();
    discountCtrl.dispose();
    bookingCtrl.dispose();
    downCtrl.dispose();
    installmentCtrl.dispose();
    bookingDateCtrl.dispose();
    deliveryDateCtrl.dispose();
    projectLocationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController ctrl,
    void Function(String) onPicked,
  ) async {
    final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted = picked.toIso8601String().split('T')[0];
      ctrl.text = formatted;
      onPicked(formatted);
    }
  }

  int get totalRate {
    final size = int.tryParse(sizeCtrl.text) ?? 0;
    final rate = int.tryParse(rateCtrl.text) ?? 0;
    final garage = int.tryParse(garageCtrl.text) ?? 0;
    final utility = int.tryParse(utilityCtrl.text) ?? 0;
    final common = int.tryParse(commonCtrl.text) ?? 0;
    final others = int.tryParse(othersCtrl.text) ?? 0;
    return (size * rate) + garage + utility + common + others;
  }

  int get netPay => totalRate - (int.tryParse(discountCtrl.text) ?? 0);
  int get totalRecv =>
      (int.tryParse(bookingCtrl.text) ?? 0) +
      (int.tryParse(downCtrl.text) ?? 0);
  int get dueAmt => netPay - totalRecv;
  double get perInstallment {
    final inst = int.tryParse(installmentCtrl.text) ?? 0;
    return inst == 0 ? 0 : dueAmt / inst;
  }

  Future<void> handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'client_id': selectedClient,
      'project_id': selectedProject,
      'flat_id': selectedFlat,
      'f_size': int.tryParse(sizeCtrl.text) ?? 0,
      'rate_psqf': int.tryParse(rateCtrl.text) ?? 0,
      'garage_chrg': int.tryParse(garageCtrl.text) ?? 0,
      'utility_chrg': int.tryParse(utilityCtrl.text) ?? 0,
      'common_chrg': int.tryParse(commonCtrl.text) ?? 0,
      'others_chrg': int.tryParse(othersCtrl.text) ?? 0,
      'total_amt': totalRate,
      'disc_amt': int.tryParse(discountCtrl.text) ?? 0,
      'net_amt': netPay,
      'booking_amt': int.tryParse(bookingCtrl.text) ?? 0,
      'down_amt': int.tryParse(downCtrl.text) ?? 0,
      'booking_date': bookingDate,
      'deliv_date': deliveryDate,
      'inst_no': int.tryParse(installmentCtrl.text) ?? 0,
      'amt_per_inst': perInstallment.toStringAsFixed(0),
      'total_due': dueAmt,
      'payment_mode': 1,
      'ref_by': null,
      'comp_id': widget.compId,
    };

    final isUpdate = widget.initialData != null;
    final url = isUpdate
        ? "https://darktechteam.com/realestate/api/update_flat_sale/${widget.initialData!['id']}"
        : "https://darktechteam.com/realestate/api/create_flat_sale";

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate ? "Updated Successfully" : "Created Successfully",
          ),
        ),
      );
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Submission failed")));
    }
  }

  Widget buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget buildInput(
    String label,
    TextEditingController ctrl, {
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget buildDatePicker(
    String label,
    TextEditingController ctrl,
    void Function(String) onPicked,
  ) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
      onTap: () => _pickDate(context, ctrl, onPicked),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _summaryText(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFlats = widget.flats
        .where((f) => f['project'] == selectedProject)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1-column fields
                    buildDropdown<int>(
                      label: 'Client',
                      value:
                          widget.clients.any((c) => c['id'] == selectedClient)
                          ? selectedClient
                          : null,
                      items: widget.clients
                          .map<DropdownMenuItem<int>>(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'],
                              child: Text("${c['client_id']} - ${c['name']}"),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedClient = val),
                      validator: (val) =>
                          val == null ? 'Please select a client' : null,
                    ),
                    const SizedBox(height: 16),

                    buildDropdown<int>(
                      label: 'Project',
                      value:
                          widget.projects.any((p) => p['id'] == selectedProject)
                          ? selectedProject
                          : null,
                      items: widget.projects
                          .map<DropdownMenuItem<int>>(
                            (p) => DropdownMenuItem<int>(
                              value: p['id'],
                              child: Text("${p['pro_id']} - ${p['name']}"),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final selected = widget.projects.firstWhere(
                          (p) => p['id'] == val,
                        );
                        setState(() {
                          selectedProject = val;
                          projectLocation = selected['location'] ?? '';
                          projectLocationCtrl.text = projectLocation;
                          selectedFlat = null;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Please select a project' : null,
                    ),
                    const SizedBox(height: 16),

                    // Project Location - read only
                    TextFormField(
                      controller: projectLocationCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Project Location",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    buildDropdown<int>(
                      label: 'Flat',
                      value: filteredFlats.any((f) => f['id'] == selectedFlat)
                          ? selectedFlat
                          : null,
                      items: filteredFlats
                          .map<DropdownMenuItem<int>>(
                            (f) => DropdownMenuItem<int>(
                              value: f['id'],
                              child: Text(f['flat_id']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedFlat = val),
                      validator: (val) =>
                          val == null ? 'Please select a flat' : null,
                    ),
                    const SizedBox(height: 16),

                    // 2-column layout rows
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Size (sq ft)", sizeCtrl),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Rate (per sq ft)", rateCtrl),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Garage Charge", garageCtrl),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Utility Charge", utilityCtrl),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Common Charge", commonCtrl),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Other Charges", othersCtrl),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Discount", discountCtrl),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Booking Amount", bookingCtrl),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Down Payment", downCtrl),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 28,
                          child: buildInput("Installments", installmentCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    buildDatePicker(
                      "Booking Date",
                      bookingDateCtrl,
                      (val) => bookingDate = val,
                    ),
                    const SizedBox(height: 16),

                    buildDatePicker(
                      "Delivery Date",
                      deliveryDateCtrl,
                      (val) => deliveryDate = val,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Cancel", style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      widget.initialData != null
                          ? "Update Sale"
                          : "Submit Sale",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
