import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ms_finance/features/finance/presentation/providers/asset_provider.dart';
import 'package:ms_finance/core/utils/core_utils.dart';
import 'package:ms_finance/core/utils/math_evaluator.dart';
import 'package:ms_finance/features/finance/widgets/asset_calculator_bottom_sheet.dart';
import '../data/models/asset.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _newlyAddedAssetId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onAddAssetPressed(AssetProvider provider) async {
    final newId = await provider.addAsset('', 0);
    setState(() {
      _newlyAddedAssetId = newId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = Provider.of<AssetProvider>(context);
    final assets = assetProvider.assets;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Assets'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: assets.isEmpty
                ? const Center(child: Text('No assets added'))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: assets.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      return _AssetItemRow(
                        key: ValueKey(asset.id),
                        asset: asset,
                        autoFocusName: asset.id == _newlyAddedAssetId,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildTotalSection(assetProvider.totalAssetValue),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddAssetPressed(assetProvider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.blueGrey[50],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: const Row(
        children: [
          Expanded(
              flex: 3,
              child:
                  Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('Amount (৳)',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child:
                  Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 32), // Delete button spacing
        ],
      ),
    );
  }

  Widget _buildTotalSection(double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '৳ ${BanglaUtils.toBangla(MathEvaluator.formatNumber(total))}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: total >= 0 ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetItemRow extends StatefulWidget {
  final Asset asset;
  final bool autoFocusName;

  const _AssetItemRow({
    super.key,
    required this.asset,
    this.autoFocusName = false,
  });

  @override
  State<_AssetItemRow> createState() => _AssetItemRowState();
}

class _AssetItemRowState extends State<_AssetItemRow> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late FocusNode _nameFocusNode;
  late FocusNode _amountFocusNode;

  double? _livePreview;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset.name);
    _amountController = TextEditingController(
      text: widget.asset.amount == 0
          ? ''
          : MathEvaluator.formatNumber(widget.asset.amount),
    );
    _nameFocusNode = FocusNode();
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(_onAmountFocusChange);

    if (widget.autoFocusName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _nameFocusNode.requestFocus();
        }
      });
    }
  }

  void _onAmountFocusChange() {
    if (!_amountFocusNode.hasFocus) {
      _applyAmountChange();
    }
  }

  void _applyAmountChange() {
    final text = _amountController.text.trim();
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    if (text.isEmpty) {
      _amountController.text = '';
      assetProvider.updateAsset(widget.asset.id, amount: 0);
      setState(() {
        _livePreview = null;
      });
      return;
    }

    String clean = BanglaUtils.toEnglish(text);
    clean = clean.replaceAll(',', '').replaceAll('−', '-').replaceAll('–', '-');

    final doubleVal = double.tryParse(clean);
    if (doubleVal != null) {
      final formatted = MathEvaluator.formatNumber(doubleVal);
      _amountController.text = formatted;
      assetProvider.updateAsset(widget.asset.id, amount: doubleVal);
    } else {
      _amountController.text = widget.asset.amount == 0
          ? ''
          : MathEvaluator.formatNumber(widget.asset.amount);
    }

    setState(() {
      _livePreview = null;
    });
  }

  void _onAmountTextChanged(String val) {
    if (val.trim().isEmpty) {
      final assetProvider = Provider.of<AssetProvider>(context, listen: false);
      assetProvider.updateAsset(widget.asset.id, amount: 0);
      setState(() {
        _livePreview = null;
      });
      return;
    }

    String clean = BanglaUtils.toEnglish(val.trim());
    clean = clean.replaceAll(',', '').replaceAll('−', '-').replaceAll('–', '-');

    final doubleVal = double.tryParse(clean);
    if (doubleVal != null) {
      final assetProvider = Provider.of<AssetProvider>(context, listen: false);
      assetProvider.updateAsset(widget.asset.id, amount: doubleVal);
    }

    setState(() {
      _livePreview = null;
    });
  }

  Future<void> _openCalculator() async {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    final newAmount = await AssetCalculatorBottomSheet.show(
      context,
      assetName: _nameController.text,
      initialAmount: widget.asset.amount,
    );

    if (newAmount != null) {
      _amountController.text = MathEvaluator.formatNumber(newAmount);
      assetProvider.updateAsset(widget.asset.id, amount: newAmount);
      setState(() {
        _livePreview = null;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _AssetItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.name != widget.asset.name &&
        _nameController.text != widget.asset.name) {
      _nameController.text = widget.asset.name;
    }
    if (oldWidget.asset.amount != widget.asset.amount &&
        !_amountFocusNode.hasFocus) {
      _amountController.text = widget.asset.amount == 0
          ? ''
          : MathEvaluator.formatNumber(widget.asset.amount);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _nameFocusNode.dispose();
    _amountFocusNode.removeListener(_onAmountFocusChange);
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Asset Name Field
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: const InputDecoration(
                hintText: 'Asset Name',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (val) {
                assetProvider.updateAsset(widget.asset.id, name: val);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Amount Field with Live Preview & Calculator Icon
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: '0 (+/-)',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: _onAmountTextChanged,
                        onSubmitted: (_) => _applyAmountChange(),
                      ),
                    ),
                    InkWell(
                      onTap: _openCalculator,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.calculate_outlined,
                          size: 18,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_livePreview != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: Colors.green.shade300, width: 0.8),
                    ),
                    child: Text(
                      '= ৳ ${BanglaUtils.toBangla(MathEvaluator.formatNumber(_livePreview!))}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Date Text
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yy').format(widget.asset.lastModified),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          // Delete Button
          SizedBox(
            width: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () => assetProvider.deleteAsset(widget.asset.id),
            ),
          ),
        ],
      ),
    );
  }
}
