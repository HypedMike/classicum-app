import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/core/theme.dart';

String formatDate(DateTime d) => DateFormat('d MMM yyyy', 'it').format(d);
String formatDay(DateTime d) => DateFormat('d', 'it').format(d);
String formatMonth(DateTime d) =>
    DateFormat('MMM', 'it').format(d).toUpperCase();
String formatTime(DateTime d) => DateFormat('HH:mm', 'it').format(d);

String errorText(Object error) =>
    error is ApiException ? error.message : 'Qualcosa è andato storto';

/// Page header: eyebrow + big serif title, as in the mock-up.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(eyebrow.toUpperCase(), style: eyebrowStyle()),
      const SizedBox(height: 8),
      Text(title, style: displayStyle(56)),
    ],
  );
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.dark = true});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: dark ? Palette.ink : null,
      border: dark ? null : Border.all(color: Palette.ink),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: dark ? Palette.cream : Palette.ink,
      ),
    ),
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(errorText(error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    ),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: serif,
          fontSize: 20,
          color: Palette.muted,
        ),
      ),
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String body) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Palette.cream,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Round chip used for filters.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Palette.ink : null,
          border: Border.all(color: selected ? Palette.ink : Palette.stone),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Palette.cream : Palette.ink,
          ),
        ),
      ),
    ),
  );
}

/// Network image that degrades to a flat block on error / in tests.
class RemoteImage extends StatelessWidget {
  const RemoteImage({super.key, required this.url, this.size = 72});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE2D9C6),
        borderRadius: BorderRadius.circular(16),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

/// Strips the HTML produced by the website's editor down to plain text.
String stripHtml(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();
