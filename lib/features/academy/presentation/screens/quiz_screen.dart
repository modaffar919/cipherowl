import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import '../../data/academy_content.dart';
import '../../domain/entities/academy_module.dart';
import '../bloc/academy_bloc.dart';

class QuizScreen extends StatefulWidget {
  final String moduleId;

  const QuizScreen({super.key, required this.moduleId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late final AcademyModule _module;
  int _currentIndex = 0;
  int? _selectedChoice;
  bool _revealed = false;
  int _correctCount = 0;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _module = AcademyContent.modules
        .firstWhere((m) => m.id == widget.moduleId);
    _animCtrl = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  QuizQuestion get _question => _module.quiz[_currentIndex];
  bool get _isLast => _currentIndex == _module.quiz.length - 1;
  Color get _moduleColor => Color(_module.colorValue);

  void _onChoiceTap(int index) {
    if (_revealed) return;
    setState(() {
      _selectedChoice = index;
      _revealed = true;
      if (index == _question.correctIndex) _correctCount++;
    });
    context.read<AcademyBloc>().add(AcademyQuizAnswered(
          questionIndex: _currentIndex,
          selectedChoice: index,
        ));
  }

  void _onNext() {
    if (_isLast) {
      _finishQuiz();
      return;
    }
    _animCtrl.reset();
    setState(() {
      _currentIndex++;
      _selectedChoice = null;
      _revealed = false;
    });
    _animCtrl.forward();
  }

  void _finishQuiz() {
    context
        .read<AcademyBloc>()
        .add(AcademyModuleCompleted(widget.moduleId));
    _showResultDialog();
  }

  void _showResultDialog() {
    final total = _module.quiz.length;
    final pct = (_correctCount / total * 100).round();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.surfaceDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          pct >= 70 ? '🎉 أحسنت!' : '📚 حاول مجدداً',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              '$_correctCount / $total إجابات صحيحة ($pct%)',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.accentGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${_module.xpReward} XP',
                style: const TextStyle(
                    color: AppConstants.accentGold,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // back to module detail
            },
            child: const Text('العودة للأكاديمية',
                style: TextStyle(
                    color: AppConstants.primaryCyan,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _moduleColor;
    final total = _module.quiz.length;

    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _module.titleAr,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / $total',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Progress Bar ─────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / total,
                  backgroundColor: AppConstants.cardDark,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 28),

              // ── Question ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: color.withOpacity(0.25)),
                ),
                child: Text(
                  _question.questionAr,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.5),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 20),

              // ── Choices ──────────────────────────────────────────────────
              ...List.generate(_question.choicesAr.length, (i) {
                final isSelected = _selectedChoice == i;
                final isCorrect = i == _question.correctIndex;
                Color borderColor = AppConstants.borderDark;
                Color bgColor = AppConstants.cardDark;
                Color textColor = Colors.white70;

                if (_revealed) {
                  if (isCorrect) {
                    borderColor = AppConstants.successGreen;
                    bgColor = AppConstants.successGreen.withOpacity(0.08);
                    textColor = AppConstants.successGreen;
                  } else if (isSelected && !isCorrect) {
                    borderColor = AppConstants.errorRed;
                    bgColor = AppConstants.errorRed.withOpacity(0.08);
                    textColor = AppConstants.errorRed;
                  }
                } else if (isSelected) {
                  borderColor = color;
                  bgColor = color.withOpacity(0.08);
                  textColor = color;
                }

                return GestureDetector(
                  onTap: () => _onChoiceTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        if (_revealed)
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : (isSelected
                                    ? Icons.cancel
                                    : Icons.radio_button_unchecked),
                            color: isCorrect
                                ? AppConstants.successGreen
                                : (isSelected
                                    ? AppConstants.errorRed
                                    : Colors.white24),
                            size: 20,
                          )
                        else
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected ? color : Colors.white24,
                            size: 20,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _question.choicesAr[i],
                            style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: isSelected || (_revealed && isCorrect)
                                    ? FontWeight.w600
                                    : FontWeight.normal),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // ── Explanation ──────────────────────────────────────────────
              if (_revealed) ...[
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: _revealed ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryCyan.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppConstants.primaryCyan.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: AppConstants.primaryCyan, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _question.explanationAr,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // ── Next / Finish ────────────────────────────────────────────
              if (_revealed)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _isLast ? 'إنهاء الاختبار 🎯' : 'السؤال التالي ←',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
