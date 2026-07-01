import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/product_model.dart';
import '../../clients/controllers/client_controller.dart';
import '../../products/controllers/product_controller.dart';
import '../controllers/invoice_controller.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final InvoiceModel? editInvoice;
  const CreateInvoiceScreen({super.key, this.editInvoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final InvoiceController _invCtrl = Get.find();
  final ClientController _clientCtrl = Get.find();
  final ProductController _prodCtrl = Get.find();

  ClientModel? _selectedClient;
  final List<InvoiceItem> _items = [];
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _status = 'Draft';
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  String _currency = 'PKR';
  bool _isSaving = false;

  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    if (widget.editInvoice != null) {
      final inv = widget.editInvoice!;
      _selectedClient = _clientCtrl.getClientById(inv.clientId);
      _items.addAll(inv.items);
      _issueDate = inv.issueDate;
      _dueDate = inv.dueDate;
      _status = inv.status;
      _notesCtrl.text = inv.notes ?? '';
      _discountCtrl.text = inv.discountPercent.toString();
      _currency = inv.currency;
    }
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.subtotal);
  double get _totalTax => _items.fold(0, (s, i) => s + i.taxAmount);
  double get _discount => _subtotal * ((double.tryParse(_discountCtrl.text) ?? 0) / 100);
  double get _grandTotal => _subtotal + _totalTax - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF1FF),
        title: Text(widget.editInvoice == null ? 'New Invoice' : 'Edit Invoice'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: AppBackground(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Client', _clientSection()),
            const SizedBox(height: 16),
            _section('Invoice Details', _detailsSection()),
            const SizedBox(height: 16),
            _section('Items', _itemsSection()),
            const SizedBox(height: 16),
            _section('Summary', _summarySection()),
            const SizedBox(height: 16),
            _section('Notes', TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add notes or payment terms...',
              ),
            )),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _clientSection() {
    return Column(
      children: [
        if (_selectedClient != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(_selectedClient!.name[0].toUpperCase(),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(_selectedClient!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_selectedClient!.email),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedClient = null),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _selectClient,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Select Client'),
          ),
      ],
    );
  }

  Widget _detailsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _datePicker('Issue Date', _issueDate, (d) => setState(() => _issueDate = d))),
            const SizedBox(width: 12),
            Expanded(child: _datePicker('Due Date', _dueDate, (d) => setState(() => _dueDate = d))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Draft', 'Sent', 'Paid', 'Overdue', 'Cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: ['PKR', 'USD', 'EUR', 'GBP', 'AED', 'SAR']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _datePicker(String label, DateTime date, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(10),
          color: AppTheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(DateFormat('dd MMM yyyy').format(date),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _itemsSection() {
    return Column(
      children: [
        ..._items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                      onPressed: () => setState(() => _items.removeAt(i)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(item.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${item.quantity} ${item.unit} × $_currency ${_fmt.format(item.unitPrice)}',
                        style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text('$_currency ${_fmt.format(item.total)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                if (item.taxPercent > 0)
                  Text('Tax: ${item.taxPercent}% = $_currency ${_fmt.format(item.taxAmount)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
        ),
      ],
    );
  }

  Widget _summarySection() {
    return Column(
      children: [
        _summaryRow('Subtotal', '$_currency ${_fmt.format(_subtotal)}'),
        if (_totalTax > 0) _summaryRow('Tax', '$_currency ${_fmt.format(_totalTax)}'),
        Row(
          children: [
            const Text('Discount (%)', style: TextStyle(color: AppTheme.textSecondary)),
            const Spacer(),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _discountCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                  suffixText: '%',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const Divider(),
        _summaryRow('Total', '$_currency ${_fmt.format(_grandTotal)}', bold: true),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(
              color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              fontSize: bold ? 16 : 14)),
          const Spacer(),
          Text(value, style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 16 : 14,
              color: bold ? AppTheme.primary : AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _selectClient() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Client', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() => ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                    title: const Text('Add New Client'),
                    onTap: () {
                      Get.back();
                      Get.toNamed('/clients/add');
                    },
                  ),
                  const Divider(),
                  ..._clientCtrl.clients.map((c) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(c.name[0], style: const TextStyle(color: AppTheme.primary)),
                    ),
                    title: Text(c.name),
                    subtitle: Text(c.email),
                    onTap: () {
                      setState(() => _selectedClient = c);
                      Get.back();
                    },
                  )),
                ],
              )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _addItem() {
    Get.dialog(
      _AddProductDialog(
        productController: _prodCtrl,
        currency: _currency,
        onAdd: (item) => setState(() => _items.add(item)),
      ),
      barrierDismissible: false, // stays open until the user taps Close
    );
  }

  Future<void> _save() async {
    if (_selectedClient == null) {
      Get.snackbar('Missing', 'Please select a client', backgroundColor: AppTheme.danger, colorText: Colors.white);
      return;
    }
    if (_items.isEmpty) {
      Get.snackbar('Missing', 'Add at least one item', backgroundColor: AppTheme.danger, colorText: Colors.white);
      return;
    }
    setState(() => _isSaving = true);

    final invoice = InvoiceModel(
      id: widget.editInvoice?.id ?? _invCtrl.newId(),
      invoiceNumber: widget.editInvoice?.invoiceNumber ?? _invCtrl.generateInvoiceNumber(),
      clientId: _selectedClient!.id,
      clientName: _selectedClient!.name,
      clientEmail: _selectedClient!.email,
      clientAddress: _selectedClient!.address,
      items: _items,
      issueDate: _issueDate,
      dueDate: _dueDate,
      status: _status,
      discountPercent: double.tryParse(_discountCtrl.text) ?? 0,
      notes: _notesCtrl.text,
      currency: _currency,
      createdAt: widget.editInvoice?.createdAt ?? DateTime.now(),
      userId: _invCtrl.userId,
    );

    if (widget.editInvoice == null) {
      await _invCtrl.createInvoice(invoice);
    } else {
      await _invCtrl.updateInvoice(invoice);
    }

    setState(() => _isSaving = false);
    Get.back();
    Get.snackbar('Success', widget.editInvoice == null ? 'Invoice created!' : 'Invoice updated!',
        backgroundColor: AppTheme.accent, colorText: Colors.white);
  }
}

/// "Add Product / Service" dialog — modelled on the Uni Invoice window.
///
/// • Type a product name (existing products are suggested as you type).
/// • Pick a suggestion to auto-fill, or enter a brand-new product.
/// • "Use WholeSale Rate" swaps in the product's wholesale price.
/// • A new product is saved straight into the Products list.
/// • "Add" keeps the dialog OPEN so several items can be added in one go;
///   "Close" (or the back gesture is disabled) dismisses it.
class _AddProductDialog extends StatefulWidget {
  final ProductController productController;
  final String currency;
  final Function(InvoiceItem) onAdd;
  const _AddProductDialog({
    required this.productController,
    required this.currency,
    required this.onAdd,
  });

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  static const List<String> _units = ['pcs', 'kg', 'g', 'l', 'ml', 'hr', 'day', 'month', 'service'];

  ProductModel? _selected;
  bool _useWholesale = false;
  int _addedCount = 0;

  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _rateCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _unit = 'pcs';
  double _tax = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> get _suggestions {
    final q = _nameCtrl.text.trim().toLowerCase();
    if (q.isEmpty || _selected != null) return const [];
    return widget.productController.products
        .where((p) => p.name.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  double _rateFor(ProductModel p) {
    if (_useWholesale && p.wholesalePrice != null) return p.wholesalePrice!;
    return p.price;
  }

  void _pick(ProductModel p) {
    setState(() {
      _selected = p;
      _nameCtrl.text = p.name;
      _rateCtrl.text = _rateFor(p).toString();
      _codeCtrl.text = p.sku ?? '';
      _descCtrl.text = p.description;
      _unit = p.unit;
      _tax = p.taxPercent;
    });
    FocusScope.of(context).unfocus();
  }

  void _resetForNext() {
    setState(() {
      _selected = null;
      _nameCtrl.clear();
      _qtyCtrl.text = '1';
      _rateCtrl.clear();
      _codeCtrl.clear();
      _descCtrl.clear();
      _unit = 'pcs';
      _tax = 0;
    });
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _rateCtrl.text.trim().isEmpty) {
      Get.snackbar('Missing info', 'Enter a product name and rate',
          backgroundColor: AppTheme.danger, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text) ?? 1;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final code = _codeCtrl.text.trim();

    String productId = _selected?.id ?? '';
    // New product → save it into the catalog.
    if (_selected == null) {
      final created = await widget.productController.addProduct(
        name: name,
        description: _descCtrl.text.trim(),
        price: rate,
        taxPercent: _tax,
        unit: _unit,
        sku: code.isNotEmpty ? code : null,
        wholesalePrice: _useWholesale ? rate : null,
      );
      productId = created.id;
    }

    widget.onAdd(InvoiceItem(
      productId: productId,
      productName: name,
      description: _descCtrl.text.trim(),
      quantity: qty,
      unitPrice: rate,
      taxPercent: _tax,
      unit: _unit,
    ));

    setState(() => _addedCount++);
    _resetForNext();
    Get.snackbar('Added', '$name added to invoice',
        backgroundColor: AppTheme.accent, colorText: Colors.white,
        duration: const Duration(milliseconds: 900),
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFFE7EBEF),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: AppTheme.accent, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Add Product / Service',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      if (_addedCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$_addedCount added',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Use WholeSale Rate
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Use WholeSale Rate',
                              style: TextStyle(fontSize: 15, color: AppTheme.textPrimary)),
                        ),
                        Checkbox(
                          value: _useWholesale,
                          activeColor: AppTheme.accent,
                          onChanged: (v) {
                            setState(() {
                              _useWholesale = v ?? false;
                              if (_selected != null) {
                                _rateCtrl.text = _rateFor(_selected!).toString();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    // Product name + scan icon
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Please Enter Product Name',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          color: AppTheme.textSecondary,
                          tooltip: 'Barcode scan',
                          onPressed: () => Get.snackbar(
                            'Coming soon', 'Barcode scanning is not enabled yet',
                            snackPosition: SnackPosition.BOTTOM),
                        ),
                      ),
                      onChanged: (_) => setState(() => _selected = null),
                    ),
                    // Live suggestions from saved products
                    if (_suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.divider),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: _suggestions
                              .map((p) => ListTile(
                                    dense: true,
                                    title: Text(p.name, style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(
                                        '${widget.currency} ${p.price.toStringAsFixed(2)} / ${p.unit}',
                                        style: const TextStyle(fontSize: 12)),
                                    trailing: const Icon(Icons.north_west, size: 16),
                                    onTap: () => _pick(p),
                                  ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 14),
                    // Quantity / Rate
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Quantity'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _rateCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Rate (${widget.currency})'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Product Code / Unit
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeCtrl,
                            decoration: const InputDecoration(labelText: 'Product Code'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _unit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: _units
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Footer buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _add,
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
