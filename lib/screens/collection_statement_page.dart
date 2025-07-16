import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PDF imports
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart'; // For PdfColors
import 'package:printing/printing.dart';

class CollectionStatementPage extends StatefulWidget {
  const CollectionStatementPage({super.key});

  @override
  State<CollectionStatementPage> createState() =>
      _CollectionStatementPageState();
}

class _CollectionStatementPageState extends State<CollectionStatementPage> {
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> flats = [];
  List<Map<String, dynamic>> allCollections = [];

  Map<String, dynamic> selectedFlat = {};
  List<Map<String, dynamic>> clientCollections = [];

  int? selectedClient;
  bool isLoading = true;
  String? authToken;
  int? compId;

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

  void onClientChanged(int? clientId) {
    if (clientId == null) return;

    final flat = flats.firstWhere(
      (flat) => flat['client_id'] == clientId,
      orElse: () => {},
    );

    final collections = allCollections
        .where((c) => c['client_id'] == clientId)
        .toList();

    setState(() {
      selectedClient = clientId;
      selectedFlat = flat;
      clientCollections = collections;
    });
  }

  String formatDate(String? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
  }

  // === PDF generation function with clean layout ===
  Future<void> _generatePdfAndPrint() async {
    final pdf = pw.Document();

    double totalPaid = 0;
    double totalDue = (selectedFlat['net_amt'] ?? 0).toDouble();

    for (var c in clientCollections) {
      totalPaid += (c['mr_amt'] ?? 0).toDouble();
      totalDue -= (c['mr_amt'] ?? 0).toDouble();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'Collection Statement',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfInfoRow(
                  'Client Name',
                  '${selectedFlat['cId']} - ${selectedFlat['cName']}',
                ),
                _pdfInfoRow(
                  'Project',
                  '${selectedFlat['pId']} - ${selectedFlat['pName']}',
                ),
                _pdfInfoRow(
                  'Flat',
                  '${selectedFlat['fId']} - ${selectedFlat['fLoc']} (${selectedFlat['fSide']})',
                ),
                _pdfInfoRow('Size', '${selectedFlat['fSize']} sq.ft'),
                _pdfInfoRow('Rate per sq.ft', '${selectedFlat['rate_psqf']}'),
                _pdfInfoRow('Garage Charge', '${selectedFlat['garage_chrg']}'),
                _pdfInfoRow(
                  'Utility Charge',
                  '${selectedFlat['utility_chrg']}',
                ),
                _pdfInfoRow('Other Charges', '${selectedFlat['others_chrg']}'),
                _pdfInfoRow('Total Amount', '${selectedFlat['total_amt']}'),
                _pdfInfoRow('Discount', '${selectedFlat['disc_amt']}'),
                _pdfInfoRow('Net Payable', '${selectedFlat['net_amt']}'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Collection Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: {
              0: pw.FixedColumnWidth(30),
              1: pw.FixedColumnWidth(70),
              2: pw.FixedColumnWidth(60),
              3: pw.FixedColumnWidth(80),
              4: pw.FixedColumnWidth(60),
              5: pw.FixedColumnWidth(50),
              6: pw.FixedColumnWidth(70),
              7: pw.FixedColumnWidth(70),
              8: pw.FixedColumnWidth(70),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: [
                  _pdfTableCell('Sl', isHeader: true),
                  _pdfTableCell('Inst Dt', isHeader: true),
                  _pdfTableCell('MR Amt', isHeader: true),
                  _pdfTableCell('Type', isHeader: true),
                  _pdfTableCell('MR No', isHeader: true),
                  _pdfTableCell('Inst No', isHeader: true),
                  _pdfTableCell('Cheque No', isHeader: true),
                  _pdfTableCell('Paid Total', isHeader: true),
                  _pdfTableCell('Due', isHeader: true),
                ],
              ),

              // Data rows
              ...clientCollections.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;

                return pw.TableRow(
                  decoration: index % 2 == 0
                      ? pw.BoxDecoration(color: PdfColors.grey200)
                      : null,
                  children: [
                    _pdfTableCell('${index + 1}'),
                    _pdfTableCell(formatDate(row['inst_date'])),
                    _pdfTableCell('${row['mr_amt']}'),
                    _pdfTableCell(
                      row['p_type'] == 1
                          ? 'Installment'
                          : row['p_type'] == 2
                          ? 'Booking'
                          : 'Down Payment',
                    ),
                    _pdfTableCell(row['mr_no'] ?? '-'),
                    _pdfTableCell('${row['inst_no']}'),
                    _pdfTableCell(row['ch_no'] ?? '-'),
                    _pdfTableCell('${totalPaid.toStringAsFixed(0)}'),
                    _pdfTableCell('${totalDue.toStringAsFixed(0)}'),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Helper function for label-value rows in PDF
  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: PdfColors.blueGrey700,
              ),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Helper function for table cells in PDF
  pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 11,
          color: PdfColors.blueGrey900,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPaid = 0;
    double totalDue = (selectedFlat['net_amt'] ?? 0).toDouble();

    for (var c in clientCollections) {
      totalPaid += (c['mr_amt'] ?? 0).toDouble();
      totalDue -= (c['mr_amt'] ?? 0).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Statement'),
        backgroundColor: Colors.teal[700],
        actions: [
          if (selectedClient != null && selectedFlat.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Download PDF',
              onPressed: _generatePdfAndPrint,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: "Select Client",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: selectedClient,
                    items: clients.map((client) {
                      return DropdownMenuItem<int>(
                        value: client['id'],
                        child: Text(
                          "${client['client_id']} - ${client['name']} (${client['mobile']})",
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: onClientChanged,
                  ),
                  const SizedBox(height: 20),
                  if (selectedClient != null && selectedFlat.isNotEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(
                              "Client Name",
                              "${selectedFlat['cId']} - ${selectedFlat['cName']}",
                            ),
                            _infoRow(
                              "Project",
                              "${selectedFlat['pId']} - ${selectedFlat['pName']}",
                            ),
                            _infoRow(
                              "Flat",
                              "${selectedFlat['fId']} - ${selectedFlat['fLoc']} (${selectedFlat['fSide']})",
                            ),
                            _infoRow("Size", "${selectedFlat['fSize']} sq.ft"),
                            _infoRow(
                              "Rate per sq.ft",
                              "${selectedFlat['rate_psqf']}",
                            ),
                            _infoRow(
                              "Garage Charge",
                              "${selectedFlat['garage_chrg']}",
                            ),
                            _infoRow(
                              "Utility Charge",
                              "${selectedFlat['utility_chrg']}",
                            ),
                            _infoRow(
                              "Other Charges",
                              "${selectedFlat['others_chrg']}",
                            ),
                            _infoRow(
                              "Total Amount",
                              " ${selectedFlat['total_amt']}",
                            ),
                            _infoRow("Discount", "${selectedFlat['disc_amt']}"),
                            _infoRow(
                              "Net Payable",
                              "${selectedFlat['net_amt']}",
                            ),
                            const Divider(height: 30),
                            const Text(
                              "Collection Details",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Table(
                                border: TableBorder.all(),
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                columnWidths: const {
                                  0: FixedColumnWidth(40),
                                  1: FixedColumnWidth(90),
                                  2: FixedColumnWidth(110),
                                  3: FixedColumnWidth(100),
                                  4: FixedColumnWidth(80),
                                  5: FixedColumnWidth(100),
                                  6: FixedColumnWidth(100),
                                  7: FixedColumnWidth(100),
                                  8: FixedColumnWidth(100),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.teal[100],
                                    ),
                                    children: [
                                      tableCell("Sl"),
                                      tableCell("Inst Dt"),
                                      tableCell("MR Amt"),
                                      tableCell("Type"),
                                      tableCell("MR No"),
                                      tableCell("Inst No"),
                                      tableCell("Cheque No"),
                                      tableCell("Paid Total"),
                                      tableCell("Due"),
                                    ],
                                  ),
                                  ...clientCollections.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final row = entry.value;

                                    return TableRow(
                                      children: [
                                        tableCell("${index + 1}"),
                                        tableCell(formatDate(row['inst_date'])),
                                        tableCell("${row['mr_amt']}"),
                                        tableCell(
                                          row['p_type'] == 1
                                              ? "Installment"
                                              : row['p_type'] == 2
                                              ? "Booking"
                                              : "Down Payment",
                                        ),
                                        tableCell(row['mr_no'] ?? "-"),
                                        tableCell("${row['inst_no']}"),
                                        tableCell(row['ch_no'] ?? "-"),
                                        tableCell(
                                          "${totalPaid.toStringAsFixed(0)}",
                                        ),
                                        tableCell(
                                          "${totalDue.toStringAsFixed(0)}",
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
