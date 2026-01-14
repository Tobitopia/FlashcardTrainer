import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/repositories/card_repository.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<List<VocabCard>> _cardsFuture;
  final ICardRepository _cardRepository = locator<ICardRepository>();

  @override
  void initState() {
    super.initState();
    _cardsFuture = _cardRepository.getAllCards();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VocabCard>>(
      future: _cardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No card data available."));
        } else {
          final cards = snapshot.data!;
          return _buildCharts(cards);
        }
      },
    );
  }

  Widget _buildCharts(List<VocabCard> cards) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Skill Level',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildRatingChart(cards)),
        ],
      ),
    );
  }

  Widget _buildRatingChart(List<VocabCard> cards) {
    final Map<int, int> ratingCounts = { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };

    for (var card in cards) {
      ratingCounts.update(card.rating, (value) => value + 1, ifAbsent: () => 1);
    }

    final barGroups = ratingCounts.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: ratingCounts.values.isEmpty ? 1 : ratingCounts.values.reduce(max).toDouble() + 1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '${value.toInt()} ★';
                return Text(text, style: const TextStyle(fontSize: 10));
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0 && value > 0) {
                  return Text(value.toInt().toString());
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        barGroups: barGroups,
      ),
    );
  }
}
