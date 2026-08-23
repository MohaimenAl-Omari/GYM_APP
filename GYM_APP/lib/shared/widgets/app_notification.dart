import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/responsive.dart';

/// Visual/semantic category for [AppNotification] — drives icon, accent
/// color, haptic weight, and how long the banner stays up.
enum AppNotificationType { error, success, warning, info }

/// Modern top-of-screen notification banner, replacing the default
/// [SnackBar] (which docks at the bottom and is easy to miss mid-workout
/// with the phone held low). Slides + fades in from under the status bar,
/// auto-dismisses, and can be swiped away.
///
/// Usage: `AppNotification.showError(context, 'generic_error'.tr);`
class AppNotification {
  AppNotification._();

  static OverlayEntry? _entry;

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppNotificationType.error);

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppNotificationType.success);

  static void showWarning(BuildContext context, String message) =>
      _show(context, message, AppNotificationType.warning);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, AppNotificationType.info);

  static void _show(BuildContext context, String message, AppNotificationType type) {
    // Only one banner on screen at a time — a fresh one interrupts
    // whatever's currently showing rather than queuing behind it.
    _entry?.remove();
    _entry = null;

    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _NotificationHost(
        message: message,
        type: type,
        duration: type == AppNotificationType.error
            ? const Duration(seconds: 4)
            : const Duration(seconds: 3),
        onRemove: () {
          if (identical(_entry, entry)) _entry = null;
          entry.remove();
        },
      ),
    );
    _entry = entry;
    overlayState.insert(entry);
  }
}

class _NotificationHost extends StatefulWidget {
  const _NotificationHost({
    required this.message,
    required this.type,
    required this.duration,
    required this.onRemove,
  });

  final String message;
  final AppNotificationType type;
  final Duration duration;
  final VoidCallback onRemove;

  @override
  State<_NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends State<_NotificationHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  Timer? _timer;
  double _dragOffset = 0;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _triggerHaptic();
    _timer = Timer(widget.duration, _dismiss);
  }

  void _triggerHaptic() {
    switch (widget.type) {
      case AppNotificationType.error:
        HapticFeedback.heavyImpact();
        break;
      case AppNotificationType.warning:
        HapticFeedback.mediumImpact();
        break;
      case AppNotificationType.success:
      case AppNotificationType.info:
        HapticFeedback.lightImpact();
        break;
    }
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    if (mounted) await _controller.reverse();
    widget.onRemove();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              16.rs(context),
              topInset + 8.rs(context),
              16.rs(context),
              0,
            ),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy >= 0) return;
                setState(() => _dragOffset += details.delta.dy);
              },
              onVerticalDragEnd: (_) {
                if (_dragOffset < -24) {
                  _dismiss();
                } else {
                  setState(() => _dragOffset = 0);
                }
              },
              child: Transform.translate(
                offset: Offset(0, _dragOffset.clamp(-80, 0)),
                child: _NotificationCard(
                  message: widget.message,
                  type: widget.type,
                  onClose: _dismiss,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.message,
    required this.type,
    required this.onClose,
  });

  final String message;
  final AppNotificationType type;
  final VoidCallback onClose;

  Color get _accent {
    switch (type) {
      case AppNotificationType.error:
        return AppColors.error;
      case AppNotificationType.success:
        return AppColors.success;
      case AppNotificationType.warning:
        return AppColors.warning;
      case AppNotificationType.info:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (type) {
      case AppNotificationType.error:
        return Icons.error_rounded;
      case AppNotificationType.success:
        return Icons.check_circle_rounded;
      case AppNotificationType.warning:
        return Icons.warning_rounded;
      case AppNotificationType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(
          14.rs(context),
          14.rs(context),
          10.rs(context),
          14.rs(context),
        ),
        decoration: BoxDecoration(
          color: AppColors.darkCardElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: accent, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14.rf(context),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textGrey,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              splashRadius: 22,
            ),
          ],
        ),
      ),
    );
  }
}
