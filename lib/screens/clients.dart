import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  List<dynamic> clients = [];
  List<dynamic> filteredClients = [];
  final TextEditingController _searchController = TextEditingController();

  String? authToken;
  int? compId;

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetchClients();
  }

  Future<void> _loadAuthAndFetchClients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final compIdStored = prefs.getInt('comp_id');

    if (token != null && compIdStored != null) {
      setState(() {
        authToken = token;
        compId = compIdStored;
      });
      fetchClients();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication info missing')),
      );
    }
  }

  Future<void> fetchClients() async {
    if (authToken == null || compId == null) return;

    final response = await http.get(
      Uri.parse(
        "https://darktechteam.com/realestate/api/all_client?compId=$compId",
      ),
      headers: {
        "Authorization": "Bearer $authToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        clients = data['data'];
        filteredClients = clients;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load clients: ${response.statusCode}"),
        ),
      );
    }
  }

  void _filterClients(String query) {
    setState(() {
      filteredClients = clients.where((client) {
        final name = client['name']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  String _getNextClientId() {
    final List<String> clientIds = clients
        .map((e) => e['client_id'] as String?)
        .where((id) => id != null && id.startsWith('C'))
        .cast<String>()
        .toList();

    if (clientIds.isEmpty) return "C$compId-101";

    final lastId = clientIds
        .map((id) {
          final parts = id.split("-");
          return int.tryParse(parts.last) ?? 100;
        })
        .fold<int>(100, (prev, element) => element > prev ? element : prev);

    return "C$compId-${lastId + 1}";
  }

  void _showAddClientBottomSheet() {
    final name = TextEditingController();
    final spouse = TextEditingController();
    final father = TextEditingController();
    final mother = TextEditingController();
    final mobile = TextEditingController();
    final nid = TextEditingController();
    final presAddr = TextEditingController();
    final permAddr = TextEditingController();
    final rmks = TextEditingController();

    String nextClientId = _getNextClientId();

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Add New Client",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    _buildField(
                      "Client ID",
                      initialValue: nextClientId,
                      readOnly: true,
                    ),
                    _buildField("Name", controller: name),
                    _buildField("Spouse", controller: spouse),
                    _buildField("Father", controller: father),
                    _buildField("Mother", controller: mother),
                    _buildField("Mobile", controller: mobile),
                    _buildField("NID", controller: nid),
                    _buildField("Present Address", controller: presAddr),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        "Permanent Address",
                        controller: permAddr,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField("Remarks", controller: rmks)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("SAVE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        await _addClient(
                          name.text,
                          spouse.text,
                          father.text,
                          mother.text,
                          mobile.text,
                          nid.text,
                          presAddr.text,
                          permAddr.text,
                          rmks.text,
                          nextClientId,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(
    String label, {
    TextEditingController? controller,
    String? initialValue,
    bool readOnly = false,
  }) {
    final fieldController =
        controller ?? TextEditingController(text: initialValue);

    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 26,
      child: TextField(
        controller: fieldController,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: readOnly ? Colors.grey[200] : Colors.white,
        ),
      ),
    );
  }

  Future<void> _addClient(
    String name,
    String spouse,
    String father,
    String mother,
    String mobile,
    String nid,
    String presAddr,
    String permAddr,
    String rmks,
    String clientId,
  ) async {
    if (authToken == null || compId == null) return;

    final response = await http.post(
      Uri.parse("https://darktechteam.com/realestate/api/create_client"),
      headers: {
        "Authorization": "Bearer $authToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "client_id": clientId,
        "name": name,
        "spouse": spouse,
        "father": father,
        "mother": mother,
        "mobile": mobile,
        "nid": nid,
        "pres_addr": presAddr,
        "perm_addr": permAddr,
        "rmks": rmks,
        "image": "",
        "comp_id": compId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      await fetchClients();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add client: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateClient(
    int id,
    String name,
    String spouse,
    String father,
    String mother,
    String mobile,
    String nid,
    String presAddr,
    String permAddr,
    String rmks,
  ) async {
    if (authToken == null || compId == null) return;

    final response = await http.patch(
      Uri.parse("https://darktechteam.com/realestate/api/client_update/$id"),
      headers: {
        "Authorization": "Bearer $authToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "spouse": spouse,
        "father": father,
        "mother": mother,
        "mobile": mobile,
        "nid": nid,
        "pres_addr": presAddr,
        "perm_addr": permAddr,
        "rmks": rmks,
        "comp_id": compId,
      }),
    );

    if (response.statusCode == 200) {
      await fetchClients();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update client: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editClient(Map client) {
    final name = TextEditingController(text: client['name'] ?? '');
    final spouse = TextEditingController(text: client['spouse'] ?? '');
    final father = TextEditingController(text: client['father'] ?? '');
    final mother = TextEditingController(text: client['mother'] ?? '');
    final mobile = TextEditingController(text: client['mobile'] ?? '');
    final nid = TextEditingController(text: client['nid'] ?? '');
    final presAddr = TextEditingController(text: client['pres_addr'] ?? '');
    final permAddr = TextEditingController(text: client['perm_addr'] ?? '');
    final rmks = TextEditingController(text: client['rmks'] ?? '');

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
                Center(
                  child: Text(
                    "Edit Client",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    _buildField(
                      "Client ID",
                      initialValue: client['client_id'],
                      readOnly: true,
                    ),
                    _buildField("Name", controller: name),
                    _buildField("Spouse", controller: spouse),
                    _buildField("Father", controller: father),
                    _buildField("Mother", controller: mother),
                    _buildField("Mobile", controller: mobile),
                    _buildField("NID", controller: nid),
                    _buildField("Present Address", controller: presAddr),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        "Permanent Address",
                        controller: permAddr,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField("Remarks", controller: rmks)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.update),
                      label: const Text("UPDATE"),
                      onPressed: () async {
                        await _updateClient(
                          client['id'],
                          name.text,
                          spouse.text,
                          father.text,
                          mother.text,
                          mobile.text,
                          nid.text,
                          presAddr.text,
                          permAddr.text,
                          rmks.text,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteClient(String clientIdNumber) async {
    if (authToken == null) return;

    final response = await http.delete(
      Uri.parse(
        "https://darktechteam.com/realestate/api/client_delete/$clientIdNumber",
      ),
      headers: {
        "Authorization": "Bearer $authToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      await fetchClients();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete client: ${response.statusCode}'),
        ),
      );
    }
  }

  Widget _buildClientCard(Map client) {
    String mobile = client['mobile'] ?? '';
    String spouse = client['spouse'] ?? '';
    String father = client['father'] ?? '';
    String mother = client['mother'] ?? '';
    String presAddr = client['pres_addr'] ?? '';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          "${client['name'] ?? 'Unknown'}  (${client['client_id'] ?? ''})",
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spouse.isNotEmpty) Text("Spouse: $spouse"),
            if (father.isNotEmpty) Text("Father: $father"),
            if (mother.isNotEmpty) Text("Mother: $mother"),
            if (presAddr.isNotEmpty) Text("Address: $presAddr"),
            if (mobile.isNotEmpty)
              Row(
                children: [
                  Text("Mobile: $mobile"),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () async {
                      final Uri phoneUri = Uri(scheme: 'tel', path: mobile);
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editClient(client),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteClient(client['id'].toString()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Clients")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterClients,
              decoration: const InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchClients,
              child: ListView.builder(
                itemCount: filteredClients.length,
                itemBuilder: (context, index) {
                  return _buildClientCard(filteredClients[index]);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
