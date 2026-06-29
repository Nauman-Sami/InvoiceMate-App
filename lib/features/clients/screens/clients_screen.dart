import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/services/pdf_service.dart';
import '../controllers/client_controller.dart';
import '../../../data/models/client_model.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ClientController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download PDF',
            onPressed: () {
              if (ctrl.clients.isEmpty) {
                Get.snackbar('No clients', 'Add a client first',
                    backgroundColor: AppTheme.warning, colorText: Colors.white);
                return;
              }
              PdfService.printClientsPdf(ctrl.clients.toList());
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () {
              if (ctrl.clients.isEmpty) {
                Get.snackbar('No clients', 'Add a client first',
                    backgroundColor: AppTheme.warning, colorText: Colors.white);
                return;
              }
              PdfService.shareClientsPdf(ctrl.clients.toList());
            },
          ),
        ],
      ),
      body: AppBackground(child: Obx(() {
        if (ctrl.clients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text('No clients yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddClient(context, ctrl),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Client'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.clients.length,
          itemBuilder: (_, i) {
            final c = ctrl.clients[i];
            return Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => ctrl.deleteClient(c.id),
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
              child: _ClientTile(client: c, ctrl: ctrl),
            );
          },
        );
      })),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClient(context, ctrl),
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  void _showAddClient(BuildContext context, ClientController ctrl, [ClientModel? edit]) {
    final nameCtrl = TextEditingController(text: edit?.name);
    final emailCtrl = TextEditingController(text: edit?.email);
    final phoneCtrl = TextEditingController(text: edit?.phone);
    final addressCtrl = TextEditingController(text: edit?.address);
    final companyCtrl = TextEditingController(text: edit?.companyName);
    final taxCtrl = TextEditingController(text: edit?.taxNumber);
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
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
                Text(edit == null ? 'Add Client' : 'Edit Client',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                TextFormField(controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextFormField(controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextFormField(controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2),
                const SizedBox(height: 12),
                TextFormField(controller: companyCtrl,
                    decoration: const InputDecoration(labelText: 'Company (optional)')),
                const SizedBox(height: 12),
                TextFormField(controller: taxCtrl,
                    decoration: const InputDecoration(labelText: 'Tax Number (optional)')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      if (edit == null) {
                        ctrl.addClient(
                          name: nameCtrl.text,
                          email: emailCtrl.text,
                          phone: phoneCtrl.text,
                          address: addressCtrl.text,
                          companyName: companyCtrl.text.isNotEmpty ? companyCtrl.text : null,
                          taxNumber: taxCtrl.text.isNotEmpty ? taxCtrl.text : null,
                        );
                      } else {
                        final updated = edit.copyWith(
                          name: nameCtrl.text,
                          email: emailCtrl.text,
                          phone: phoneCtrl.text,
                          address: addressCtrl.text,
                          companyName: companyCtrl.text,
                          taxNumber: taxCtrl.text,
                        );
                        ctrl.updateClient(updated);
                      }
                      Get.back();
                    },
                    child: Text(edit == null ? 'Add Client' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _ClientTile extends StatelessWidget {
  final ClientModel client;
  final ClientController ctrl;
  const _ClientTile({required this.client, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Text(client.name[0].toUpperCase(),
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.email.isNotEmpty) Text(client.email, style: const TextStyle(fontSize: 12)),
            if (client.companyName != null)
              Text(client.companyName!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () {},
        ),
        isThreeLine: client.companyName != null,
      ),
    );
  }
}
