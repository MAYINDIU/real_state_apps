import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReferenceInfoPage extends StatefulWidget {
  const ReferenceInfoPage({super.key});

  @override
  State<ReferenceInfoPage> createState() => _ReferenceInfoPageState();
}

class _ReferenceInfoPageState extends State<ReferenceInfoPage> {
  List<dynamic> references = [];
  List<dynamic> filteredReferences = [];
  final TextEditingController _searchController = TextEditingController();

  String? authToken;
  int? compId;

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetchReferences();
  }

  Future<void> _loadAuthAndFetchReferences() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    compId = prefs.getInt('comp_id');
    if (authToken != null && compId != null) {
      fetchReferences();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication info missing')),
      );
    }
  }

  Future<void> fetchReferences() async {
    final response = await http.get(
      Uri.parse('http://localhost:5002/api/all_reference?compId=$compId'),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        references = data['data'];
        filteredReferences = references;
      });
    }
  }

  void _filterReferences(String query) {
    setState(() {
      filteredReferences = references.where((ref) {
        final name = ref['name']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  String _getNextRefId() {
    final List<String> ids = references
        .map((e) => e['ref_id'] as String? ?? '')
        .toList();
    final nextNum =
        ids
            .map((id) => int.tryParse(id.split('-').last) ?? 101)
            .fold(101, (a, b) => b > a ? b : a) +
        1;
    return 'R$compId-$nextNum';
  }

  void _showAddEditBottomSheet({Map? reference}) {
    final isEdit = reference != null;
    final name = TextEditingController(text: reference?['name'] ?? '');
    final mobile = TextEditingController(text: reference?['mobile'] ?? '');
    final email = TextEditingController(text: reference?['email'] ?? '');
    final rmks = TextEditingController(text: reference?['rmks'] ?? '');
    final refId = isEdit ? reference!['ref_id'] : _getNextRefId();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
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
                isEdit ? 'Edit Reference' : 'Add Reference',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                enabled: false,
                initialValue: refId,
                decoration: const InputDecoration(
                  labelText: 'Ref ID',
                  filled: true,
                  fillColor: Color(0xFFF0F0F0),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: mobile,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rmks,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEdit ? Colors.blue : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (isEdit) {
                        await _updateReference(
                          reference!['id'],
                          name.text,
                          mobile.text,
                          email.text,
                          rmks.text,
                        );
                      } else {
                        await _addReference(
                          refId,
                          name.text,
                          mobile.text,
                          email.text,
                          rmks.text,
                        );
                      }
                      Navigator.pop(context);
                    },
                    child: Text(isEdit ? 'UPDATE' : 'SAVE'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addReference(
    String refId,
    String name,
    String mobile,
    String email,
    String rmks,
  ) async {
    await http.post(
      Uri.parse('http://localhost:5002/api/create_reference'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ref_id': refId,
        'name': name,
        'mobile': mobile,
        'email': email,
        'rmks': rmks,
        'comp_id': compId,
      }),
    );
    fetchReferences();
  }

  Future<void> _updateReference(
    int id,
    String name,
    String mobile,
    String email,
    String rmks,
  ) async {
    await http.patch(
      Uri.parse('http://localhost:5002/api/reference_update/$id'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'mobile': mobile,
        'email': email,
        'rmks': rmks,
        'comp_id': compId,
      }),
    );
    fetchReferences();
  }

  Future<void> _deleteReference(int id) async {
    await http.delete(
      Uri.parse('http://localhost:5002/api/reference_delete/$id'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    fetchReferences();
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
            'Are you sure you want to delete this reference?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteReference(id);
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReferenceCard(Map ref) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(
          '${ref['name']} (${ref['ref_id']})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Mobile: ${ref['mobile']}'),
        trailing: Wrap(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showAddEditBottomSheet(reference: ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(ref['id']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reference List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterReferences,
              decoration: const InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchReferences,
              child: ListView.builder(
                itemCount: filteredReferences.length,
                itemBuilder: (context, index) =>
                    _buildReferenceCard(filteredReferences[index]),
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
