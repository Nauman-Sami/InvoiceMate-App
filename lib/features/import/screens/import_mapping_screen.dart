import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/services/import_service.dart';

/// One target field the user maps a spreadsheet column onto.
class ImportField {
  final String key;
  final String label;
  final bool required;
  final bool numeric;
  final List<String> keywords; // for auto-detection
  final List<String> avoid;
  const ImportField(
    this.key,
    this.label, {
    this.required = false,
    this.numeric = false,
    this.keywords = const [],
    this.avoid = const [],
  });
}

class ImportMappingScreen extends StatefulWidget {
  final String title; // e.g. "Products" / "Clients"
  final ParsedTable table;
  final List<ImportField> fields;
  final Future<int> Function(List<Map<String, String>> rows) onImport;

  const ImportMappingScreen({
    super.key,
    required this.title,
    required this.table,
    required this.fields,
    required this.onImport,
  });

  @override
  State<ImportMappingScreen> createState() => _ImportMappingScreenState();
}

class _ImportMappingScreenState extends State<ImportMappingScreen> {
  late Map<String, int> _map; // fieldKey -> header index (-1 = none)
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _map = {};
    final taken = <int>{};
    for (final f in widget.fields) {
      final idx = ImportService.guessColumn(widget.table.headers, f.keywords,
          avoid: f.avoid, taken: taken);
      _map[f.key] = idx;
      if (idx >= 0) taken.add(idx);
    }
  }

  bool get _requiredMet =>
      widget.fields.where((f) => f.required).every((f) => (_map[f.key] ?? -1) >= 0);

  String _cell(List<String> row, int idx) =>
      (idx >= 0 && idx < row.length) ? row[idx] : '';

  List<Map<String, String>> _buildRows() {
    final out = <Map<String, String>>[];
    for (final row in widget.table.rows) {
      final m = <String, String>{};
      for (final f in widget.fields) {
        final idx = _map[f.key] ?? -1;
        var v = _cell(row, idx);
        if (f.numeric) v = ImportService.parseNumber(v).toString();
        m[f.key] = v;
      }
      out.add(m);
    }
    return out;
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final count = await widget.onImport(_buildRows());
      Get.back(); // close mapping screen
      Get.snackbar('Import complete', 'Added $count ${widget.title.toLowerCase()}',
          backgroundColor: AppTheme.accent, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      setState(() => _importing = false);
      Get.snackbar('Import failed', '$e',
          backgroundColor: AppTheme.danger, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headers = widget.table.headers;
    final previewRows = widget.table.rows.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF1FF),
        title: Text('Import ${widget.title}'),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Found ${widget.table.rows.length} rows and ${headers.length} columns. '
                        'Match your columns below.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Column mapping',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              ...widget.fields.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text.rich(TextSpan(
                            text: f.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            children: [
                              if (f.required)
                                const TextSpan(text: ' *',
                                    style: TextStyle(color: AppTheme.danger)),
                            ],
                          )),
                        ),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int>(
                            value: _map[f.key],
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem(value: -1, child: Text('— None —')),
                              ...headers.asMap().entries.map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(
                                      e.value.isEmpty ? 'Column ${e.key + 1}' : e.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _map[f.key] = v ?? -1),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              const Text('Preview (first 3 rows)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: previewRows.map((row) {
                    final parts = widget.fields
                        .where((f) => (_map[f.key] ?? -1) >= 0)
                        .map((f) {
                      var v = _cell(row, _map[f.key]!);
                      if (f.numeric) v = ImportService.parseNumber(v).toString();
                      return '${f.label}: ${v.isEmpty ? '—' : v}';
                    }).join('   •   ');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(parts, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_requiredMet && !_importing) ? _import : null,
                  icon: _importing
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_done),
                  label: Text(_importing
                      ? 'Importing...'
                      : 'Import ${widget.table.rows.length} ${widget.title}'),
                ),
              ),
              if (!_requiredMet)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Map the required (*) fields to continue.',
                      style: TextStyle(fontSize: 12, color: AppTheme.danger)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
