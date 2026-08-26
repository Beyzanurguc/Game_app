import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_settings.dart';
import 'settings_storage.dart';

/// Ad kutusu — giriş sayfası ile ayarlar sayfası aynı kutuyu kullanır.
///
/// Yalnızca harf ve boşluk kabul eder, [maxChildNameLength] karakterde durur;
/// böylece kaydetmeden önceki [sanitizeChildName] temizliğiyle aynı sonucu
/// verir ve kullanıcı ne yazdıysa onu görür.
class ChildNameField extends StatelessWidget {
  const ChildNameField({
    super.key,
    required this.controller,
    this.fieldKey,
    this.hintText = 'Adını yazabilirsin',
    this.onChanged,
  });

  final TextEditingController controller;

  /// Testlerde aranan kutu anahtarı — sarmalayanın değil, kutunun kendisinin.
  final Key? fieldKey;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      maxLength: maxChildNameLength,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
      cursorColor: AppColors.foxOrange,
      // Sayı ve işaretler kutuya hiç girmez; yalnızca harf ve boşluk.
      inputFormatters: [FilteringTextInputFormatter.allow(childNameCharacters)],
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppText.bodyLg.copyWith(color: AppColors.outline),
        counterStyle: AppText.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border(AppColors.outlineVariant),
        enabledBorder: border(AppColors.outlineVariant),
        focusedBorder: border(AppColors.foxOrange, 2),
      ),
    );
  }
}

/// Günlük oyun limiti sürgüsü: değer rozeti, sürgü ve uç etiketleri.
///
/// Sınırlar [minDailyGameLimit]/[maxDailyGameLimit] ile tek yerden gelir.
class DailyLimitSlider extends StatelessWidget {
  const DailyLimitSlider({
    super.key,
    required this.limit,
    required this.onChanged,
    this.valueKey,
    this.sliderKey,
  });

  /// Sürgünün anlık değeri; gösterilirken tam sayıya yuvarlanır.
  final double limit;
  final ValueChanged<double> onChanged;

  /// Değer rozetinin ve sürgünün testlerde aranan anahtarları.
  final Key? valueKey;
  final Key? sliderKey;

  @override
  Widget build(BuildContext context) {
    final value = limit.round();

    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.bandanaTeal, width: 2),
            ),
            child: Text(
              value == 1 ? 'Günde 1 oyun' : 'Günde $value oyun',
              key: valueKey,
              style: AppText.titleMd.copyWith(color: AppColors.secondary),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 14,
            activeTrackColor: AppColors.foxOrange,
            inactiveTrackColor: Colors.white,
            thumbColor: Colors.white,
            overlayColor: AppColors.foxOrange.withValues(alpha: 0.15),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            key: sliderKey,
            value: limit,
            min: minDailyGameLimit.toDouble(),
            max: maxDailyGameLimit.toDouble(),
            divisions: maxDailyGameLimit - minDailyGameLimit,
            label: '$value',
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$minDailyGameLimit',
                style: AppText.labelSm.copyWith(color: AppColors.secondary),
              ),
              Text(
                'en fazla $maxDailyGameLimit',
                style: AppText.labelSm.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
