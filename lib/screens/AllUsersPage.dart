import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AllUsersPage extends StatefulWidget {
  const AllUsersPage({super.key});

  @override
  State<AllUsersPage> createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  String? authToken;
  int? compId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetchUsers();
  }

  Future<void> _loadAuthAndFetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    compId = prefs.getInt('comp_id');
    if (authToken != null && compId != null) {
      await fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication info missing')),
      );
    }
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse(
        'https://darktechteam.com/realestate/api/all_users?compId=$compId',
      ),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        users = data['data'];
        filteredUsers = users;
      });
    } else {
      // You may want to handle errors here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: ${response.statusCode}')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        final name = user['username']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showUserBottomSheet({Map? user}) {
    final isEdit = user != null;
    final username = TextEditingController(text: user?['username'] ?? '');
    final password = TextEditingController();
    String selectedUserType = user?['type'] ?? 'user';

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
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      isEdit ? 'Edit User' : 'Create User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isEdit)
                    TextFormField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedUserType,
                    decoration: const InputDecoration(
                      labelText: 'User Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        selectedUserType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEdit
                              ? Colors.orange
                              : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (isEdit) {
                            await _updateUser(
                              user!['id'],
                              username.text,
                              selectedUserType,
                            );
                          } else {
                            await _createUser(
                              username.text,
                              password.text,
                              selectedUserType,
                            );
                          }
                          Navigator.pop(context);
                        },
                        child: Text(isEdit ? 'UPDATE' : 'CREATE'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createUser(
    String username,
    String password,
    String type,
  ) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://darktechteam.com/realestate/api/register'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
        'type': type,
        'comp_id': compId,
      }),
    );

    if (response.statusCode == 200) {
      _showSuccessDialog('User created successfully!');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User created successfully!')));
    }

    setState(() {
      isLoading = false;
    });

    fetchUsers();
  }

  Future<void> _updateUser(int id, String username, String type) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.patch(
      Uri.parse('https://darktechteam.com/realestate/api/user_update/$id'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': username, 'type': type, 'comp_id': compId}),
    );

    if (response.statusCode == 200) {
      _showSuccessDialog('User updated successfully!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user: ${response.statusCode}'),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });

    fetchUsers();
  }

  Future<void> _deleteUser(int id) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.delete(
      Uri.parse('https://darktechteam.com/realestate/api/user_delete/$id'),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: ${response.statusCode}'),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });

    fetchUsers();
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(id);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map user) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text('${user['username']}'),
        subtitle: Text('Role: ${user['role']}'),
        trailing: Wrap(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showUserBottomSheet(user: user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(user['id']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterUsers,
                    decoration: const InputDecoration(
                      labelText: 'Search by Username',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchUsers,
                    child: ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) =>
                          _buildUserCard(filteredUsers[index]),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _showUserBottomSheet(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
