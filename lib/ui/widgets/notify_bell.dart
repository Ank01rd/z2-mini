import 'package:flutter/foundation.dart'; // 👈 Добавь эту строку
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/notify_service.dart';
import '../../core/ui_scale.dart';

/// 🔔 Dynamic Island + адаптивное позиционирование под сайдбар:
///    сайдбар слева/справа → тосты сверху в противоположном углу
///    сайдбар сверху      → тосты справа-снизу (под рельсом)
///    сайдбар снизу       → тосты справа-сверху (над рельсом)
class NotifyBell extends StatefulWidget {
  final AppTheme theme;
  final ValueListenable<int> sidebarPos;
  const NotifyBell({
    super.key,
    required this.theme,
    required this.sidebarPos,
  });
  @override
  State<NotifyBell> createState() => _NotifyBellState();
}

class _NotifyBellState extends State<NotifyBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    NotifyService.banner.addListener(_onBanner);
  }

  void _onBanner() {
    final v = NotifyService.banner.value;
    if (v != null && v.progress == null) _ring.forward(from: 0);
  }

  void _tap(NotifyItem? banner) {
    if (banner != null) {
      final act = banner.onTap;
      NotifyService.dismiss();
      act?.call();
      return;
    }
    _ring.forward(from: 0);
  }

  @override
  void dispose() {
    NotifyService.banner.removeListener(_onBanner);
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    // 📍 позиция тоста в зависимости от сайдбара
    return ValueListenableBuilder<int>(
      valueListenable: widget.sidebarPos,
      builder: (ctx, pos, _) {
        final bool leftCorner = pos == 1; // сайдбар справа → тост слева
        final bool useBottom = pos == 1 || pos == 2; // справа/сверху → тост снизу
        return Positioned(
          top: useBottom ? null : sc(80),
          bottom: useBottom ? sc(20) : null,
          left: leftCorner ? sc(12) : null,
          right: leftCorner ? null : sc(12),
          child: ValueListenableBuilder<NotifyItem?>(
            valueListenable: NotifyService.banner,
            builder: (ctx, banner, _) {
              final showResults = banner != null && banner.lines != null;
              final showProgress = banner != null && banner.progress != null;
              final expanded = banner != null;
              final double w = !expanded
                  ? sc(44)
                  : showResults
                      ? sc(310)
                      : showProgress
                          ? sc(280)
                          : sc(320);
              final double h = showResults
                  ? (sc(60) + banner!.lines!.length * sc(28) + sc(8))
                      .clamp(sc(44), sc(320))
                  : showProgress
                      ? sc(58)
                      : sc(44);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _tap(banner),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.92),
                    borderRadius:
                        BorderRadius.circular(h > sc(60) ? sc(28) : 999),
                    border: expanded
                        ? null
                        : Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: sc(14),
                          offset: Offset(0, sc(4))),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(h > sc(60) ? sc(28) : 999),
                    child: Stack(children: [
                      if (expanded)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          right: sc(44),
                          child: LayoutBuilder(builder: (ctx, c) {
                            if (c.maxWidth < sc(90)) return const SizedBox.shrink();
                            return showResults
                                ? _resultsContent(t, banner!)
                                : showProgress
                                    ? _progressContent(t, banner!)
                                    : _bannerContent(t, banner!);
                          }),
                        ),
                      expanded
                          ? Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: _cap(t, true,
                                  showProgress ? Icons.download_rounded : null))
                          : Center(child: _cap(t, false)),
                    ]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _cap(AppTheme t, bool active, [IconData? icon]) => SizedBox(
        width: sc(44),
        height: sc(44),
        child: AnimatedBuilder(
          animation: _ring,
          builder: (ctx, child) {
            final v = _ring.value;
            final angle =
                v < 1 ? math.sin(v * math.pi * 4) * 0.22 * (1 - v) : 0.0;
            return Transform.rotate(angle: angle, child: child!);
          },
          child: Center(
            child: Icon(
                icon ??
                    (active
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded),
                color: Colors.white.withOpacity(0.85),
                size: sc(20)),
          ),
        ),
      );

  Widget _bannerContent(AppTheme t, NotifyItem n) => Padding(
        padding: EdgeInsets.only(left: sc(16)),
        child: Row(children: [
          Icon(n.icon, color: t.accent, size: sc(16)),
          SizedBox(width: sc(8)),
          Expanded(
            child: Text(n.text,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sc(13),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none)),
          ),
        ]),
      );

  Widget _progressContent(AppTheme t, NotifyItem n) => Padding(
        padding: EdgeInsets.only(left: sc(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(n.icon, color: t.accent, size: sc(16)),
              SizedBox(width: sc(8)),
              Expanded(
                child: Text(n.text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: sc(12),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none)),
              ),
            ]),
            SizedBox(height: sc(6)),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: n.progress,
                minHeight: sc(5),
                backgroundColor: Colors.white.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(t.accent),
              ),
            ),
          ],
        ),
      );

  Widget _resultsContent(AppTheme t, NotifyItem n) => Padding(
        padding: EdgeInsets.fromLTRB(sc(16), sc(12), sc(10), sc(10)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(n.icon, color: t.accent, size: sc(15)),
                SizedBox(width: sc(6)),
                Expanded(
                  child: Text(n.text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: sc(13),
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.none)),
                ),
              ]),
              SizedBox(height: sc(8)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    for (final l in n.lines!)
                      Padding(
                        padding: EdgeInsets.only(bottom: sc(5)),
                        child: Row(children: [
                          Icon(
                              l.ok
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: sc(14),
                              color: l.ok
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444)),
                          SizedBox(width: sc(6)),
                          Expanded(
                            child: Text(l.text,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: sc(11),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none)),
                          ),
                        ]),
                      ),
                  ]),
                ),
              ),
            ]),
      );
}