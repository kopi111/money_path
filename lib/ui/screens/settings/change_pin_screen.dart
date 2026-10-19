import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_services.dart';
import '../../lock/pin_pad.dart';
import '../../theme/book_palette.dart';

enum _Step { current, choose, confirm }

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const ChangePinScreen());

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  _Step _step = _Step.current;
  String _newPin = '';
  String _message = 'Enter your current PIN.';

  Future<void> _entered(String pin) async {
    final lock = ref.read(appServicesProvider).lock;
    switch (_step) {
      case _Step.current:
        final right = await lock.confirmPinForChange(pin);
        setState(() {
          _step = right ? _Step.choose : _Step.current;
          _message = right ? 'Choose a new 4-digit PIN.' : 'That PIN is not right. Try again.';
        });
      case _Step.choose:
        setState(() {
          _newPin = pin;
          _step = _Step.confirm;
          _message = 'Enter the new PIN again.';
        });
      case _Step.confirm:
        if (pin != _newPin) {
          setState(() {
            _step = _Step.choose;
            _message = 'The PINs did not match. Choose a new PIN again.';
          });
          return;
        }
        await lock.changePin(pin);
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(const SnackBar(content: Text('PIN changed')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Change PIN')),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  _message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: context.book.ink),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              PinPad(key: ValueKey(_step), onComplete: _entered),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
}
