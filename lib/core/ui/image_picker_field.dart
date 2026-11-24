import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:classicum_admin/core/network/uploads.dart';

/// Lets the admin pick a photo from the gallery.
Future<List<UploadImage>> pickImages({bool multiple = false}) async {
  final picker = ImagePicker();
  if (multiple) {
    final files = await picker.pickMultiImage(maxWidth: 2400, imageQuality: 85);
    return [for (final f in files) UploadImage(path: f.path, filename: f.name)];
  }
  final file = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 2400,
    imageQuality: 85,
  );
  return file == null
      ? []
      : [UploadImage(path: file.path, filename: file.name)];
}

class PickedImagesRow extends StatelessWidget {
  const PickedImagesRow({
    super.key,
    required this.images,
    required this.onRemove,
  });

  final List<UploadImage> images;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < images.length; i++)
        InputChip(
          label: Text(images[i].filename, overflow: TextOverflow.ellipsis),
          onDeleted: () => onRemove(i),
        ),
    ],
  );
}
