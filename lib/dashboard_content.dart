import 'package:farmers_record/dashboard.dart';
import 'package:farmers_record/main.dart';
import 'package:farmers_record/produkto_bar_chart.dart';
import 'package:farmers_record/table_section.dart';
import 'package:flutter/material.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight40 = screenHeight * 0.4;
    final cardHeight60 = screenHeight * 0.6;
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Card(
                    color: isDarkMode
                        ? const Color.fromARGB(255, 38, 38, 42)
                        : const Color.fromRGBO(245, 245, 247, 1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: isDarkMode
                            ? const Color.fromARGB(255, 60, 60, 62)
                            : const Color.fromARGB(255, 255, 255, 255),
                        width: 0.7,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: cardHeight40,
                        child: const ProduktoBarChart(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Card(
                    color: isDarkMode
                        ? const Color.fromARGB(255, 38, 38, 42)
                        : const Color.fromRGBO(245, 245, 247, 1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDarkMode
                            ? const Color.fromARGB(255, 60, 60, 62)
                            : const Color.fromARGB(255, 255, 255, 255),
                        width: 0.7,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: cardHeight40,
                        child: const FarmerRankingWidget(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: isDarkMode
                  ? const Color.fromARGB(255, 38, 38, 42)
                  : const Color.fromRGBO(245, 245, 247, 1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDarkMode
                      ? const Color.fromARGB(255, 60, 60, 62)
                      : const Color.fromARGB(255, 255, 255, 255),
                  width: 0.7,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: cardHeight60,
                  child: const TableSection(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
