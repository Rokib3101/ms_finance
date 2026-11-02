import 'package:flutter/material.dart';
import 'package:ms_finance/core/utils/math_evaluator.dart';
import 'package:ms_finance/core/utils/core_utils.dart';

class AssetCalculatorBottomSheet extends StatefulWidget {
  final String assetName;
  final double initialAmount;

  const AssetCalculatorBottomSheet({
    super.key,
    required this.assetName,
    required this.initialAmount,
  });

  static Future<double?> show(
    BuildContext context, {
    required String assetName,
    required double initialAmount,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AssetCalculatorBottomSheet(
        assetName: assetName,
        initialAmount: initialAmount,
      ),
    );
  }

  @override
  State<AssetCalculatorBottomSheet> createState() =>
      _AssetCalculatorBottomSheetState();
}

class _AssetCalculatorBottomSheetState
    extends State<AssetCalculatorBottomSheet> {
  late String _expression;
  late double _baseAmount;

  @override
  void initState() {
    super.initState();
    _baseAmount = widget.initialAmount;
    _expression = widget.initialAmount == 0
        ? ''
        : MathEvaluator.formatNumber(widget.initialAmount);
  }

  double get _currentResult {
    if (_expression.trim().isEmpty) return 0.0;
    return MathEvaluator.evaluate(_expression, baseValue: _baseAmount) ??
        _baseAmount;
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _expression = '';
      } else if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (key == '=') {
        final result = _currentResult;
        _expression = MathEvaluator.formatNumber(result);
      } else {
        _expression += key;
      }
    });
  }

  void _addQuickAmount(double amount) {
    setState(() {
      final str = MathEvaluator.formatNumber(amount.abs());
      final sign = amount >= 0 ? '+' : '-';

      if (_expression.isEmpty) {
        _expression = '$sign$str';
      } else {
        _expression += '$sign$str';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        widget.assetName.trim().isEmpty ? 'Asset' : widget.assetName.trim();
    final resultVal = _currentResult;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'অ্যাসেট ক্যালকুলেটর',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Previous Balance & Expression Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'পূর্বের পরিমাণ:',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                    Text(
                      '৳ ${BanglaUtils.toBangla(MathEvaluator.formatNumber(_baseAmount))}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                // Expression Display
                Text(
                  _expression.isEmpty ? '0' : BanglaUtils.toBangla(_expression),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 6),
                // Evaluated Result Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'নতুন মোট পরিমাণ:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      '৳ ${BanglaUtils.toBangla(MathEvaluator.formatNumber(resultVal))}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: resultVal >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Addition/Subtraction Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('+১০০', 100),
                _buildQuickChip('+৫০০', 500),
                _buildQuickChip('+১,০০০', 1000),
                _buildQuickChip('+৫,০০০', 5000),
                _buildQuickChip('-১০০', -100),
                _buildQuickChip('-৫০০', -500),
                _buildQuickChip('-১,০০০', -1000),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Keypad Buttons
          _buildKeypad(),
          const SizedBox(height: 16),

          // Apply Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context, resultVal);
            },
            child: Text(
              'যোগফল সেভ করুন (৳ ${BanglaUtils.toBangla(MathEvaluator.formatNumber(resultVal))})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, double val) {
    final isNegative = val < 0;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.red[700] : Colors.green[700],
          ),
        ),
        backgroundColor: isNegative ? Colors.red.shade50 : Colors.green.shade50,
        side: BorderSide(
          color: isNegative ? Colors.red.shade200 : Colors.green.shade200,
        ),
        onPressed: () => _addQuickAmount(val),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['C', '(', ')', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '⌫', '='],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: row.map((key) {
              final isOperator = ['÷', '×', '-', '+', '='].contains(key);
              final isAction = ['C', '(', ')', '⌫'].contains(key);

              Color bg = Colors.grey.shade100;
              Color fg = Colors.black87;

              if (isOperator) {
                bg = const Color(0xFFE0F2FE);
                fg = const Color(0xFF0369A1);
              } else if (key == '=') {
                bg = const Color(0xFF0284C7);
                fg = Colors.white;
              } else if (isAction) {
                bg = Colors.grey.shade200;
                fg = Colors.blueGrey.shade800;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _onKeyPress(key),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: fg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
