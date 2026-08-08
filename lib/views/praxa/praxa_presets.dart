// lib/views/praxa/praxa_presets.dart
//
// PRAXA — пресеты роутинга (простые кнопки для юзера).
//
//  «🇷🇺 RU»          → режим rule + правила: российское напрямую, остальное VPN
//  «🌍 Всё через VPN» → режим global: весь трафик в туннель
//
// Реализация через штатные механизмы FlClashX:
//  - changeMode(Mode.rule/global)
//  - overrideData с addedRules (GEOIP,ru,DIRECT / GEOSITE,category-ru,DIRECT)
//  - setProfile + applyProfileDebounce
//
// БЕЗОПАСНОСТЬ: если RU-правила по какой-то причине не подхватятся конфигом,
// VPN не ломается — просто RU-трафик пойдёт через туннель как обычно.

import 'package:flclashx/common/common.dart';
import 'package:flclashx/enum/enum.dart';
import 'package:flclashx/models/models.dart';
import 'package:flclashx/providers/providers.dart';
import 'package:flclashx/state.dart';
import 'package:flclashx/views/praxa/praxa_ru_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _praxaBlue = Color(0xFF1E9BE0);

// Список RU-правил берётся из praxa_ru_rules.dart (зашит в приложение).
const _ruRuleValues = praxaRuRuleValues;

class PraxaPresets extends ConsumerWidget {
  const PraxaPresets({super.key});

  // Добавляет RU-правила в текущий профиль и включает режим rule.
  void _applyRu(WidgetRef ref) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;

    final ruRules = _ruRuleValues.map((v) => Rule.value(v)).toList();

    globalState.appController.changeMode(Mode.rule);

    // Правильный путь применения override-правил (как в override_profile.dart):
    // updateProfile + setupClashConfigDebounce. НЕ setProfile/applyProfile —
    // тот путь вызывает getConfig timeout.
    ref.read(profilesProvider.notifier).updateProfile(
          profile.id,
          (state) {
            final existing = state.overrideData.rule.addedRules
                .where((r) => !_ruRuleValues.contains(r.value))
                .toList();
            return state.copyWith(
              overrideData: state.overrideData.copyWith(
                enable: true,
                rule: state.overrideData.rule.copyWith(
                  type: OverrideRuleType.added,
                  addedRules: [...ruRules, ...existing],
                ),
              ),
            );
          },
        );
    globalState.appController.setupClashConfigDebounce();
  }

  // Всё через VPN: режим global, наши RU-правила убираем.
  void _applyGlobal(WidgetRef ref) {
    final profile = ref.read(currentProfileProvider);

    globalState.appController.changeMode(Mode.global);

    if (profile != null) {
      ref.read(profilesProvider.notifier).updateProfile(
            profile.id,
            (state) {
              final cleaned = state.overrideData.rule.addedRules
                  .where((r) => !_ruRuleValues.contains(r.value))
                  .toList();
              return state.copyWith(
                overrideData: state.overrideData.copyWith(
                  rule: state.overrideData.rule.copyWith(addedRules: cleaned),
                ),
              );
            },
          );
      globalState.appController.setupClashConfigDebounce();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    // «RU» активна, если режим rule; «Всё» — если global.
    final ruActive = mode == Mode.rule;
    final globalActive = mode == Mode.global;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: _PresetButton(
              emoji: '🇷🇺',
              title: 'RU',
              subtitle: 'Рос. сайты напрямую',
              active: ruActive,
              onTap: () => _applyRu(ref),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PresetButton(
              emoji: '🌍',
              title: 'Всё через VPN',
              subtitle: 'Полная защита',
              active: globalActive,
              onTap: () => _applyGlobal(ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  const _PresetButton({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: active
          ? _praxaBlue.withValues(alpha: 0.15)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? _praxaBlue : colorScheme.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
