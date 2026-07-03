import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/count_header.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/import_service.dart';
import '../../import/screens/import_mapping_screen.dart';
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
      backgroundColor: const Color(0xFFEAF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF1FF),
        title: const Text('Products & Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Import from CSV/Excel',
            onPressed: () => _import(ctrl),
          ),
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
        return Column(
          children: [
            CountHeader(label: 'Total Products', count: ctrl.products.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.warning)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (p.description.isNotEmpty)
                                  Text(p.description,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (p.wholesalePrice != null)
                                  Text('WS: ${fmt.format(p.wholesalePrice!)}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(fmt.format(p.price),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('per ${p.unit}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              if (p.taxPercent > 0)
                                Text('+${p.taxPercent}% tax',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.warning)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                            tooltip: 'Edit product',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showAddProduct(context, ctrl, p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                            tooltip: 'Delete product',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Get.defaultDialog(
                              title: 'Delete product',
                              middleText: 'Delete "${p.name}"? This cannot be undone.',
                              textConfirm: 'Delete',
                              textCancel: 'Cancel',
                              confirmTextColor: Colors.white,
                              buttonColor: AppTheme.danger,
                              onConfirm: () {
                                ctrl.deleteProduct(p.id);
                                Get.back();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      })),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProduct(context, ctrl),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _import(ProductController ctrl) async {
    try {
      final table = await ImportService.pickAndParse();
      if (table == null) return; // cancelled
      if (table.isEmpty) {
        Get.snackbar('Empty file', 'No rows found in that file',
            backgroundColor: AppTheme.warning, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      Get.to(() => ImportMappingScreen(
            title: 'Products',
            table: table,
            fields: const [
              ImportField('name', 'Product name',
                  required: true,
                  keywords: ['product name', 'item name', 'name', 'product', 'item'],
                  avoid: ['code', 'categor', 'rate', 'price']),
              ImportField('price', 'Sale rate / price',
                  required: true, numeric: true,
                  keywords: ['sale rate', 'sale', 'price', 'rate', 'mrp'],
                  avoid: ['whole', 'purchase']),
              ImportField('wholesale', 'Wholesale rate',
                  numeric: true, keywords: ['whole']),
              ImportField('unit', 'Unit', keywords: ['unit', 'uom']),
              ImportField('code', 'Product code / SKU',
                  keywords: ['code', 'sku', 'barcode']),
              ImportField('description', 'Description',
                  keywords: ['description', 'desc', 'detail']),
            ],
            onImport: (rows) => ctrl.importProducts(rows),
          ));
    } catch (e) {
      Get.snackbar('Could not read file', '$e',
          backgroundColor: AppTheme.danger, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
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
                        final ws = wholesaleCtrl.text.trim().isNotEmpty
                            ? double.tryParse(wholesaleCtrl.text)
                            : null;
                        if (edit == null) {
                          ctrl.addProduct(
                            name: nameCtrl.text,
                            description: descCtrl.text,
                            price: double.tryParse(priceCtrl.text) ?? 0,
                            taxPercent: double.tryParse(taxCtrl.text) ?? 0,
                            unit: unit,
                            sku: skuCtrl.text.isNotEmpty ? skuCtrl.text : null,
                            wholesalePrice: ws,
                          );
                        } else {
                          edit.name = nameCtrl.text;
                          edit.description = descCtrl.text;
                          edit.price = double.tryParse(priceCtrl.text) ?? 0;
                          edit.taxPercent = double.tryParse(taxCtrl.text) ?? 0;
                          edit.unit = unit;
                          edit.sku = skuCtrl.text.isNotEmpty ? skuCtrl.text : null;
                          edit.wholesalePrice = ws;
                          ctrl.updateProduct(edit);
                        }
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
