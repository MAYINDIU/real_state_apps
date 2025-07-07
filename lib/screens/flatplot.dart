import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FlatPlotPage extends StatefulWidget {
  const FlatPlotPage({super.key});

  @override
  State<FlatPlotPage> createState() => _FlatPlotPageState();
}

class _FlatPlotPageState extends State<FlatPlotPage> {
  List<dynamic> flats = [];
  List<dynamic> filteredFlats = [];
  List<dynamic> projects = [];
  final TextEditingController _searchController = TextEditingController();

  String? authToken;
  int? compId;

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetchData();
  }

  Future<void> _loadAuthAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    compId = prefs.getInt('comp_id') ?? 1;

    if (authToken != null && compId != null) {
      await fetchProjects();
      await fetchFlats();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication info missing')),
      );
    }
  }

  Future<void> fetchProjects() async {
    final res = await http.get(
      Uri.parse('http://localhost:5002/api/all_project?compId=$compId'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        projects = data['data'];
      });
    }
  }

  Future<void> fetchFlats() async {
    final res = await http.get(
      Uri.parse('http://localhost:5002/api/all_flat_plot?compId=$compId'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        flats = data['data'];
        filteredFlats = flats;
      });
    }
  }

  void _filterFlats(String query) {
    setState(() {
      filteredFlats = flats.where((flat) {
        final flatNo = flat['flat_no']?.toLowerCase() ?? '';
        final projectName = flat['projectName']?.toLowerCase() ?? '';
        return flatNo.contains(query.toLowerCase()) ||
            projectName.contains(query.toLowerCase());
      }).toList();
    });
  }

  String _getNextFlatId() {
    return 'P${compId ?? 1}-${DateTime.now().millisecondsSinceEpoch}';
  }

  void _showAddEditBottomSheet({Map? flat}) {
    final isEdit = flat != null;

    final flatNoController = TextEditingController(
      text: flat?['flat_no'] ?? '',
    );
    final areaController = TextEditingController(text: flat?['area'] ?? '');
    final sizeController = TextEditingController(
      text: flat?['size']?.toString() ?? '',
    );
    final floorLocController = TextEditingController(
      text: flat?['floor_loc'] ?? '',
    );
    final priceController = TextEditingController(
      text: flat?['price_per_sq_f']?.toString() ?? '',
    );
    final utilityController = TextEditingController(
      text: flat?['utility_chrg']?.toString() ?? '',
    );
    final garageController = TextEditingController(
      text: flat?['garage_chrg']?.toString() ?? '',
    );
    final commController = TextEditingController(
      text: flat?['comm_chrg']?.toString() ?? '',
    );
    final othersController = TextEditingController(
      text: flat?['others_chrg']?.toString() ?? '',
    );
    final spacialDiscController = TextEditingController(
      text: flat?['spacial_disc']?.toString() ?? '',
    );

    // --- Fix dropdown initial values to be valid ---

    // Project dropdown
    List<String> projectIds = projects
        .map((p) => p['id'].toString())
        .toList(growable: false);
    String selectedProjectId = '';
    if (flat != null && flat['project'] != null) {
      final projIdStr = flat['project'].toString();
      selectedProjectId = projectIds.contains(projIdStr)
          ? projIdStr
          : (projectIds.isNotEmpty ? projectIds.first : '');
    } else {
      selectedProjectId = projectIds.isNotEmpty ? projectIds.first : '';
    }

    // Type dropdown
    List<String> typeItems = ['Flat', 'Shop', 'Plot', 'Land'];
    String selectedType =
        (flat?['type'] != null && typeItems.contains(flat!['type']))
        ? flat['type']
        : typeItems.first;

    // Side dropdown - add 'Any' if needed, to match your data
    List<String> sideItems = [
      'Any',
      'North Side',
      'South Side',
      'East Side',
      'West Side',
    ];
    String selectedSide =
        (flat?['side'] != null && sideItems.contains(flat!['side']))
        ? flat['side']
        : sideItems.first;

    // Sale status dropdown
    List<String> saleStatusItems = ['Sold', 'Unsold'];
    String selectedSaleStatus =
        (flat?['sale_status'] != null &&
            saleStatusItems.contains(flat!['sale_status']))
        ? flat['sale_status']
        : saleStatusItems.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    Text(
                      isEdit ? 'Edit Flat/Plot' : 'Add Flat/Plot',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Project Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedProjectId.isNotEmpty
                          ? selectedProjectId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Select Project',
                        border: OutlineInputBorder(),
                      ),
                      items: projects.map<DropdownMenuItem<String>>((project) {
                        final id = project['id'].toString();
                        final proId = project['pro_id'] ?? '';
                        final name = project['name'] ?? 'Unnamed Project';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text('$proId - $name'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedProjectId = val;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _formInput('Flat/Plot No', flatNoController),
                        _formInput('Area', areaController),
                        _formInput('Size', sizeController, number: true),
                        _dropdownInput(
                          'Type',
                          selectedType,
                          typeItems,
                          setModalState,
                          (val) => selectedType = val,
                        ),
                        _dropdownInput(
                          'Side',
                          selectedSide,
                          sideItems,
                          setModalState,
                          (val) => selectedSide = val,
                        ),
                        _formInput('Floor Location', floorLocController),
                        _formInput(
                          'Price per sq. ft.',
                          priceController,
                          number: true,
                        ),
                        _formInput(
                          'Utility Charge',
                          utilityController,
                          number: true,
                        ),
                        _formInput(
                          'Garage Charge',
                          garageController,
                          number: true,
                        ),
                        _formInput(
                          'Common Charge',
                          commController,
                          number: true,
                        ),
                        _formInput(
                          'Other Charges',
                          othersController,
                          number: true,
                        ),
                        _formInput(
                          'Special Discount',
                          spacialDiscController,
                          number: true,
                        ),
                        _dropdownInput(
                          'Sale Status',
                          selectedSaleStatus,
                          saleStatusItems,
                          setModalState,
                          (val) => selectedSaleStatus = val,
                        ),
                      ],
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
                          onPressed: () async {
                            final flatId = isEdit
                                ? flat!['flat_id']
                                : _getNextFlatId() +
                                      '-' +
                                      flatNoController.text;

                            final total =
                                (int.tryParse(priceController.text) ?? 0) *
                                    (int.tryParse(sizeController.text) ?? 0) +
                                (int.tryParse(utilityController.text) ?? 0) +
                                (int.tryParse(garageController.text) ?? 0) +
                                (int.tryParse(commController.text) ?? 0) +
                                (int.tryParse(othersController.text) ?? 0) -
                                (int.tryParse(spacialDiscController.text) ?? 0);

                            final payload = {
                              "flat_id": flatId,
                              "project": selectedProjectId,
                              "area": areaController.text,
                              "type": selectedType,
                              "flat_no": flatNoController.text,
                              "size": sizeController.text,
                              "side": selectedSide,
                              "floor_loc": floorLocController.text,
                              "price_per_sq_f": priceController.text,
                              "utility_chrg": utilityController.text,
                              "garage_chrg": garageController.text,
                              "comm_chrg": commController.text,
                              "others_chrg": othersController.text,
                              "spacial_disc": spacialDiscController.text,
                              "sale_status": selectedSaleStatus,
                              "comp_id": compId,
                              "total": total,
                              "net_pay": total,
                            };

                            http.Response response;

                            if (isEdit) {
                              response = await http.patch(
                                Uri.parse(
                                  'http://localhost:5002/api/plat_plot_update/${flat!['id']}',
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
                                  'http://localhost:5002/api/create_flat_plot',
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
                              fetchFlats();
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
                                const SnackBar(
                                  content: Text('Failed to save flat'),
                                ),
                              );
                            }
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
      },
    );
  }

  Widget _formInput(
    String label,
    TextEditingController controller, {
    bool number = false,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 64) / 2,
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

  Widget _dropdownInput(
    String label,
    String value,
    List<String> items,
    StateSetter setModalState,
    Function(String) onChanged,
  ) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: (val) {
          if (val != null) setModalState(() => onChanged(val));
        },
      ),
    );
  }

  Widget _buildFlatCard(Map flat) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${flat['flat_no']} (${flat['flat_id']})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Project: ${flat['projectName'] ?? 'N/A'}'),
                  const SizedBox(height: 6),
                  Text('Area: ${flat['area'] ?? 'N/A'}'),
                  const SizedBox(height: 6),
                  Text('Floor Location: ${flat['floor_loc'] ?? 'N/A'}'),
                  const SizedBox(height: 6),
                  Text('Sale Status: ${flat['sale_status'] ?? 'N/A'}'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showAddEditBottomSheet(flat: flat),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flat / Plot List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterFlats,
              decoration: const InputDecoration(
                labelText: 'Search by Flat No or Project Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchFlats,
              child: ListView.builder(
                itemCount: filteredFlats.length,
                itemBuilder: (context, index) =>
                    _buildFlatCard(filteredFlats[index]),
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
