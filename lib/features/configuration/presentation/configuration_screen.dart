import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/configuration_provider.dart';

class ConfigurationScreen extends ConsumerStatefulWidget {
  const ConfigurationScreen({super.key});
  @override
  ConsumerState<ConfigurationScreen> createState() =>
      _ConfigurationScreenState();
}

class _ConfigurationScreenState extends ConsumerState<ConfigurationScreen> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final config = ref.read(calibrationConfigProvider);
    _fields = [
      config.alphaBetaTargetMm,
      config.betaGammaTargetMm,
      config.alphaGammaTargetMm,
    ].map((v) => TextEditingController(text: v.toString())).toList();
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(calibrationConfigProvider.notifier)
          .setTargets(
            alphaBetaMm: double.parse(_fields[0].text),
            betaGammaMm: double.parse(_fields[1].text),
            alphaGammaMm: double.parse(_fields[2].text),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Target distances saved')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save targets. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configuration')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Target distances',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Set the desired distance between each pair of strip midpoints. Saved history keeps its original targets.',
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < 3; i++) ...[
                TextFormField(
                  controller: _fields[i],
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: ['Alpha-Beta', 'Beta-Gamma', 'Alpha-Gamma'][i],
                    suffixText: 'mm',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (text) {
                    final value = double.tryParse(text ?? '');
                    return value == null || !value.isFinite || value <= 0
                        ? 'Enter a positive distance in mm'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              const Text('Marker spacing: 40 mm · Tolerance: ±5 mm'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save targets'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
