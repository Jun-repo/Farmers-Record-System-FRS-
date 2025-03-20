import 'package:farmers_record/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:farmers_record/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class ProduktoBarChart extends StatefulWidget {
  const ProduktoBarChart({super.key});

  @override
  State<ProduktoBarChart> createState() => _ProduktoBarChartState();
}

class _ProduktoBarChartState extends State<ProduktoBarChart> {
  String selectedView = 'Overall';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Map<String, double> productIncome = {};
  final List<String> products = [
    'PALAY',
    'NIYOG',
    'SAGING',
    'HALAMANG UGAT',
    'PRUTAS',
    'GULAY'
  ];

  // Static demo data
  final Map<String, double> staticDemoData = const {
    'PALAY': 15000.0,
    'NIYOG': 8000.0,
    'SAGING': 12000.0,
    'HALAMANG UGAT': 6000.0,
    'PRUTAS': 9000.0,
    'GULAY': 11000.0,
  };

  @override
  void initState() {
    super.initState();
    _loadProductIncome();
  }

  List<String> _getViewOptions() {
    final currentYear = DateTime.now().year;
    List<String> views = ['Overall'];
    for (int year = 2024; year <= currentYear; year++) {
      views.add(year.toString());
    }
    return views;
  }

  Future<void> _loadProductIncome() async {
    final allProducts = await queryAllProducts();
    Map<String, double> tempIncome = {};

    for (var product in products) {
      tempIncome[product] = 0.0;
    }

    for (var product in allProducts) {
      final productName = product['product_name'] as String;
      final harvestDateString =
          product['crop_harvest_date_every_product'] as String?;
      final income =
          (product['crop_harvest_income_every_product'] as num?)?.toDouble() ??
              0.0;

      if (harvestDateString == null) continue;

      try {
        final harvestDate = DateTime.parse(harvestDateString);
        if (products.contains(productName)) {
          if (selectedView == 'Overall') {
            tempIncome[productName] = (tempIncome[productName] ?? 0.0) + income;
          } else {
            final selectedYear = int.parse(selectedView);
            if (harvestDate.year == selectedYear) {
              tempIncome[productName] =
                  (tempIncome[productName] ?? 0.0) + income;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing date: $e');
        }
      }
    }

    setState(() {
      productIncome = tempIncome;
    });
  }

  Future<List<Map<String, dynamic>>> queryAllProducts() async {
    final db = await _dbHelper.database;
    return await db.query('products');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;
    final displayData = productIncome.isEmpty ? staticDemoData : productIncome;
    final isDemoData = productIncome.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 1, bottom: 8, right: 8, left: 26),
      child: Card(
        color: isDarkMode
            ? const Color.fromARGB(255, 38, 38, 42)
            : const Color.fromRGBO(245, 245, 247, 1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Product Income',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy',
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedView,
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    items: _getViewOptions().map((String view) {
                      return DropdownMenuItem<String>(
                        value: view,
                        child: Text(
                          view,
                          style: const TextStyle(fontFamily: 'Gilroy'),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedView = newValue;
                          _loadProductIncome();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomBarChart(
                data: displayData,
                barColor: isDarkMode
                    ? Colors.lightBlue[200]!
                    : Colors.lightBlueAccent,
                isDemoData: isDemoData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBarChart extends StatelessWidget {
  final Map<String, double> data;
  final Color barColor;
  final bool isDemoData;

  const CustomBarChart({
    super.key,
    required this.data,
    required this.barColor,
    this.isDemoData = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 200),
            painter: BarChartPainter(data: data, barColor: barColor),
          ),
          if (isDemoData)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.05),
                alignment: Alignment.center,
                child: Text(
                  'Sample Preview Data',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Color barColor;

  BarChartPainter({required this.data, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = barColor;

    double maxY = data.values.reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) maxY = 15000.0; // Fallback for demo data
    maxY *= 1.2;

    final double barWidth = size.width / (data.length * 2);
    final double unitHeight = size.height / maxY;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    int index = 0;
    for (var entry in data.entries) {
      final double barHeight = entry.value * unitHeight;
      final double x = index * barWidth * 2 + barWidth / 2;
      final double y = size.height - barHeight;

      // Draw bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      // Draw product name label
      textPainter.text = TextSpan(
        text: entry.key,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          color: Colors.black,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, size.height + 2),
      );

      // Draw value label
      textPainter.text = TextSpan(
        text: NumberFormat.compact().format(entry.value),
        style: const TextStyle(
          fontFamily: 'Gilroy',
          color: Colors.black,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - textPainter.width / 2,
          y - textPainter.height - 5,
        ),
      );

      index++;
    }

    // Draw Y-axis labels
    for (int i = 0; i <= 5; i++) {
      double value = maxY * i / 5;
      double yPos = size.height - (value * unitHeight);

      textPainter.text = TextSpan(
        text: NumberFormat.compact().format(value),
        style: const TextStyle(
          fontFamily: 'Gilroy',
          color: Colors.black,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width - 5, yPos - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
