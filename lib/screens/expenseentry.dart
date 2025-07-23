import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ExpenseEntryPage extends StatefulWidget {
  const ExpenseEntryPage({super.key});

  @override
  State<ExpenseEntryPage> createState() => _ExpenseEntryPageState();
}

class _ExpenseEntryPageState extends State<ExpenseEntryPage> {
  int? compId;
  String? token;

  final List<Map<String, String>> monthList = [
    {'val': '01', 'name': 'January'},
    {'val': '02', 'name': 'February'},
    {'val': '03', 'name': 'March'},
    {'val': '04', 'name': 'April'},
    {'val': '05', 'name': 'May'},
    {'val': '06', 'name': 'June'},
    {'val': '07', 'name': 'July'},
    {'val': '08', 'name': 'August'},
    {'val': '09', 'name': 'September'},
    {'val': '10', 'name': 'October'},
    {'val': '11', 'name': 'November'},
    {'val': '12', 'name': 'December'},
  ];

  String? selectedYear;
  String? selectedMonth;
  String? selectedProjectId;

  List<Map<String, dynamic>> projects = [];

  final signMoneyCtrl = TextEditingController();
  final rodCementCtrl = TextEditingController();
  final aboutRajRodWorkCtrl = TextEditingController();
  final buyElecProCtrl = TextEditingController();
  final aboutElecWorkCtrl = TextEditingController();
  final buyColorCtrl = TextEditingController();
  final aboutColorWorkCtrl = TextEditingController();
  final buyGrillThyCtrl = TextEditingController();
  final buyTilesProCtrl = TextEditingController();
  final aboutTilesWorkCtrl = TextEditingController();
  final buyCenetaryProCtrl = TextEditingController();
  final aboutCenetaryWorkCtrl = TextEditingController();
  final buyDorCtrl = TextEditingController();
  final officeRentElecBillCtrl = TextEditingController();
  final tradeTaxAdverCtrl = TextEditingController();
  final direcMediaTravelCtrl = TextEditingController();
  final investDividensCtrl = TextEditingController();
  final officeEquipmentCtrl = TextEditingController();

  double totalCost = 0;
  bool isLoadingProjects = false;

  @override
  void initState() {
    super.initState();
    loadInitial();
    _addControllersListener();
  }

  void _addControllersListener() {
    [
      signMoneyCtrl,
      rodCementCtrl,
      aboutRajRodWorkCtrl,
      buyElecProCtrl,
      aboutElecWorkCtrl,
      buyColorCtrl,
      aboutColorWorkCtrl,
      buyGrillThyCtrl,
      buyTilesProCtrl,
      aboutTilesWorkCtrl,
      buyCenetaryProCtrl,
      aboutCenetaryWorkCtrl,
      buyDorCtrl,
      officeRentElecBillCtrl,
      tradeTaxAdverCtrl,
      direcMediaTravelCtrl,
      investDividensCtrl,
      officeEquipmentCtrl,
    ].forEach((controller) {
      controller.addListener(_calculateTotal);
    });
  }

  Future<void> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    compId = prefs.getInt('comp_id');

    await Future.wait([fetchProjects()]);
  }

  Future<void> fetchProjects() async {
    if (token == null || compId == null) {
      debugPrint('Token or Company ID is null, cannot fetch projects');
      return;
    }

    setState(() {
      isLoadingProjects = true;
    });

    try {
      final res = await http.get(
        Uri.parse(
          'https://darktechteam.com/realestate/api/all_project?compId=$compId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          projects = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        debugPrint('Failed to load projects: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading projects: $e');
    } finally {
      setState(() {
        isLoadingProjects = false;
      });
    }
  }

  void _calculateTotal() {
    setState(() {
      totalCost =
          [
                signMoneyCtrl,
                rodCementCtrl,
                aboutRajRodWorkCtrl,
                buyElecProCtrl,
                aboutElecWorkCtrl,
                buyColorCtrl,
                aboutColorWorkCtrl,
                buyGrillThyCtrl,
                buyTilesProCtrl,
                aboutTilesWorkCtrl,
                buyCenetaryProCtrl,
                aboutCenetaryWorkCtrl,
                buyDorCtrl,
                officeRentElecBillCtrl,
                tradeTaxAdverCtrl,
                direcMediaTravelCtrl,
                investDividensCtrl,
                officeEquipmentCtrl,
              ]
              .map((ctrl) => double.tryParse(ctrl.text) ?? 0)
              .fold(0.0, (a, b) => a + b);
    });
  }

  Future<void> _showYearPicker() async {
    final now = DateTime.now();
    final initialYear = selectedYear != null
        ? int.tryParse(selectedYear!) ?? now.year
        : now.year;
    final pickedYear = await showDialog<int>(
      context: context,
      builder: (context) => YearPickerDialog(initialYear: initialYear),
    );

    if (pickedYear != null) {
      setState(() {
        selectedYear = pickedYear.toString();
      });
    }
  }

  @override
  void dispose() {
    signMoneyCtrl.dispose();
    rodCementCtrl.dispose();
    aboutRajRodWorkCtrl.dispose();
    buyElecProCtrl.dispose();
    aboutElecWorkCtrl.dispose();
    buyColorCtrl.dispose();
    aboutColorWorkCtrl.dispose();
    buyGrillThyCtrl.dispose();
    buyTilesProCtrl.dispose();
    aboutTilesWorkCtrl.dispose();
    buyCenetaryProCtrl.dispose();
    aboutCenetaryWorkCtrl.dispose();
    buyDorCtrl.dispose();
    officeRentElecBillCtrl.dispose();
    tradeTaxAdverCtrl.dispose();
    direcMediaTravelCtrl.dispose();
    investDividensCtrl.dispose();
    officeEquipmentCtrl.dispose();

    super.dispose();
  }

  Widget _buildNumberInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.teal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Entry'),
        backgroundColor: primaryColor,
      ),
      body: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 8,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Year picker
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    selectedYear ?? 'Select Year',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedYear == null ? Colors.grey : Colors.black,
                    ),
                  ),
                  trailing: Icon(Icons.calendar_today, color: primaryColor),
                  onTap: _showYearPicker,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),

              // Month dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                value: selectedMonth,
                items: monthList
                    .map(
                      (m) => DropdownMenuItem<String>(
                        value: m['val'],
                        child: Text(m['name']!),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedMonth = val),
              ),
              const SizedBox(height: 16),

              // Project dropdown
              isLoadingProjects
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Project Id & Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      value: selectedProjectId,
                      items: projects
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p['id'].toString(),
                              child: Text("${p['id']} - ${p['name']}"),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedProjectId = val),
                    ),
              const SizedBox(height: 20),

              // Numeric inputs
              _buildNumberInput(
                'Signing Money, Cost Including Plan',
                signMoneyCtrl,
              ),
              _buildNumberInput(
                'Rod, Cement, Brick, Sand, Stone',
                rodCementCtrl,
              ),
              _buildNumberInput(
                "About Raj and Rod's Work",
                aboutRajRodWorkCtrl,
              ),
              _buildNumberInput('Purchase Of Electrical Goods', buyElecProCtrl),
              _buildNumberInput('About Electric Work', aboutElecWorkCtrl),
              _buildNumberInput('Purchase Of Color Goods', buyColorCtrl),
              _buildNumberInput("About Color's Work", aboutColorWorkCtrl),
              _buildNumberInput('Purchase Grill and Thai', buyGrillThyCtrl),
              _buildNumberInput('Purchase Tiles', buyTilesProCtrl),
              _buildNumberInput('About Tiles Work', aboutTilesWorkCtrl),
              _buildNumberInput('Purchase Sanitary Goods', buyCenetaryProCtrl),
              _buildNumberInput('About Sanitary Work', aboutCenetaryWorkCtrl),
              _buildNumberInput('Purchase Frames and Doors', buyDorCtrl),
              _buildNumberInput(
                'Office Rent and Electricity Bill',
                officeRentElecBillCtrl,
              ),
              _buildNumberInput(
                'Tin, Trade, Tax, Advertise',
                tradeTaxAdverCtrl,
              ),
              _buildNumberInput(
                'Director, Media, Travel',
                direcMediaTravelCtrl,
              ),
              _buildNumberInput('Investment Dividends', investDividensCtrl),
              _buildNumberInput('Office Equipment', officeEquipmentCtrl),

              const SizedBox(height: 24),

              // Total cost (read-only)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Total Cost',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                enabled: false,
                controller: TextEditingController(
                  text: totalCost.toStringAsFixed(2),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  if (selectedYear == null ||
                      selectedMonth == null ||
                      selectedProjectId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select Year, Month and Project'),
                      ),
                    );
                    return;
                  }

                  final formData = {
                    'year': selectedYear,
                    'month': selectedMonth,
                    'project_id': selectedProjectId,
                    'signMoney': double.tryParse(signMoneyCtrl.text) ?? 0,
                    'rodCement': double.tryParse(rodCementCtrl.text) ?? 0,
                    'about_raj_rod_work':
                        double.tryParse(aboutRajRodWorkCtrl.text) ?? 0,
                    'buy_elec_pro': double.tryParse(buyElecProCtrl.text) ?? 0,
                    'about_elec_work':
                        double.tryParse(aboutElecWorkCtrl.text) ?? 0,
                    'buy_color': double.tryParse(buyColorCtrl.text) ?? 0,
                    'about_color_work':
                        double.tryParse(aboutColorWorkCtrl.text) ?? 0,
                    'buy_grill_thy': double.tryParse(buyGrillThyCtrl.text) ?? 0,
                    'buy_tiles_pro': double.tryParse(buyTilesProCtrl.text) ?? 0,
                    'about_tiles_work':
                        double.tryParse(aboutTilesWorkCtrl.text) ?? 0,
                    'buy_cenetary_pro':
                        double.tryParse(buyCenetaryProCtrl.text) ?? 0,
                    'about_cenetary_work':
                        double.tryParse(aboutCenetaryWorkCtrl.text) ?? 0,
                    'buy_dor': double.tryParse(buyDorCtrl.text) ?? 0,
                    'office_rent_elec_bill':
                        double.tryParse(officeRentElecBillCtrl.text) ?? 0,
                    'trade_tax_adver':
                        double.tryParse(tradeTaxAdverCtrl.text) ?? 0,
                    'direc_media_travel':
                        double.tryParse(direcMediaTravelCtrl.text) ?? 0,
                    'invest_dividens':
                        double.tryParse(investDividensCtrl.text) ?? 0,
                    'office_equipment':
                        double.tryParse(officeEquipmentCtrl.text) ?? 0,
                    'total_cost': totalCost,
                  };

                  print('Submitting data: $formData');

                  // TODO: Submit data to backend API here
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YearPickerDialog extends StatefulWidget {
  final int initialYear;

  const YearPickerDialog({required this.initialYear, super.key});

  @override
  State<YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<YearPickerDialog> {
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 10;
    final endYear = currentYear + 10;
    final years = List<int>.generate(
      endYear - startYear + 1,
      (i) => startYear + i,
    );

    return AlertDialog(
      title: const Text('Select Year'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.builder(
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              return ListTile(
                title: Text(year.toString()),
                selected: year == selectedYear,
                selectedTileColor: Colors.teal.shade100,
                onTap: () => setState(() => selectedYear = year),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedYear),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
