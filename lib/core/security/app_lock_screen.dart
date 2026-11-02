import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_lock_service.dart';

enum AppLockMode {
  unlock,
  setPin,
  verifyToDisable,
}

class AppLockScreen extends StatefulWidget {
  final AppLockMode mode;
  final VoidCallback? onSuccess;

  const AppLockScreen({
    super.key,
    required this.mode,
    this.onSuccess,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String? _firstPin; // Used in setPin mode for confirmation
  String? _errorMessage;
  bool _isConfirmStep = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == AppLockMode.unlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryBiometricUnlock();
      });
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final lockService = Provider.of<AppLockService>(context, listen: false);
    if (lockService.biometricEnabled) {
      final success = await lockService.authenticateWithBiometrics();
      if (success && mounted) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.pop(context, true);
        }
      }
    }
  }

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage = null;
        _enteredPin += val;
      });

      if (_enteredPin.length == 4) {
        _handlePinSubmission();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _handlePinSubmission() async {
    final lockService = Provider.of<AppLockService>(context, listen: false);

    switch (widget.mode) {
      case AppLockMode.unlock:
        final success = await lockService.verifyPin(_enteredPin);
        if (success && mounted) {
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _errorMessage = 'ভুল পিন কোড, আবার চেষ্টা করুন';
            _enteredPin = '';
          });
        }
        break;

      case AppLockMode.setPin:
        if (!_isConfirmStep) {
          setState(() {
            _firstPin = _enteredPin;
            _enteredPin = '';
            _isConfirmStep = true;
          });
        } else {
          if (_enteredPin == _firstPin) {
            await lockService.setPin(_enteredPin);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('পিন কোড সফলভাবে সেট করা হয়েছে')),
              );
              Navigator.pop(context, true);
            }
          } else {
            setState(() {
              _errorMessage = 'পিন কোড মিলেনি, পুনরায় নতুন পিন দিন';
              _enteredPin = '';
              _firstPin = null;
              _isConfirmStep = false;
            });
          }
        }
        break;

      case AppLockMode.verifyToDisable:
        final success = await lockService.verifyPin(_enteredPin);
        if (success && mounted) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = 'ভুল পিন কোড, আবার চেষ্টা করুন';
            _enteredPin = '';
          });
        }
        break;
    }
  }

  String _getHeading() {
    switch (widget.mode) {
      case AppLockMode.unlock:
        return 'Personal Finance';
      case AppLockMode.setPin:
        return _isConfirmStep ? 'পিন কোড নিশ্চিত করুন' : 'নতুন পিন কোড দিন';
      case AppLockMode.verifyToDisable:
        return 'বর্তমান পিন কোড দিন';
    }
  }

  String _getSubHeading() {
    switch (widget.mode) {
      case AppLockMode.unlock:
        return 'সুরক্ষিত ফাইন্যান্স ডাটা অ্যাক্সেস করতে পিন কোড প্রদান করুন';
      case AppLockMode.setPin:
        return _isConfirmStep
            ? 'আগের ৪-ডিজিটের পিন কোডটি পুনরায় লিখুন'
            : '৪-ডিজিটের একটি পিন কোড লিখুন';
      case AppLockMode.verifyToDisable:
        return 'নিরাপত্তা যাচাইয়ের জন্য আপনার পিন কোড লিখুন';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockService = Provider.of<AppLockService>(context);

    return Scaffold(
      backgroundColor:
          const Color(0xFF0F172A), // Dark slate theme for high security feel
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: widget.mode != AppLockMode.unlock
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context, false),
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Lock Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 48,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              _getHeading(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _getSubHeading(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? Colors.blueAccent : Colors.white24,
                    border: Border.all(
                      color: isFilled ? Colors.blueAccent : Colors.white38,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Error Text
            SizedBox(
              height: 24,
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),

            const Spacer(),

            // Keypad Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button (if unlock mode and biometrics enabled)
                      if (widget.mode == AppLockMode.unlock &&
                          lockService.biometricEnabled)
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.fingerprint,
                              color: Colors.blueAccent),
                          onPressed: _tryBiometricUnlock,
                        )
                      else
                        const SizedBox(width: 64, height: 64),

                      _buildKeypadButton('0'),

                      IconButton(
                        iconSize: 28,
                        icon: const Icon(Icons.backspace_outlined,
                            color: Colors.white70),
                        onPressed: _onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((val) => _buildKeypadButton(val)).toList(),
    );
  }

  Widget _buildKeypadButton(String val) {
    return InkWell(
      onTap: () => _onKeyPress(val),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
