import 'package:flutter/material.dart';

import '../../security/lock_controller.dart';
import '../theme/book_palette.dart';
import 'pin_pad.dart';

/// Covers the whole app, routes and sheets included, until it is unlocked.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.controller, required this.child});

  final LockController controller;
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: widget.controller.wentToBackground,
      onShow: widget.controller.cameBack,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final unlocked = widget.controller.state == AppLockState.unlocked;
          return Listener(
            onPointerDown: (_) => widget.controller.noteActivity(),
            child: Stack(
              children: [
                ExcludeSemantics(excluding: !unlocked, child: TickerMode(enabled: unlocked, child: widget.child)),
                if (!unlocked) Positioned.fill(child: _LockScreen(controller: widget.controller)),
              ],
            ),
          );
        },
      );
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.controller});

  final LockController controller;

  @override
  Widget build(BuildContext context) => Material(
        color: context.book.paper,
        child: SafeArea(
          child: switch (controller.state) {
            AppLockState.checking => const SizedBox.expand(),
            AppLockState.needsPin => _ChoosePin(controller: controller),
            _ => _EnterPin(controller: controller),
          },
        ),
      );
}

class _EnterPin extends StatefulWidget {
  const _EnterPin({required this.controller});

  final LockController controller;

  @override
  State<_EnterPin> createState() => _EnterPinState();
}

class _EnterPinState extends State<_EnterPin> {
  String _message = 'Enter your PIN';
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _offerBiometrics();
  }

  Future<void> _offerBiometrics() async {
    final available = await widget.controller.biometricsAvailable();
    if (!mounted) return;
    setState(() => _canUseBiometrics = available);
    if (available) await widget.controller.tryBiometrics();
  }

  Future<void> _check(String pin) async {
    if (widget.controller.isLockedOut) {
      setState(() => _message = 'Too many tries. Wait ${widget.controller.lockoutRemaining.inSeconds} seconds.');
      return;
    }
    final right = await widget.controller.tryPin(pin);
    if (!right && mounted) {
      setState(() => _message = widget.controller.isLockedOut
          ? 'Too many tries. Wait ${LockController.cooldown.inSeconds} seconds.'
          : 'That PIN is not right. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) => _LockLayout(
        title: 'Money Path is locked',
        message: _message,
        pad: PinPad(
          onComplete: _check,
          extraKey: _canUseBiometrics
              ? IconButton(
                  onPressed: widget.controller.tryBiometrics,
                  icon: const Icon(Icons.fingerprint, semanticLabel: 'Unlock with fingerprint or face'),
                  iconSize: 36,
                )
              : null,
        ),
      );
}

class _ChoosePin extends StatefulWidget {
  const _ChoosePin({required this.controller});

  final LockController controller;

  @override
  State<_ChoosePin> createState() => _ChoosePinState();
}

class _ChoosePinState extends State<_ChoosePin> {
  String _firstEntry = '';
  String _message = 'Choose a 4-digit PIN. You will need it to open the app.';

  Future<void> _entered(String pin) async {
    if (_firstEntry.isEmpty) {
      setState(() {
        _firstEntry = pin;
        _message = 'Enter the same PIN again.';
      });
      return;
    }
    if (pin == _firstEntry) {
      await widget.controller.choosePin(pin);
      return;
    }
    setState(() {
      _firstEntry = '';
      _message = 'The PINs did not match. Choose a PIN again.';
    });
  }

  @override
  Widget build(BuildContext context) => _LockLayout(
        title: 'Welcome to Money Path',
        message: _message,
        pad: PinPad(onComplete: _entered),
      );
}

class _LockLayout extends StatelessWidget {
  const _LockLayout({required this.title, required this.message, required this.pad});

  final String title;
  final String message;
  final Widget pad;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Semantics(header: true, child: Text(title, style: text.headlineSmall, textAlign: TextAlign.center)),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    style: text.bodyLarge?.copyWith(color: context.book.inkSoft),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                pad,
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
