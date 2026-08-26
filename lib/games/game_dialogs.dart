import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/squishy.dart';

/// Yarım kalmış oyundan çıkmadan önce onay ister.
Future<bool> confirmExitGame(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => const _ExitGameDialog(),
  );
  return leave ?? false;
}

class _ExitGameDialog extends StatelessWidget {
  const _ExitGameDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: DepthBox(
        color: AppColors.creamBg,
        depthColor: AppColors.surfaceContainerHighest,
        borderColor: AppColors.bandanaTeal,
        radius: AppRadius.lg,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 90, mood: MascotMood.sad),
            const SizedBox(height: 8),
            Text(
              'Şimdiden gidiyor musun?',
              textAlign: TextAlign.center,
              style: AppText.titleMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Bu oyundaki ilerlemen kaydedilmeyecek.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Squishy(
              key: const ValueKey('exit_stay'),
              onTap: () => Navigator.of(context).pop(false),
              color: AppColors.foxOrange,
              depthColor: AppColors.primary,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Center(
                child: Text(
                  'OYUNA DEVAM',
                  style: AppText.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              key: const ValueKey('exit_leave'),
              onTap: () => Navigator.of(context).pop(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Çık',
                  style: AppText.labelLg.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Duraklatma ekranından seçilen işlem.
enum PauseAction { resume, restart, home }

/// Oyunu duraklatır ve ne yapılacağını sorar.
Future<PauseAction?> showPauseDialog(BuildContext context) {
  return showDialog<PauseAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _PauseDialog(),
  );
}

class _PauseDialog extends StatelessWidget {
  const _PauseDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: DepthBox(
        color: AppColors.creamBg,
        depthColor: AppColors.surfaceContainerHighest,
        borderColor: AppColors.bandanaTeal,
        radius: AppRadius.lg,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 90),
            const SizedBox(height: 8),
            Text(
              'Mola verdik',
              style: AppText.headlineMd.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Hazır olunca devam edebilirsin.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Squishy(
              key: const ValueKey('pause_resume'),
              onTap: () => Navigator.of(context).pop(PauseAction.resume),
              color: AppColors.foxOrange,
              depthColor: AppColors.primary,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'DEVAM ET',
                  style: AppText.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Squishy(
              key: const ValueKey('pause_restart'),
              onTap: () => Navigator.of(context).pop(PauseAction.restart),
              color: AppColors.creamBg,
              depthColor: AppColors.surfaceContainerHighest,
              borderColor: AppColors.foxOrange,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'YENİDEN BAŞLA',
                  style: AppText.labelLg.copyWith(color: AppColors.foxOrange),
                ),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              key: const ValueKey('pause_home'),
              onTap: () => Navigator.of(context).pop(PauseAction.home),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Ana sayfaya dön',
                  style: AppText.labelLg.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
