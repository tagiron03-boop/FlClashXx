// lib/views/praxa/praxa_servers.dart
//
// PRAXA — экран выбора серверов. ВСЕ ДАННЫЕ РЕАЛЬНЫЕ, из подписки Remnawave:
//  - список серверов: currentGroupsStateProvider (живые прокси-группы ядра)
//  - пинг: getDelayProvider (реальные delay-тесты mihomo)
//  - активный сервер: group.now
//  - переключение: appController.changeProxyDebounce (реальная смена узла)
//  - флаг: вытягивается из имени сервера (эмодзи 🇫🇮/🇩🇪 или ISO-код)
//
// Никаких выдуманных серверов. Если подписки нет — список пустой (честно).

import 'package:flclashx/common/common.dart';
import 'package:flclashx/enum/enum.dart';
import 'package:flclashx/models/models.dart';
import 'package:flclashx/providers/providers.dart';
import 'package:flclashx/state.dart';
import 'package:flclashx/views/proxies/common.dart';
import 'package:flclashx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _praxaBlue = Color(0xFF1E9BE0);

// Эмодзи-флаг из ISO-кода (NL -> 🇳🇱).
String _codeToEmoji(String code) {
  if (code.length != 2) return '🌐';
  final upper = code.toUpperCase();
  final first = 0x1F1E6 - 0x41 + upper.codeUnitAt(0);
  final second = 0x1F1E6 - 0x41 + upper.codeUnitAt(1);
  return String.fromCharCodes([first, second]);
}

// Достаёт флаг-эмодзи прямо из имени сервера, если он там есть ("🇳🇱 Amsterdam").
String? _flagFromName(String text) {
  final runes = text.runes.toList();
  for (var i = 0; i < runes.length - 1; i++) {
    final a = runes[i];
    final b = runes[i + 1];
    if (a >= 0x1F1E6 && a <= 0x1F1FF && b >= 0x1F1E6 && b <= 0x1F1FF) {
      final c1 = a - 0x1F1E6 + 0x41;
      final c2 = b - 0x1F1E6 + 0x41;
      return String.fromCharCodes([c1, c2]);
    }
  }
  return null;
}

// Убирает флаг-эмодзи из имени для чистого заголовка.
String _cleanName(String name) {
  final buffer = StringBuffer();
  for (final rune in name.runes) {
    if (rune >= 0x1F1E6 && rune <= 0x1F1FF) continue;
    buffer.writeCharCode(rune);
  }
  return buffer.toString().trim();
}

class PraxaServersView extends ConsumerWidget {
  const PraxaServersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // РЕАЛЬНЫЕ группы из подписки.
    final groups = ref.watch(
      currentGroupsStateProvider.select((state) => state.value),
    );

    // Берём первую группу-селектор (стандартный случай VPN-подписки).
    final selectableGroups = groups
        .where((g) => g.type == GroupType.Selector && g.all.isNotEmpty)
        .toList();

    return CommonScaffold(
      title: 'Серверы',
      body: SafeArea(
        child: selectableGroups.isEmpty
            ? const _EmptyState()
            : _ServersList(group: selectableGroups.first),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public_off_rounded,
                size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Нет доступных серверов',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Добавьте подписку на вкладке «Профиль», '
              'чтобы здесь появились серверы.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServersList extends ConsumerWidget {
  final Group group;
  const _ServersList({required this.group});

  void _select(String proxyName) {
    globalState.appController.changeProxyDebounce(group.name, proxyName);
  }

  void _testAll() {
    delayTest(group.all, group.testUrl);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = group.now;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: Row(
            children: [
              Text(
                'Все локации',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _testAll,
                icon: const Icon(Icons.bolt_rounded, size: 16, color: _praxaBlue),
                label: const Text('Тест пинга',
                    style: TextStyle(color: _praxaBlue, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemCount: group.all.length,
            itemBuilder: (context, index) {
              final proxy = group.all[index];
              return _ServerTile(
                proxy: proxy,
                testUrl: group.testUrl,
                isActive: proxy.name == now,
                onTap: () => _select(proxy.name),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ServerTile extends ConsumerWidget {
  final Proxy proxy;
  final String? testUrl;
  final bool isActive;
  final VoidCallback onTap;

  const _ServerTile({
    required this.proxy,
    required this.testUrl,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // РЕАЛЬНЫЙ пинг сервера.
    final delay = ref.watch(getDelayProvider(
      proxyName: proxy.name,
      testUrl: testUrl,
    ));

    final code = _flagFromName(proxy.name);
    final flag = code != null ? _codeToEmoji(code) : '🌐';
    final title = _cleanName(proxy.name);

    return Material(
      color: isActive
          ? _praxaBlue.withValues(alpha: 0.12)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? _praxaBlue : colorScheme.outlineVariant,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 22)),
                  const Spacer(),
                  if (isActive)
                    const Icon(Icons.check_circle_rounded,
                        color: _praxaBlue, size: 18),
                ],
              ),
              const Spacer(),
              Text(
                title.isEmpty ? proxy.name : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              _DelayLabel(delay: delay),
            ],
          ),
        ),
      ),
    );
  }
}

class _DelayLabel extends StatelessWidget {
  final int? delay;
  const _DelayLabel({required this.delay});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    if (delay == null) {
      return Text('— мс',
          style: TextStyle(color: onSurfaceVariant, fontSize: 12));
    }
    if (delay == 0) {
      return Text('проверка…',
          style: TextStyle(color: onSurfaceVariant, fontSize: 12));
    }

    final color = delay! < 200
        ? const Color(0xFF3ddc84)
        : delay! < 500
            ? const Color(0xFFf0b429)
            : const Color(0xFFe2504a);

    return Row(
      children: [
        Text('$delay мс',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
