import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:glowmind/theme.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int _range = 0; // 0=Day,1=Week,2=Month

  List<double> _getGlowData() {
    if (_range == 0) return [2, 4, 3, 5, 6, 5, 7];
    if (_range == 1) return [3, 4, 6, 5, 7, 6, 8];
    return [2, 5, 4, 6, 8, 7, 9];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding =
        MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF8B5CF6),
                blurRadius: 25,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Back to Home",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B061A), Color(0xFF1A0F3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight - padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 20),
                    _rangeToggle(),
                    const SizedBox(height: 24),
                    _glowLineChart(),
                    const SizedBox(height: 24),
                    _statsRow(),
                    const SizedBox(height: 20),
                    _emotionRhythm(),
                    const SizedBox(height: 80), // space for button
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return const Text(
      "Insights",
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        shadows: [Shadow(color: Color(0xFF8B5CF6), blurRadius: 14)],
      ),
    );
  }

  Widget _rangeToggle() {
    final labels = ["Day", "Week", "Month"];
    return Row(
      children: List.generate(3, (i) {
        final active = _range == i;
        return GestureDetector(
          onTap: () => setState(() => _range = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: active
                  ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)])
                  : null,
              color: active ? null : Colors.white10,
              boxShadow: active
                  ? [const BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 20)]
                  : [],
            ),
            child: Text(labels[i], style: const TextStyle(color: Colors.white)),
          ),
        );
      }),
    );
  }

  Widget _glowLineChart() {
    final data = _getGlowData();
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  data.length, (i) => FlSpot(i.toDouble(), data[i].toDouble())),
              isCurved: true,
              barWidth: 4,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.4),
                    const Color(0xFF4F46E5).withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _circleStat("Mood Balance", 0.75)),
        const SizedBox(width: 14),
        Expanded(child: _barStat()),
      ],
    );
  }

  Widget _circleStat(String title, double value) {
    return Container(
      height: 140,
      decoration: _cardStyle(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _barStat() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardStyle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (i) {
          final h = (i + 2) * 18.0;
          return Container(
            height: h,
            width: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _emotionRhythm() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 20,
        itemBuilder: (_, i) {
          final colors = [
            const Color(0xFF8B5CF6),
            const Color(0xFF4F46E5),
            Colors.grey,
          ];
          final c = colors[i % 3];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 16,
            decoration: BoxDecoration(
              color: c.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: c, blurRadius: 10)],
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: const Color(0xFF140F28).withOpacity(0.7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF6D4AFF).withOpacity(0.4)),
      boxShadow: const [
        BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 25),
      ],
    );
  }
}
