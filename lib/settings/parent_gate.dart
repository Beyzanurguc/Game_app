import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/squishy.dart';

/// Yetişkin kapısında sorulan çarpma sorusu.
///
/// Çarpım tablosunun üst ucundan seçilir: okul öncesi bir çocuk yapamaz ama
/// yetişkin düşünmeden yanıtlar.
class ParentGateQuestion {
  const ParentGateQuestion(this.first, this.second);

  /// Rastgele bir soru üretir. Testler sabit tohumlu bir [Random] verip
  /// beklenen yanıtı önceden hesaplayabilir.
  ///
  /// [avoid] verilirse onunla aynı yanıta götüren soru üretilmez: yanlış
  /// yanıttan sonra aynı sorunun geri gelmesi hem bozuk görünür hem de
  /// deneme yanılmayı kolaylaştırır.
  factory ParentGateQuestion.generate(
    Random random, {
    ParentGateQuestion? avoid,
  }) {
    ParentGateQuestion question;
    do {
      question = ParentGateQuestion(
        6 + random.nextInt(4),
        6 + random.nextInt(4),
      );
    } while (question.answer == avoid?.answer);
    return question;
  }

  final int first;
  final int second;

  int get answer => first * second;

  /// Ekranda görünen hâli.
  String get text => '$first × $second';
}

/// Yetişkin olduğunu doğrulatır; doğru yanıtta `true` döner.
///
/// Ayarlar sayfası bir ebeveyn alanı: günlük oyun hakkı oradan değiştiriliyor
/// ve çıkış düğmesi ilerlemeyi kalıcı olarak siliyor. Kapı olmasa çocuk kendi
/// sınırını kaldırabilirdi.
///
/// Vazgeçildiğinde ya da pencere kapatıldığında `false` döner. Kapı her
/// açılışta yeniden sorar; "bir süre hatırla" gibi bir kolaylık bilerek yok,
/// çünkü çocuk telefonu elinde tutmaya devam ediyor olabilir.
Future<bool> showParentGate(BuildContext context, {Random? random}) async {
  final passed = await showDialog<bool>(
    context: context,
    // Dışarı dokunup geçilememeli.
    barrierDismissible: false,
    builder: (context) => _ParentGateDialog(random: random ?? Random()),
  );
  return passed ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog({required this.random});

  final Random random;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _controller = TextEditingController();

  late ParentGateQuestion _question = ParentGateQuestion.generate(
    widget.random,
  );

  /// Son deneme yanlış mıydı? Yanlışsa soru değişir ve uyarı gösterilir.
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (int.tryParse(_controller.text) == _question.answer) {
      Navigator.of(context).pop(true);
      return;
    }

    // Yanlış yanıtta yeni soru: aynı soruyu deneyerek geçmek zorlaşsın.
    setState(() {
      _wrong = true;
      _question = ParentGateQuestion.generate(widget.random, avoid: _question);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.gutter),
      child: DepthBox(
        color: AppColors.creamBg,
        depthColor: AppColors.surfaceContainerHighest,
        borderColor: AppColors.bandanaTeal,
        radius: AppRadius.lg,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        // Kutu klavye açılınca daralıyor; küçük ekranlarda taşmasın diye
        // içerik kaydırılabilir.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 44,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 10),
              Text(
                'Bu bölüm yetişkinler için',
                textAlign: TextAlign.center,
                style: AppText.headlineMd.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: 6),
              Text(
                'Devam etmek için soruyu yanıtla.',
                textAlign: TextAlign.center,
                style: AppText.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                key: const ValueKey('parent_gate_question'),
                '${_question.text} = ?',
                textAlign: TextAlign.center,
                style: AppText.displayLg.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              _AnswerField(
                controller: _controller,
                wrong: _wrong,
                onSubmitted: (_) => _submit(),
              ),
              if (_wrong) ...[
                const SizedBox(height: 8),
                Text(
                  key: const ValueKey('parent_gate_error'),
                  'Yanlış yanıt. İşte yeni bir soru.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMd.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 18),
              Squishy(
                key: const ValueKey('parent_gate_submit'),
                onTap: _submit,
                color: AppColors.foxOrange,
                depthColor: AppColors.primary,
                radius: AppRadius.md,
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Center(
                  child: Text(
                    'DEVAM',
                    style: AppText.labelLg.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Squishy(
                key: const ValueKey('parent_gate_cancel'),
                onTap: () => Navigator.of(context).pop(false),
                color: AppColors.surfaceContainerHigh,
                depthColor: AppColors.surfaceContainerHighest,
                radius: AppRadius.md,
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Center(
                  child: Text(
                    'VAZGEÇ',
                    style: AppText.labelLg.copyWith(color: AppColors.primary),
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

/// Yanıt kutusu — yalnızca rakam alır, açılışta kendiliğinden odaklanır.
class _AnswerField extends StatelessWidget {
  const _AnswerField({
    required this.controller,
    required this.wrong,
    required this.onSubmitted,
  });

  final TextEditingController controller;

  /// Son deneme yanlışsa kenarlık kırmızıya döner.
  final bool wrong;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final accent = wrong ? AppColors.error : AppColors.bandanaTeal;

    return TextField(
      key: const ValueKey('parent_gate_answer'),
      controller: controller,
      autofocus: true,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      maxLength: 3,
      style: AppText.headlineMd.copyWith(color: AppColors.onSurface),
      cursorColor: AppColors.foxOrange,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: border(accent),
        enabledBorder: border(accent),
        focusedBorder: border(accent, 2),
      ),
    );
  }
}
