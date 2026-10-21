import 'package:flutter/material.dart';

class PinDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool isCreatingNewPin;
  final bool Function(String pin)? onVerify;

  const PinDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.isCreatingNewPin = false,
    this.onVerify,
  });

  static Future<bool> showUnlockDialog(
    BuildContext context, {
    required bool Function(String pin) onVerify,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PinDialog(
        title: 'Buka Catatan Terkunci',
        subtitle: 'Masukkan 4 digit PIN keamanan Anda',
        onVerify: onVerify,
      ),
    );
    return result ?? false;
  }

  static Future<String?> showSetPinDialog(BuildContext context) async {
    return await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const PinDialog(
        title: 'Buat PIN Keamanan Baru',
        subtitle: 'Tentukan 4 digit angka sebagai kode sandi catatan Anda',
        isCreatingNewPin: true,
      ),
    );
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String _enteredPin = '';
  String? _errorMessage;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _submitPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _submitPin() {
    if (widget.isCreatingNewPin) {
      Navigator.of(context).pop(_enteredPin);
    } else {
      if (widget.onVerify != null) {
        final isValid = widget.onVerify!(_enteredPin);
        if (isValid) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = 'PIN salah. Silakan coba lagi.';
            _enteredPin = '';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(120),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            // Indikator 4 Digit Pin Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withAlpha(120),
                    border: Border.all(
                      color: isFilled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 28),
            // Numeric Keypad
            _buildKeypad(theme),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3'], theme),
        const SizedBox(height: 12),
        _buildKeyRow(['4', '5', '6'], theme),
        const SizedBox(height: 12),
        _buildKeyRow(['7', '8', '9'], theme),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 64, height: 52), // empty slot
            _buildKeyButton('0', theme),
            SizedBox(
              width: 64,
              height: 52,
              child: IconButton(
                onPressed: _onDeletePressed,
                icon: const Icon(Icons.backspace_outlined),
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> digits, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeyButton(d, theme)).toList(),
    );
  }

  Widget _buildKeyButton(String digit, ThemeData theme) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 64,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
        ),
        child: Text(
          digit,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
