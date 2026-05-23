import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import '../model/dashboard_data.dart';

class InterviewStatusChart extends StatelessWidget {
  final InterviewStats stats;

  const InterviewStatusChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final pendingCount = stats.pendingRequests.length;
    final acceptedCount = stats.acceptedRequests.length;
    final scheduledCount = stats.allInterviews
        .where((i) => i.scheduledTime != null)
        .length;

    // If no data, show a message or empty chart
    if (pendingCount == 0 && acceptedCount == 0 && scheduledCount == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No interview data available')),
      );
    }

    final dataMap = <String, double>{
      "Pending ($pendingCount)": pendingCount.toDouble(),
      "Accepted ($acceptedCount)": acceptedCount.toDouble(),
      "Scheduled ($scheduledCount)": scheduledCount.toDouble(),
    };

    final gradientList = <List<Color>>[
      [Colors.orangeAccent, Colors.deepOrange],
      [Colors.greenAccent, Colors.green],
      [Colors.lightBlueAccent, Colors.blue],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 360;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: PieChart(
            dataMap: dataMap,
            animationDuration: const Duration(milliseconds: 800),
            chartLegendSpacing: 32,
            chartRadius: isSmall ? 120 : 160,
            gradientList: gradientList,
            emptyColor: Colors.grey.shade200,
            emptyColorGradient: [Colors.grey.shade200, Colors.grey.shade300],
            initialAngleInDegree: 0,
            chartType: ChartType.ring,
            ringStrokeWidth: isSmall ? 20 : 26,
            legendOptions: LegendOptions(
              showLegendsInRow: isSmall,
              legendPosition: isSmall ? LegendPosition.bottom : LegendPosition.right,
              showLegends: true,
              legendShape: BoxShape.circle,
              legendTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            chartValuesOptions: const ChartValuesOptions(
              showChartValueBackground: false,
              showChartValues: false, // We hid labels since they are in legend
              showChartValuesInPercentage: false,
              showChartValuesOutside: false,
            ),
          ),
        );
      },
    );
  }
}
