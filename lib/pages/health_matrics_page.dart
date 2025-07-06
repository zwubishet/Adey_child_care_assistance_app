import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:adde/l10n/arb/app_localizations.dart';

class HealthMetricsPage extends StatefulWidget {
  final String userId;
  const HealthMetricsPage({super.key, required this.userId});

  @override
  State<HealthMetricsPage> createState() => _HealthMetricsPageState();
}

class _HealthMetricsPageState extends State<HealthMetricsPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController bpSysController = TextEditingController();
  final TextEditingController bpDiaController = TextEditingController();
  final TextEditingController hrController = TextEditingController();
  final TextEditingController tempController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  List<Map<String, dynamic>> healthData = [];

  @override
  void initState() {
    super.initState();
    fetchHealthData();
  }

  Future<void> fetchHealthData() async {
    final response = await supabase
        .from('health_metrics')
        .select()
        .eq('user_id', widget.userId)
        .order('created_at', ascending: true);
    setState(() {
      healthData = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> saveHealthData() async {
    final bpSystolic = int.tryParse(bpSysController.text);
    final bpDiastolic = int.tryParse(bpDiaController.text);
    final heartRate = int.tryParse(hrController.text);
    final bodyTemp = double.tryParse(tempController.text);
    final weight = double.tryParse(weightController.text);

    if ([bpSystolic, bpDiastolic, heartRate, bodyTemp, weight].contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invalidValuesError),
        ),
      );
      return;
    }

    try {
      await supabase.from('health_metrics').insert({
        'user_id': widget.userId,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'heart_rate': heartRate,
        'body_temp': bodyTemp,
        'weight': weight,
        'created_at': DateTime.now().toIso8601String(),
      });

      bpSysController.clear();
      bpDiaController.clear();
      hrController.clear();
      tempController.clear();
      weightController.clear();

      fetchHealthData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.dataSavedSuccessfully),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveData)),
      );
    }
  }

  Widget buildLineChart() {
    if (healthData.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.noDataAvailable,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final List<FlSpot> bpSysSpots =
        healthData.asMap().entries.map((e) {
          final value = (e.value['bp_systolic'] as num?)?.toDouble() ?? 0.0;
          return FlSpot(e.key.toDouble(), value);
        }).toList();

    final List<FlSpot> hrSpots =
        healthData.asMap().entries.map((e) {
          final value = (e.value['heart_rate'] as num?)?.toDouble() ?? 0.0;
          return FlSpot(e.key.toDouble(), value);
        }).toList();

    final List<FlSpot> tempSpots =
        healthData.asMap().entries.map((e) {
          final value = (e.value['body_temp'] as num?)?.toDouble() ?? 0.0;
          return FlSpot(e.key.toDouble(), value * 5);
        }).toList();

    final List<FlSpot> weightSpots =
        healthData.asMap().entries.map((e) {
          final value = (e.value['weight'] as num?)?.toDouble() ?? 0.0;
          return FlSpot(e.key.toDouble(), value);
        }).toList();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine:
                (value) => FlLine(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  strokeWidth: 1,
                ),
            getDrawingVerticalLine:
                (value) => FlLine(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  strokeWidth: 1,
                ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final text =
                      value == 0
                          ? "0"
                          : value == 50
                          ? "50"
                          : value == 100
                          ? "100"
                          : value == 150
                          ? "150"
                          : value == 200
                          ? "200"
                          : "";
                  return Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          minY: 0,
          maxY: 200,
          lineBarsData: [
            LineChartBarData(
              spots: bpSysSpots,
              isCurved: true,
              color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: hrSpots,
              isCurved: true,
              color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: tempSpots,
              isCurved: true,
              color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: weightSpots,
              isCurved: true,
              color:
                  isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final data = healthData[index];
                  String label = '';
                  if (spot.barIndex == 0) {
                    label = AppLocalizations.of(
                      context,
                    )!.tooltipBpSys(data['bp_systolic'].toString() as int);
                  } else if (spot.barIndex == 1) {
                    label = AppLocalizations.of(
                      context,
                    )!.tooltipHr(data['heart_rate'].toString() as int);
                  } else if (spot.barIndex == 2) {
                    label = AppLocalizations.of(context)!.tooltipTemp(
                      (data['body_temp'] as num).toStringAsFixed(1) as double,
                    );
                  } else if (spot.barIndex == 3) {
                    label = AppLocalizations.of(context)!.tooltipWeight(
                      (data['weight'] as num).toStringAsFixed(1) as double,
                    );
                  }
                  return LineTooltipItem(
                    label,
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ) ??
                        const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<String> generateRecommendations() {
    final l10n = AppLocalizations.of(context)!;

    if (healthData.isEmpty) {
      return [l10n.noDataRecommendation];
    }

    final latest = healthData.last;
    final bpSys = (latest['bp_systolic'] as num?)?.toInt() ?? 0;
    final bpDia = (latest['bp_diastolic'] as num?)?.toInt() ?? 0;
    final hr = (latest['heart_rate'] as num?)?.toInt() ?? 0;
    final temp = (latest['body_temp'] as num?)?.toDouble() ?? 0.0;
    final weight = (latest['weight'] as num?)?.toDouble() ?? 0.0;

    List<String> recommendations = [];

    if (bpSys < 90 || bpDia < 60) {
      recommendations.add(l10n.bpLowRecommendation(bpSys, bpDia));
    } else if (bpSys > 140 || bpDia > 90) {
      recommendations.add(l10n.bpHighRecommendation(bpSys, bpDia));
    } else {
      recommendations.add(l10n.bpNormalRecommendation(bpSys, bpDia));
    }

    if (hr < 60) {
      recommendations.add(l10n.hrLowRecommendation(hr));
    } else if (hr > 100) {
      recommendations.add(l10n.hrHighRecommendation(hr));
    } else {
      recommendations.add(l10n.hrNormalRecommendation(hr));
    }

    if (temp < 36.0) {
      recommendations.add(l10n.tempLowRecommendation(temp));
    } else if (temp > 37.5) {
      recommendations.add(l10n.tempHighRecommendation(temp));
    } else {
      recommendations.add(l10n.tempNormalRecommendation(temp));
    }

    if (weight < 50) {
      recommendations.add(l10n.weightLowRecommendation(weight));
    } else if (weight > 80) {
      recommendations.add(l10n.weightHighRecommendation(weight));
    } else {
      recommendations.add(l10n.weightNormalRecommendation(weight));
    }

    if (healthData.length > 1) {
      final previous = healthData[healthData.length - 2];
      final prevBpSys = (previous['bp_systolic'] as num?)?.toInt() ?? 0;
      final prevHr = (previous['heart_rate'] as num?)?.toInt() ?? 0;
      final prevWeight = (previous['weight'] as num?)?.toDouble() ?? 0.0;

      if (bpSys > prevBpSys + 10) {
        recommendations.add(
          l10n.bpSysIncreasedRecommendation(prevBpSys, bpSys),
        );
      }
      if (hr > prevHr + 15) {
        recommendations.add(l10n.hrIncreasedRecommendation(prevHr, hr));
      }
      if (weight > prevWeight + 2) {
        recommendations.add(
          l10n.weightIncreasedRecommendation(prevWeight, weight),
        );
      }
    }

    return recommendations.isEmpty
        ? [l10n.allVitalsNormalRecommendation(bpSys, bpDia, hr, temp, weight)]
        : recommendations;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.pageTitleHealthMetrics,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor:
            Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.primary,
        foregroundColor:
            Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onPrimary,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.enterHealthData,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bpSysController,
                decoration: InputDecoration(
                  labelText: l10n.bpSystolicLabel,
                  border: Theme.of(context).inputDecorationTheme.border,
                  focusedBorder:
                      Theme.of(context).inputDecorationTheme.focusedBorder,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bpDiaController,
                decoration: InputDecoration(
                  labelText: l10n.bpDiastolicLabel,
                  border: Theme.of(context).inputDecorationTheme.border,
                  focusedBorder:
                      Theme.of(context).inputDecorationTheme.focusedBorder,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hrController,
                decoration: InputDecoration(
                  labelText: l10n.heartRateLabel,
                  border: Theme.of(context).inputDecorationTheme.border,
                  focusedBorder:
                      Theme.of(context).inputDecorationTheme.focusedBorder,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tempController,
                decoration: InputDecoration(
                  labelText: l10n.bodyTemperatureLabel,
                  border: Theme.of(context).inputDecorationTheme.border,
                  focusedBorder:
                      Theme.of(context).inputDecorationTheme.focusedBorder,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: l10n.weightLabelKg,
                  border: Theme.of(context).inputDecorationTheme.border,
                  focusedBorder:
                      Theme.of(context).inputDecorationTheme.focusedBorder,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: saveHealthData,
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                ),
                child: Text(
                  l10n.saveDataButton,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.recommendationsTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              ...generateRecommendations().map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Text(
                    "• $rec",
                    textAlign: TextAlign.justify,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.healthTrendsTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 5,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        color:
                            isDarkMode
                                ? Colors.blue.shade300
                                : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.bpSystolicLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        color:
                            isDarkMode
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.heartRateLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        color:
                            isDarkMode
                                ? Colors.green.shade300
                                : Colors.green.shade700,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.tempScaledLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        color:
                            isDarkMode
                                ? Colors.orange.shade300
                                : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.weightLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              buildLineChart(),
            ],
          ),
        ),
      ),
    );
  }
}
