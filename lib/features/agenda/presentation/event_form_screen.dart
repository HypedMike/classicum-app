import 'package:material_ui/material_ui.dart';
import 'package:classicum_admin/core/ui/admin_top_bar.dart';
import 'package:provider/provider.dart';
import 'package:classicum_admin/core/network/uploads.dart';
import 'package:classicum_admin/core/ui/image_picker_field.dart';
import 'package:classicum_admin/core/ui/widgets.dart';
import 'package:classicum_admin/features/agenda/data/events_repository.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _form = GlobalKey<FormState>();
  final _titolo = TextEditingController();
  final _descrizione = TextEditingController();
  final _luogo = TextEditingController();
  DateTime? _date;
  List<UploadImage> _image = [];
  bool _busy = false;
  String? _dateError;

  @override
  void dispose() {
    _titolo.dispose();
    _descrizione.dispose();
    _luogo.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date ?? now),
    );
    if (time == null) return;
    setState(() {
      _date = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      _dateError = null;
    });
  }

  Future<void> _save() async {
    final valid = _form.currentState!.validate();
    if (_date == null) setState(() => _dateError = 'Scegli data e ora');
    if (!valid || _date == null) return;
    setState(() => _busy = true);
    try {
      await context.read<EventsRepository>().createEvent(
        titolo: _titolo.text.trim(),
        descrizione: _descrizione.text.trim(),
        data: _date!,
        luogo: _luogo.text.trim(),
        image: _image.isEmpty ? null : _image.first,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminTopBar(title: 'Nuovo evento'),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const Key('event-title'),
              controller: _titolo,
              decoration: const InputDecoration(labelText: 'Titolo'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('event-place'),
              controller: _luogo,
              decoration: const InputDecoration(labelText: 'Luogo'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('event-date'),
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(
                _date == null
                    ? 'Data e ora'
                    : '${formatDate(_date!)} · ${formatTime(_date!)}',
              ),
            ),
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _dateError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('event-description'),
              controller: _descrizione,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Descrizione'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await pickImages();
                if (picked.isNotEmpty) setState(() => _image = picked);
              },
              icon: const Icon(Icons.image_outlined),
              label: const Text('Immagine (facoltativa)'),
            ),
            if (_image.isNotEmpty) ...[
              const SizedBox(height: 8),
              PickedImagesRow(
                images: _image,
                onRemove: (_) => setState(() => _image = []),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              key: const Key('event-save'),
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Salvataggio…' : 'Pubblica evento'),
            ),
          ],
        ),
      ),
    );
  }
}
