import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../model/dashboard_data.dart';

class MarketOverviewChart extends StatelessWidget {
  final MarketOverview overview;

  const MarketOverviewChart({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        (overview.totalJobs > overview.totalCompanies
                ? overview.totalJobs
                : overview.totalCompanies)
            .toDouble();
    final maxY = maxVal == 0 ? 10.0 : maxVal * 1.2;

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5], // Dashed lines
              );
            },
          ),
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 8,
              getTooltipItem:
                  (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex,
                  ) {
                    return BarTooltipItem(
                      rod.toY.round().toString(),
                      TextStyle(
                        color: group.x == 0 ? Colors.indigo : Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = 'Companies';
                      break;
                    case 1:
                      text = 'Jobs';
                      break;
                    default:
                      text = '';
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Text(text, style: style),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: overview.totalCompanies.toDouble(),
                  gradient: const LinearGradient(
                    colors: [Colors.indigo, Colors.blue],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 30,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
              showingTooltipIndicators: [0],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: overview.totalJobs.toDouble(),
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.greenAccent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 30,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
              showingTooltipIndicators: [0],
            ),
          ],
        ),
      ),
    );
  }
}
