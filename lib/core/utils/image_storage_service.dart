import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages all item image storage in a dedicated, fixed folder under the
/// application's documents directory: `<AppDocuments>/suki_pos/item_images/`
///
/// **Design**:
/// - Copies picked images into the managed folder at save time.
/// - Only the *filename* (e.g. `item_1234567890.jpg`) is stored in SQLite,
///   keeping DB paths portable and independent of the device's full path.
/// - At display time, [resolveImagePath] reconstructs the full absolute path
///   from the stored filename.
class ImageStorageService {
  static const String _subDir = 'suki_pos/item_images';

  /// Returns (and creates if necessary) the fixed item images directory.
  static Future<Directory> getImageDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDocDir.path, _subDir));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  /// Copies [sourcePath] into the managed folder and returns the stored
  /// **filename only** (to be persisted in the database).
  ///
  /// If [sourcePath] is already inside the managed folder (i.e. the same
  /// image is re-saved), the existing filename is returned without re-copying.
  static Future<String> saveImage(String sourcePath) async {
    final imageDir = await getImageDirectory();
    final sourceFile = File(sourcePath);

    // If already in our managed folder, just return the filename
    if (p.isWithin(imageDir.path, sourcePath)) {
      return p.basename(sourcePath);
    }

    final ext = p.extension(sourcePath).toLowerCase();
    final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}$ext';
    await sourceFile.copy(p.join(imageDir.path, fileName));
    return fileName;
  }

  /// Resolves a stored filename to a full absolute path.
  /// Returns `null` if [storedValue] is null, empty, or the file doesn't exist.
  ///
  /// Handles both legacy absolute paths (migrating gracefully) and new-style
  /// filenames transparently.
  static Future<String?> resolveImagePath(String? storedValue) async {
    if (storedValue == null || storedValue.isEmpty) return null;

    // New-style: just a filename with no directory separator
    if (!storedValue.contains('/') && !storedValue.contains(r'\')) {
      final imageDir = await getImageDirectory();
      final fullPath = p.join(imageDir.path, storedValue);
      return File(fullPath).existsSync() ? fullPath : null;
    }

    // Legacy-style or absolute path: use as-is if file still exists
    return File(storedValue).existsSync() ? storedValue : null;
  }

  /// Deletes the image file for the given stored filename/path.
  /// Silently ignores errors if the file does not exist.
  static Future<void> deleteImage(String? storedValue) async {
    if (storedValue == null || storedValue.isEmpty) return;
    try {
      final resolved = await resolveImagePath(storedValue);
      if (resolved != null) {
        await File(resolved).delete();
      }
    } catch (_) {}
  }
}
