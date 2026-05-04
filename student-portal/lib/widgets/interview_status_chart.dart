import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 360;

        final chart = AspectRatio(
          aspectRatio: 1,
          child: PieChart(
            PieChartData(
              sections: _showingSections(
                pendingCount,
                acceptedCount,
                scheduledCount,
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: isSmall ? 30 : 40,
            ),
          ),
        );

        final legend = Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const <Widget>[
            Indicator(
              color: Colors.orange,
              text: 'Pending',
              isSquare: true,
              gradient: LinearGradient(
                colors: [Colors.orangeAccent, Colors.deepOrange],
              ),
            ),
            Indicator(
              color: Colors.green,
              text: 'Accepted',
              isSquare: true,
              gradient: LinearGradient(
                colors: [Colors.greenAccent, Colors.green],
              ),
            ),
            Indicator(
              color: Colors.blue,
              text: 'Scheduled',
              isSquare: true,
              gradient: LinearGradient(
                colors: [Colors.lightBlueAccent, Colors.blue],
              ),
            ),
          ],
        );

        if (isSmall) {
          return Column(
            children: [
              SizedBox(height: 200, child: chart),
              const SizedBox(height: 12),
              legend,
            ],
          );
        }

        return AspectRatio(
          aspectRatio: 1.3,
          child: Row(
            children: <Widget>[
              Expanded(child: chart),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Indicator(
                      color: Colors.orange,
                      text: 'Pending',
                      isSquare: true,
                      gradient: LinearGradient(
                        colors: [Colors.orangeAccent, Colors.deepOrange],
                      ),
                    ),
                    SizedBox(height: 6),
                    Indicator(
                      color: Colors.green,
                      text: 'Accepted',
                      isSquare: true,
                      gradient: LinearGradient(
                        colors: [Colors.greenAccent, Colors.green],
                      ),
                    ),
                    SizedBox(height: 6),
                    Indicator(
                      color: Colors.blue,
                      text: 'Scheduled',
                      isSquare: true,
                      gradient: LinearGradient(
                        colors: [Colors.lightBlueAccent, Colors.blue],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _showingSections(
    int pending,
    int accepted,
    int scheduled,
  ) {
    return List.generate(3, (i) {
      const fontSize = 16.0;
      const radius = 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      switch (i) {
        case 0:
          return PieChartSectionData(
            gradient: const LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
            ),
            value: pending.toDouble(),
            title: pending.toString(),
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 1:
          return PieChartSectionData(
            gradient: const LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
            ),
            value: accepted.toDouble(),
            title: accepted.toString(),
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 2:
          return PieChartSectionData(
            gradient: const LinearGradient(
              colors: [Colors.lightBlueAccent, Colors.blue],
            ),
            value: scheduled.toDouble(),
            title: scheduled.toString(),
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        default:
          throw Error();
      }
    });
  }
}

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
    this.gradient,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: gradient == null ? color : null,
            gradient: gradient,
            borderRadius: isSquare ? BorderRadius.circular(4) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
