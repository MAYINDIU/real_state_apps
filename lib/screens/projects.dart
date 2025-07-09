import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProjectInfoPage extends StatefulWidget {
  const ProjectInfoPage({super.key});

  @override
  State<ProjectInfoPage> createState() => _ProjectInfoPageState();
}

class _ProjectInfoPageState extends State<ProjectInfoPage> {
  List<dynamic> projects = [];
  List<dynamic> filteredProjects = [];
  final TextEditingController _searchController = TextEditingController();
  String? authToken;
  int? compId;

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetchProjects();
  }

  Future<void> _loadAuthAndFetchProjects() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    compId = prefs.getInt('comp_id') ?? 3;
    if (authToken != null && compId != null) {
      fetchProjects();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication info missing')),
      );
    }
  }

  Future<void> fetchProjects() async {
    final response = await http.get(
      Uri.parse(
        'https://darktechteam.com/realestate/api/all_project?compId=$compId',
      ),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        projects = data['data'];
        filteredProjects = projects;
      });
    }
  }

  void _filterProjects(String query) {
    setState(() {
      filteredProjects = projects.where((proj) {
        final name = proj['name']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  String _getNextProjectId() {
    final List<String> ids = projects
        .map((e) => e['pro_id'] as String? ?? '')
        .toList();
    final nextNum =
        ids
            .map((id) => int.tryParse(id.split('-').last) ?? 101)
            .fold(101, (a, b) => b > a ? b : a) +
        1;
    return 'P$compId-$nextNum';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<void> _deleteProject(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await http.delete(
        Uri.parse('https://darktechteam.com/realestate/api/project_delete/$id'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted successfully')),
        );
        fetchProjects();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete project')),
        );
      }
    }
  }

  void _showAddEditBottomSheet({Map? project}) {
    final isEdit = project != null;
    final name = TextEditingController(text: project?['name'] ?? '');
    final location = TextEditingController(text: project?['location'] ?? '');
    final area = TextEditingController(
      text: project?['area']?.toString() ?? '',
    );
    final startDate = TextEditingController(
      text: project?['start_date']?.split('T').first ?? '',
    );
    final endDate = TextEditingController(
      text: project?['end_date']?.split('T').first ?? '',
    );
    final rmks = TextEditingController(text: project?['rmks'] ?? '');
    final noOfUnit = TextEditingController(
      text: project?['no_of_unit']?.toString() ?? '',
    );
    final perFloorUnit = TextEditingController(
      text: project?['per_floor_unit']?.toString() ?? '',
    );
    final proId = isEdit ? project!['pro_id'] : _getNextProjectId();
    int projectType = project?['pro_type'] ?? 1;
    String status = project?['status'] ?? 'Open';

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
                  isEdit ? 'Edit Project' : 'Add Project',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  enabled: false,
                  initialValue: proId,
                  decoration: const InputDecoration(
                    labelText: 'Project ID',
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
                  controller: location,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Row with two columns: Area and Project Type
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: area,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Project Area (sq. ft.)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: projectType,
                        decoration: const InputDecoration(
                          labelText: 'Project Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Residential'),
                          ),
                          DropdownMenuItem(value: 2, child: Text('Commercial')),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('Residential/Commercial'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            projectType = val;
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row with two columns: Start Date and End Date
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.tryParse(startDate.text) ??
                                DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            startDate.text = picked
                                .toIso8601String()
                                .split('T')
                                .first;
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: startDate,
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.tryParse(endDate.text) ??
                                DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            endDate.text = picked
                                .toIso8601String()
                                .split('T')
                                .first;
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: endDate,
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row with two columns: No of Units and Per Floor Unit
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: noOfUnit,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'No of Units',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: perFloorUnit,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Per Floor Unit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Open', child: Text('Open')),
                    DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                    DropdownMenuItem(value: 'On Hold', child: Text('On Hold')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      status = val;
                    }
                  },
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
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: () async {
                        final payload = {
                          'pro_id': proId,
                          'pro_type': projectType,
                          'name': name.text,
                          'location': location.text,
                          'area': int.tryParse(area.text) ?? 0,
                          'start_date': startDate.text,
                          'end_date': endDate.text,
                          'status': status,
                          'rmks': rmks.text,
                          'no_of_unit': int.tryParse(noOfUnit.text) ?? 0,
                          'per_floor_unit':
                              int.tryParse(perFloorUnit.text) ?? 0,
                          'comp_id': compId,
                        };
                        http.Response response;
                        if (isEdit) {
                          response = await http.patch(
                            Uri.parse(
                              'https://darktechteam.com/realestate/api/project_update/${project!['id']}',
                            ),
                            headers: {
                              'Authorization': 'Bearer $authToken',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode(payload),
                          );
                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Project updated successfully'),
                              ),
                            );
                          }
                        } else {
                          response = await http.post(
                            Uri.parse(
                              'https://darktechteam.com/realestate/api/create_project',
                            ),
                            headers: {
                              'Authorization': 'Bearer $authToken',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode(payload),
                          );
                          if (response.statusCode == 200 ||
                              response.statusCode == 201) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Project created successfully'),
                              ),
                            );
                          }
                        }
                        Navigator.pop(context);
                        fetchProjects();
                      },
                      child: Text(isEdit ? 'UPDATE' : 'SAVE'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(Map proj) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${proj['name']} (${proj['pro_id']})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '📍 ${proj['location'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '📆 ${_formatDate(proj['start_date'])} → ${_formatDate(proj['end_date'])}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🏢 Units: ${proj['no_of_unit'] ?? 0} | Per Floor: ${proj['per_floor_unit'] ?? 0}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🟢 Status: ${proj['status'] ?? 'N/A'}',
                    style: TextStyle(
                      color: proj['status'] == 'Open'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showAddEditBottomSheet(project: proj),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProject(proj['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProjects,
              decoration: const InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchProjects,
              child: ListView.builder(
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) =>
                    _buildProjectCard(filteredProjects[index]),
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
