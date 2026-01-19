import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/affirmation.dart';
import '../../state/affirmation_state.dart';
import '../../theme.dart';

class RecordAffirmationPage extends StatefulWidget {
  const RecordAffirmationPage({super.key});

  @override
  State<RecordAffirmationPage> createState() => _RecordAffirmationPageState();
}

class _RecordAffirmationPageState extends State<RecordAffirmationPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _breatheController;
  final TextEditingController _textController = TextEditingController();
  AffirmationCategory _selectedCategory = AffirmationCategory.motivation;

  final List<String> _suggestions = [
    "I am worthy of love and respect",
    "I choose peace and happiness today",
    "I am capable of achieving my goals",
    "I release what no longer serves me",
    "I am grateful for this moment",
    "I trust the journey of my life",
    "I am strong, confident, and powerful",
    "I embrace my authentic self",
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _breatheController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B061A), Color(0xFF1A0F3D), Color(0xFF0F0720)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategorySelector(),
                        const SizedBox(height: 28),
                        _buildTextInput(),
                        const SizedBox(height: 24),
                        _buildSuggestions(),
                        const SizedBox(height: 40),
                        _buildRecordSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ).createShader(bounds),
                child: const Text(
                  "Record Affirmation",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Your voice, your power 🎙️",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.close, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AffirmationCategory.values.length,
            itemBuilder: (context, index) {
              final category = AffirmationCategory.values[index];
              final isSelected = category == _selectedCategory;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategory = category);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              category.color,
                              category.color.withValues(alpha: 0.7),
                            ],
                          )
                        : null,
                    color: isSelected ? null : category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : category.color.withValues(alpha: 0.3),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: category.color.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        color: isSelected ? Colors.white : category.color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : category.color,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Affirmation",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _selectedCategory.color.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: _textController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.6,
            ),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Type or speak your affirmation...",
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.amber.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Need inspiration?",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _suggestions.map((suggestion) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _textController.text = suggestion;
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  suggestion,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecordSection() {
    return Consumer<AffirmationState>(
      builder: (context, state, _) {
        final isRecording = state.isRecording;
        final recordingDuration = state.recordingDuration;

        return Column(
          children: [
            // Recording visualization
            if (isRecording) _buildRecordingVisualization(),
            
            // Timer
            if (isRecording) ...[
              const SizedBox(height: 20),
              Text(
                _formatDuration(recordingDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Recording...",
                style: TextStyle(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Record button
            _buildRecordButton(state, isRecording),
            
            const SizedBox(height: 20),
            
            // Save button (when not recording and has text)
            if (!isRecording && _textController.text.isNotEmpty)
              _buildSaveButton(state),
          ],
        );
      },
    );
  }

  Widget _buildRecordingVisualization() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(20, (index) {
              final phase = (index / 20) * 2 * math.pi;
              final height = 20 +
                  math.sin(phase + _waveController.value * 2 * math.pi) * 25 +
                  math.sin(phase * 2 + _waveController.value * 3 * math.pi) * 10;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: height.abs(),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6),
                      const Color(0xFFEC4899),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildRecordButton(AffirmationState state, bool isRecording) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        if (isRecording) {
          if (_textController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Please enter your affirmation text first"),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            return;
          }
          _saveRecording(state);
        } else {
          state.startRecording();
          _pulseController.repeat(reverse: true);
        }
      },
      child: AnimatedBuilder(
        animation: _breatheController,
        builder: (context, child) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isRecording
                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                    : [const Color(0xFF7C3AED), const Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isRecording
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF8B5CF6))
                      .withValues(alpha: 0.5),
                  blurRadius: 30 + (_breatheController.value * 15),
                  spreadRadius: isRecording ? _breatheController.value * 8 : 0,
                ),
              ],
            ),
            child: Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 44,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton(AffirmationState state) {
    return GestureDetector(
      onTap: () => _saveWithoutRecording(state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _selectedCategory.color,
              _selectedCategory.color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _selectedCategory.color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              "Save Without Recording",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveRecording(AffirmationState state) async {
    await state.stopRecordingAndSave(
      text: _textController.text,
      category: _selectedCategory,
    );
    
    _pulseController.stop();
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("Voice affirmation saved! ✨"),
            ],
          ),
          backgroundColor: const Color(0xFF7C3AED),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _saveWithoutRecording(AffirmationState state) {
    state.addCustomAffirmation(
      text: _textController.text,
      category: _selectedCategory,
    );
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Affirmation saved!"),
          ],
        ),
        backgroundColor: _selectedCategory.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
