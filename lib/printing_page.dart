import 'dart:typed_data';
import 'package:farmers_record/main.dart';
import 'package:farmers_record/table_section.dart';
import 'package:farmers_record/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:reorderables/reorderables.dart';
import 'package:intl/intl.dart';

class PrintingPage extends StatefulWidget {
  final List<Respondent> respondents;
  final String selectedProduct;
  final int selectedYear;
  final bool allProducts;

  const PrintingPage({
    super.key,
    required this.respondents,
    required this.selectedProduct,
    required this.selectedYear,
    this.allProducts = false,
  });

  @override
  State<PrintingPage> createState() => _PrintingPageState();
}

class _PrintingPageState extends State<PrintingPage> {
  final List<Map<String, String>> availableFields = [
    {'key': 'full_name', 'header': 'Full Name'},
    {'key': 'id', 'header': 'ID'},
    {'key': 'age', 'header': 'Age'},
    {'key': 'all_products', 'header': 'All Products'},
    {'key': 'area', 'header': 'Area (ha)'},
  ];

  final List<String> products = [
    'PALAY',
    'NIYOG',
    'SAGING',
    'HALAMANG UGAT',
    'PRUTAS',
    'GULAY',
  ];

  final List<String> _selectedKeysOrdered = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    if (_selectedKeysOrdered.length < 2) {
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Text(
                  "Select at least 2 fields to preview the PDF.",
                  style: const pw.TextStyle(color: PdfColors.black),
                ),
              ),
            );
          },
        ),
      );
      return pdf.save();
    }

    final tnrData = await rootBundle.load('assets/fonts/times new roman.ttf');
    final timesNewRoman = pw.Font.ttf(tnrData);
    final tnrDataBold =
        await rootBundle.load('assets/fonts/times new roman bold.ttf');
    final timesNewRomanBold = pw.Font.ttf(tnrDataBold);

    final headerImageData = await rootBundle.load('assets/icons/logo.png');
    final headerImage = pw.MemoryImage(headerImageData.buffer.asUint8List());

    final numberFormat = NumberFormat.decimalPattern();

    // Build headers dynamically
    List<String> headers = ['No.'];
    List<String> subHeaders = [''];
    for (var key in _selectedKeysOrdered) {
      if (key == 'all_products' && widget.allProducts) {
        for (var product in products) {
          headers.add(product);
          headers.add('');
          headers.add('');
          headers.add('');
          subHeaders.add('Size');
          subHeaders.add('Income (P)');
          subHeaders.add('Per Cycle');
          subHeaders.add('Per Year');
        }
      } else {
        headers
            .add(availableFields.firstWhere((f) => f['key'] == key)['header']!);
        subHeaders.add('');
      }
    }

    // Fetch all product data if "all_products" is selected
    List<Map<String, dynamic>> allProductData = [];
    if (widget.allProducts && _selectedKeysOrdered.contains('all_products')) {
      final respondentList = await _dbHelper.queryAllRespondents();
      for (var respondent in respondentList) {
        Map<String, dynamic> respondentData = {
          'id': respondent['id'],
          'full_name': _formatNameFromMap(respondent),
          'age': respondent['age'].toString(),
          'total_area': 0.0,
          'products': <String, Map<String, dynamic>>{},
        };
        double totalArea = 0.0;
        for (var productName in products) {
          final products =
              await _dbHelper.queryProductsByRespondent(respondent['id']);
          final matchingProducts = products.where((p) {
            final harvestDate =
                DateTime.parse(p['crop_harvest_date_every_product']);
            return p['product_name'] == productName &&
                harvestDate.year == widget.selectedYear;
          }).toList();

          if (matchingProducts.isNotEmpty) {
            int productIncome = 0;
            double productArea = 0.0;
            int cropCount = matchingProducts.length; // Number of cycles
            for (var product in matchingProducts) {
              productIncome +=
                  (product['crop_harvest_income_every_product'] as num?)
                          ?.toInt() ??
                      0;
              productArea = (product['area_hectares_every_product'] as num?)
                      ?.toDouble() ??
                  0.0;
            }
            respondentData['products'][productName] = {
              'size': productArea,
              'income': productIncome,
              'per_cycle': cropCount,
              'per_year':
                  productIncome, // Income per year is the same as total income here
            };
            totalArea += productArea;
          }
        }
        respondentData['total_area'] = totalArea;
        if (respondentData['products'].isNotEmpty) {
          allProductData.add(respondentData);
        }
      }
    }

    List<List<String>> dataRows = widget.allProducts
        ? allProductData.map((respondent) {
            List<String> row = [respondent['id'].toString()];
            for (var key in _selectedKeysOrdered) {
              switch (key) {
                case 'full_name':
                  row.add(respondent['full_name']);
                  break;
                case 'id':
                  row.add(respondent['id'].toString());
                  break;
                case 'age':
                  row.add(respondent['age']);
                  break;
                case 'all_products':
                  for (var product in products) {
                    row.add(respondent['products'][product]?['size'] != null
                        ? '${respondent['products'][product]['size']} has.'
                        : '0 has.');
                    row.add(numberFormat.format(
                        respondent['products'][product]?['income'] ?? 0));
                    row.add(respondent['products'][product]?['per_cycle']
                            ?.toString() ??
                        '0');
                    row.add(numberFormat.format(
                        respondent['products'][product]?['per_year'] ?? 0));
                  }
                  break;
                case 'area':
                  row.add('${respondent['total_area']} has.');
                  break;
                default:
                  row.add('');
              }
            }
            return row;
          }).toList()
        : widget.respondents.map((respondent) {
            List<String> row = [respondent.id.toString()];
            for (var key in _selectedKeysOrdered) {
              switch (key) {
                case 'full_name':
                  row.add(_formatName(respondent));
                  break;
                case 'id':
                  row.add(respondent.id.toString());
                  break;
                case 'age':
                  row.add(respondent.age.toString());
                  break;
                case 'all_products':
                  row.add(widget.selectedProduct);
                  break;
                case 'area':
                  row.add('${respondent.area} has.');
                  break;
                default:
                  row.add('');
              }
            }
            return row;
          }).toList();

    final int count = headers.length;
    double headerFontSize = count <= 10
        ? 10
        : count <= 15
            ? 8
            : 6;
    double dataFontSize = count <= 10
        ? 10
        : count <= 15
            ? 8
            : 6;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Image(headerImage, width: 70, height: 70),
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Farmers Record System',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                font: timesNewRomanBold,
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            widget.allProducts
                                ? 'All Products'
                                : 'Product: ${widget.selectedProduct}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                font: timesNewRoman, fontSize: 10)),
                        pw.Text('Year: ${widget.selectedYear}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                font: timesNewRoman, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 70),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 3, color: PdfColors.green),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.2),
            columnWidths: {
              for (int i = 0; i < headers.length; i++)
                i: i == 0
                    ? const pw.FixedColumnWidth(30)
                    : headers[i] == 'Full Name'
                        ? const pw.FixedColumnWidth(120)
                        : const pw.FixedColumnWidth(50),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green),
                children: headers
                    .map((header) => pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(header,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: headerFontSize,
                                  color: PdfColors.white)),
                        ))
                    .toList(),
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green),
                children: subHeaders
                    .map((subHeader) => pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(subHeader,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: headerFontSize - 2,
                                  color: PdfColors.white)),
                        ))
                    .toList(),
              ),
              ...dataRows.asMap().entries.map((entry) => pw.TableRow(
                    children: entry.value
                        .asMap()
                        .entries
                        .map((cell) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                  cell.key == 0
                                      ? '${entry.key + 1}'
                                      : cell.value,
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(fontSize: dataFontSize)),
                            ))
                        .toList(),
                  )),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  String _formatName(Respondent r) {
    String middleInitial =
        r.middleName.isNotEmpty ? '${r.middleName[0]}. ' : '';
    String suffix = r.suffix.isNotEmpty ? ' ${r.suffix}' : '';
    return '${r.firstName} $middleInitial${r.lastName}$suffix';
  }

  String _formatNameFromMap(Map<String, dynamic> r) {
    String middleInitial =
        r['middle_name']?.isNotEmpty == true ? '${r['middle_name'][0]}. ' : '';
    String suffix = r['suffix']?.isNotEmpty == true ? ' ${r['suffix']}' : '';
    return '${r['first_name']} $middleInitial${r['last_name']}$suffix';
  }

  void _toggleField(String fieldKey) {
    setState(() {
      if (_selectedKeysOrdered.contains(fieldKey)) {
        _selectedKeysOrdered.remove(fieldKey);
      } else if (_selectedKeysOrdered.length < 10) {
        _selectedKeysOrdered.add(fieldKey);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You can select a maximum of 10 fields.")),
        );
      }
    });
  }

  Widget _buildFieldSelectionPanel() {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;
    return Container(
      width: 320,
      padding: const EdgeInsets.all(8.0),
      color: isDarkMode
          ? const Color.fromARGB(255, 38, 38, 42)
          : const Color.fromRGBO(245, 245, 247, 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Selected Fields',
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 8),
          Container(
            height: 150,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                border: Border.all(
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                    width: 0.7),
                borderRadius: BorderRadius.circular(4)),
            child: _selectedKeysOrdered.isNotEmpty
                ? ReorderableWrap(
                    spacing: 8,
                    runSpacing: 8,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        final item = _selectedKeysOrdered.removeAt(oldIndex);
                        _selectedKeysOrdered.insert(newIndex, item);
                      });
                    },
                    children: _selectedKeysOrdered.map((selectedKey) {
                      final field = availableFields
                          .firstWhere((f) => f['key'] == selectedKey);
                      return Chip(
                        key: ValueKey(selectedKey),
                        label: Text(field['header']!,
                            style: TextStyle(
                                fontFamily: 'Gilroy',
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 10)),
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                                width: 0.5),
                            borderRadius: BorderRadius.circular(2)),
                      );
                    }).toList(),
                  )
                : Center(
                    child: Text('No fields selected',
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            color:
                                isDarkMode ? Colors.white70 : Colors.black87)),
                  ),
          ),
          const SizedBox(height: 16),
          Text('Available Fields',
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3,
              children: availableFields.map((field) {
                final fieldKey = field['key']!;
                final isSelected = _selectedKeysOrdered.contains(fieldKey);
                return GestureDetector(
                  onTap: () => _toggleField(fieldKey),
                  child: Card(
                    color:
                        isSelected ? Colors.green.shade700 : Colors.transparent,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                            width: 0.5),
                        borderRadius: BorderRadius.circular(2)),
                    child: Center(
                      child: Text(field['header']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printing', style: TextStyle(fontFamily: 'Gilroy')),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          _buildFieldSelectionPanel(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Container(
              color: isDarkMode
                  ? const Color.fromARGB(255, 38, 38, 40)
                  : const Color.fromARGB(255, 237, 237, 240),
              child: Theme(
                data: Theme.of(context).copyWith(
                  scaffoldBackgroundColor: isDarkMode
                      ? const Color.fromARGB(255, 38, 38, 40)
                      : const Color.fromARGB(255, 237, 237, 240),
                  canvasColor: isDarkMode
                      ? const Color.fromARGB(255, 38, 38, 40)
                      : const Color.fromARGB(255, 237, 237, 240),
                  appBarTheme: AppBarTheme(
                      backgroundColor: isDarkMode ? Colors.black : Colors.green,
                      foregroundColor: Colors.white),
                ),
                child: PdfPreview(
                  key: ValueKey(_selectedKeysOrdered.join(',')),
                  build: (format) => _generatePdf(format),
                  pageFormats: const {
                    'A4': PdfPageFormat.a4,
                    'Letter': PdfPageFormat.letter,
                    'Legal': PdfPageFormat.legal,
                  },
                  pdfPreviewPageDecoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color.fromARGB(255, 45, 45, 45)
                          : const Color.fromARGB(255, 245, 245, 255)),
                  actionBarTheme: PdfActionBarTheme(
                      backgroundColor: isDarkMode
                          ? const Color.fromARGB(255, 26, 26, 28)
                          : const Color.fromARGB(255, 71, 71, 71)),
                  initialPageFormat: PdfPageFormat.legal,
                  allowSharing: true,
                  allowPrinting: true,
                  canChangePageFormat: true,
                  canDebug: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
