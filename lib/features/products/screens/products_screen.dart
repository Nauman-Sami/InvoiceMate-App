import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/services/pdf_service.dart';
import '../controllers/product_controller.dart';
import '../../../data/models/product_model.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  static const List<String> _units = ['pcs', 'kg', 'g', 'l', 'ml', 'hr', 'day', 'month', 'service'];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProductController>();
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Products & Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download PDF',
            onPressed: () {
              if (ctrl.products.isEmpty) {
                Get.snackbar('No products', 'Add a product first',
                    backgroundColor: AppTheme.warning, colorText: Colors.white);
                return;
              }
              PdfService.printProductsPdf(ctrl.products.toList());
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () {
              if (ctrl.products.isEmpty) {
                Get.snackbar('No products', 'Add a product first',
                    backgroundColor: AppTheme.warning, colorText: Colors.white);
                return;
              }
              PdfService.shareProductsPdf(ctrl.products.toList());
            },
          ),
        ],
      ),
      body: AppBackground(child: Obx(() {
        if (ctrl.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text('No products yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddProduct(context, ctrl),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.products.length,
          itemBuilder: (_, i) {
            final p = ctrl.products[i];
            return Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => ctrl.deleteProduct(p.id),
                    backgroundColor: AppTheme.danger,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: AppTheme.warning),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(p.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (p.sku != null)
                            Text('SKU: ${p.sku}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(fmt.format(p.price),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('per ${p.unit}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        if (p.taxPercent > 0)
                          Text('+${p.taxPercent}% tax',
                              style: const TextStyle(fontSize: 11, color: AppTheme.warning)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      })),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProduct(context, ctrl),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProduct(BuildContext context, ProductController ctrl, [ProductModel? edit]) {
    final nameCtrl = TextEditingController(text: edit?.name);
    final descCtrl = TextEditingController(text: edit?.description);
    final priceCtrl = TextEditingController(text: edit?.price.toString());
    final wholesaleCtrl = TextEditingController(
        text: edit?.wholesalePrice != null ? edit!.wholesalePrice.toString() : '');
    final taxCtrl = TextEditingController(text: edit?.taxPercent.toString() ?? '0');
    final skuCtrl = TextEditingController(text: edit?.sku);
    String unit = edit?.unit ?? 'pcs';
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      StatefulBuilder(builder: (context, setState) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(edit == null ? 'Add Product/Service' : 'Edit Product',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextFormField(controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Retail Rate *'),
                        validator: (v) => v!.isEmpty ? 'Required' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                        controller: wholesaleCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Wholesale Rate'))),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: taxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tax %', suffixText: '%')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => unit = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                        controller: skuCtrl,
                        decoration: const InputDecoration(labelText: 'SKU (optional)'))),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        ctrl.addProduct(
                          name: nameCtrl.text,
                          description: descCtrl.text,
                          price: double.tryParse(priceCtrl.text) ?? 0,
                          taxPercent: double.tryParse(taxCtrl.text) ?? 0,
                          unit: unit,
                          sku: skuCtrl.text.isNotEmpty ? skuCtrl.text : null,
                          wholesalePrice: wholesaleCtrl.text.trim().isNotEmpty
                              ? double.tryParse(wholesaleCtrl.text)
                              : null,
                        );
                        Get.back();
                      },
                      child: Text(edit == null ? 'Add Product' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }
}
