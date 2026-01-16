import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/repositories/card_repository.dart';
import 'package:projects/screens/auth/login_screen.dart';
import 'package:projects/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<VocabCard>> _cardsFuture;
  final ICardRepository _cardRepository = locator<ICardRepository>();
  final AuthService _authService = locator<AuthService>();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _cardsFuture = _cardRepository.getAllCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_currentUser != null)
              Column(
                children: [
                  Text(
                    'Logged in as',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _currentUser.email ?? 'No email',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _authService.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<VocabCard>>(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(List<VocabCard> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Skill Level Distribution',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildDonutChart(cards)),
        const SizedBox(height: 24),
        _buildLegend(),
      ],
    );
  }

  Color _getColorForRating(int rating) {
    switch (rating) {
      case 0:
        return Colors.grey[400]!;
      case 1:
        return Colors.red[400]!;
      case 2:
        return Colors.orange[400]!;
      case 3:
        return Colors.yellow[600]!;
      case 4:
        return Colors.lightGreen[500]!;
      case 5:
        return Colors.green[500]!;
      default:
        return Colors.blue;
    }
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(6, (index) {
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: _getColorForRating(index),
            radius: 8,
          ),
          label: Text('$index ★', style: const TextStyle(fontSize: 12)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }),
    );
  }

  Widget _buildDonutChart(List<VocabCard> cards) {
    final Map<int, int> ratingCounts = { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    for (var card in cards) {
      ratingCounts.update(card.rating, (value) => value + 1, ifAbsent: () => 1);
    }

    final List<PieChartSectionData> sections = ratingCounts.entries.map((entry) {
      final isTouched = ratingCounts.keys.toList().indexOf(entry.key) == _touchedIndex;
      final double fontSize = isTouched ? 20.0 : 14.0;
      final double radius = isTouched ? 60.0 : 50.0;
      final color = _getColorForRating(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: entry.value > 0 ? entry.value.toString() : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 70,
            sections: sections,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cards.length.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text('Cards'),
          ],
        ),
      ],
    );
  }
}
