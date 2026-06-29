import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/local_database.dart';
import '../../../data/models/profile_model.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _auth = Get.find();
  late final ProfileModel _profile;
  bool _isNew = false;

  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();
  String _currency = 'PKR';

  @override
  void initState() {
    super.initState();
    final existing = LocalDatabase.getProfile(_auth.userId!);
    if (existing != null) {
      _profile = existing;
    } else {
      _isNew = true;
      _profile = ProfileModel(
        userId: _auth.userId!,
        businessName: '',
        ownerName: _auth.userName ?? '',
        email: _auth.userEmail ?? '',
        phone: '',
        address: '',
      );
    }
    _businessNameCtrl.text = _profile.businessName;
    _ownerNameCtrl.text = _profile.ownerName;
    _emailCtrl.text = _profile.email;
    _phoneCtrl.text = _profile.phone;
    _addressCtrl.text = _profile.address;
    _taxCtrl.text = _profile.taxNumber ?? '';
    _bankCtrl.text = _profile.bankDetails ?? '';
    _prefixCtrl.text = _profile.invoicePrefix ?? 'INV-';
    _currency = _profile.currency;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar/logo area
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.business_outlined, size: 40, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {}, // TODO: image picker
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: const Text('Upload Logo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section('Business Info', [
              TextFormField(controller: _businessNameCtrl,
                  decoration: const InputDecoration(labelText: 'Business Name *')),
              const SizedBox(height: 12),
              TextFormField(controller: _ownerNameCtrl,
                  decoration: const InputDecoration(labelText: 'Owner Name')),
              const SizedBox(height: 12),
              TextFormField(controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2),
              const SizedBox(height: 12),
              TextFormField(controller: _taxCtrl,
                  decoration: const InputDecoration(labelText: 'Tax / NTN Number (optional)')),
            ]),
            const SizedBox(height: 16),
            _section('Invoice Settings', [
              Row(children: [
                Expanded(child: TextFormField(controller: _prefixCtrl,
                    decoration: const InputDecoration(labelText: 'Invoice Prefix',
                        hintText: 'INV-'))),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(labelText: 'Default Currency'),
                  items: ['PKR', 'USD', 'EUR', 'GBP', 'AED', 'SAR']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                )),
              ]),
            ]),
            const SizedBox(height: 16),
            _section('Bank Details', [
              TextFormField(controller: _bankCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Bank Info (shown on invoices)',
                      hintText: 'Bank: HBL\nAccount: 1234567890\nIBAN: PK00...'),
                  maxLines: 4),
            ]),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.danger),
              title: const Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
              onTap: () => Get.find<AuthController>().signOut(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _save() {
    _profile.businessName = _businessNameCtrl.text;
    _profile.ownerName = _ownerNameCtrl.text;
    _profile.email = _emailCtrl.text;
    _profile.phone = _phoneCtrl.text;
    _profile.address = _addressCtrl.text;
    _profile.taxNumber = _taxCtrl.text.isNotEmpty ? _taxCtrl.text : null;
    _profile.bankDetails = _bankCtrl.text.isNotEmpty ? _bankCtrl.text : null;
    _profile.invoicePrefix = _prefixCtrl.text;
    _profile.currency = _currency;
    LocalDatabase.saveProfile(_profile);
    Get.back();
    Get.snackbar('Saved', 'Profile updated!', backgroundColor: AppTheme.accent, colorText: Colors.white);
  }
}
