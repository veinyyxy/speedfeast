import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';

class DineInScanPage extends StatefulWidget {
  const DineInScanPage({super.key});

  @override
  State<DineInScanPage> createState() => _DineInScanPageState();
}

class _DineInScanPageState extends State<DineInScanPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _manualCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);
    final serviceProvider = context.read<ServiceProvider>();
    final table = await serviceProvider.verifyDineInTable(code);
    if (!mounted) return;

    setState(() => _isProcessing = false);
    if (table != null) {
      final tableNumber = table['table_number']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Table $tableNumber selected.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          serviceProvider.lastDineInError ??
              'Table code could not be verified.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim() ?? '';
      if (code.isNotEmpty) {
        _verifyCode(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCAN TABLE'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Flash',
            icon: const Icon(Icons.flash_on_outlined),
            onPressed: _scannerController.toggleTorch,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _handleDetect,
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryColor, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Dine-in table code',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualCodeController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Enter table token',
              prefixIcon: const Icon(Icons.qr_code_2_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onSubmitted: _verifyCode,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _verifyCode(_manualCodeController.text),
            icon: const Icon(Icons.table_restaurant_outlined),
            label: Text(_isProcessing ? 'Verifying...' : 'Use Table Code'),
          ),
        ],
      ),
    );
  }
}
