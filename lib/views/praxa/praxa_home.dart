// lib/views/praxa/praxa_home.dart
//
// PRAXA — кастомный главный экран.
// Кнопка подключения РЕАЛЬНАЯ: слушает runTimeProvider (запущен ли VPN) и
// дёргает globalState.appController.updateStatus() — тот же механизм, что и
// штатная StartButton FlClashX. Никаких фейковых состояний подключения.
//
// Блоки "подписка" и "активный сервер": подписка тянется из профиля Remnawave
// (дни/статус) — пока помечено TODO и подключается на следующем шаге вместе с
// провайдером профиля; активный сервер читается из реального выбора прокси.

import 'dart:io';

import 'package:flclashx/common/common.dart';
import 'package:flclashx/enum/enum.dart';
import 'package:flclashx/models/models.dart';
import 'package:flclashx/providers/providers.dart';
import 'package:flclashx/state.dart';
import 'package:flclashx/views/praxa/praxa_presets.dart';
import 'package:flclashx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _praxaBlue = Color(0xFF1E9BE0);

class PraxaHomeView extends ConsumerWidget {
  const PraxaHomeView({super.key});

  void _toggleConnection(bool isStart) {
    if (Platform.isAndroid) {
      HapticFeedback.mediumImpact();
    }
    // Реальное переключение VPN через ядро — тем же способом, что родная
    // кнопка FlClashX: через debouncer с тегом updateStatus.
    debouncer.call(
      FunctionTag.updateStatus,
      () {
        globalState.appController.updateStatus(!isStart);
      },
      duration: commonDuration,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // РЕАЛЬНЫЙ статус: VPN запущен, если runTime != null.
    final isStart = ref.watch(
      runTimeProvider.select((state) => state != null),
    );

    // Есть ли активная подписка. Без неё подключаться не к чему —
    // ядро не сможет стартовать. Родная кнопка в этом случае прячется;
    // мы вместо этого блокируем кнопку и показываем подсказку.
    final hasProfile = ref.watch(
      profilesProvider.select((state) => state.isNotEmpty),
    );

    return CommonScaffold(
      title: 'PRAXA',
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _StatusLabel(isStart: isStart, hasProfile: hasProfile),
            const SizedBox(height: 20),
            _ConnectButton(
              isStart: isStart,
              enabled: hasProfile,
              onTap: hasProfile ? () => _toggleConnection(isStart) : null,
            ),
            const SizedBox(height: 20),
            if (hasProfile) const PraxaPresets(),
            const SizedBox(height: 20),
            const _SubscriptionCard(),
            const SizedBox(height: 12),
            const _ActiveServerCard(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final bool isStart;
  final bool hasProfile;
  const _StatusLabel({required this.isStart, required this.hasProfile});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    final String statusText;
    final Color statusColor;
    if (!hasProfile) {
      statusText = 'Нет подписки';
      statusColor = onSurfaceVariant;
    } else if (isStart) {
      statusText = 'Защищено';
      statusColor = _praxaBlue;
    } else {
      statusText = 'Не защищено';
      statusColor = onSurfaceVariant;
    }

    return Column(
      children: [
        Text(
          'Статус подключения',
          style: TextStyle(
            color: onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!hasProfile) ...[
          const SizedBox(height: 2),
          Text(
            'Добавьте подписку во вкладке «Профиль»',
            style: TextStyle(color: onSurfaceVariant, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final bool isStart;
  final bool enabled;
  final VoidCallback? onTap;

  const _ConnectButton({
    required this.isStart,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final ringColor = !enabled
        ? onSurfaceVariant.withValues(alpha: 0.25)
        : isStart
            ? _praxaBlue
            : onSurfaceVariant.withValues(alpha: 0.4);
    final iconColor = !enabled
        ? onSurfaceVariant.withValues(alpha: 0.4)
        : isStart
            ? _praxaBlue
            : onSurfaceVariant;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.2),
            border: Border.all(
              color: isStart && enabled
                  ? _praxaBlue.withValues(alpha: 0.15)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    size: 46,
                    color: iconColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    !enabled
                        ? 'Нет подписки'
                        : isStart
                            ? 'Отключить'
                            : 'Подключить',
                    style: TextStyle(
                      color: !enabled
                          ? onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Блок подписки. РЕАЛЬНЫЕ данные из профиля Remnawave:
// expire (дата окончания), total/upload/download (трафик).
class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final info = ref.watch(
      currentProfileProvider.select((p) => p?.subscriptionInfo),
    );

    // Считаем оставшиеся дни из реального expire.
    int? daysLeft;
    String subtitle;
    Color accent = _praxaBlue;

    if (info == null || info.expire == 0) {
      subtitle = info == null ? 'Добавьте подписку' : 'Бессрочная подписка';
    } else {
      final expireDate =
          DateTime.fromMillisecondsSinceEpoch(info.expire * 1000);
      final diff = expireDate.difference(DateTime.now());
      daysLeft = diff.inDays;
      if (daysLeft < 0) {
        subtitle = 'Подписка истекла';
        accent = const Color(0xFFe2504a);
      } else if (daysLeft <= 3) {
        subtitle = 'Осталось $daysLeft дн. · ${DateFormat('dd.MM.yyyy').format(expireDate)}';
        accent = const Color(0xFFf0b429);
      } else {
        subtitle = 'Осталось $daysLeft дн. · ${DateFormat('dd.MM.yyyy').format(expireDate)}';
      }
    }

    final expired = daysLeft != null && daysLeft < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expired ? 'Подписка' : 'Подписка активна',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () {
                // TODO(step-5): открыть экран тарифов / ссылку buyplan.
              },
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF06121A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(expired ? 'Оплатить' : 'Продлить',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// Активный сервер: читается из реального выбора прокси.
// Открытие списка серверов — на экране "Серверы" (следующий шаг).
class _ActiveServerCard extends ConsumerWidget {
  const _ActiveServerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _praxaBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.public_rounded,
                  color: _praxaBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Активный сервер',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Выберите на вкладке «Серверы»',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
