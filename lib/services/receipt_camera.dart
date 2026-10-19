import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../core/id_generator.dart';
import '../domain/budget/budget_records.dart';

enum ReceiptSource { camera, gallery }

/// Takes or picks a receipt photo and keeps a copy inside the app's
/// private folder, so it is not left in the phone's shared gallery.
class ReceiptCamera {
  ReceiptCamera(this.folder, {ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final Directory folder;
  final ImagePicker _picker;

  /// The saved receipt, or [NoReceipt] when the owner backs out.
  Future<Receipt> capture(ReceiptSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source == ReceiptSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked == null) return const NoReceipt();
      final destination = p.join(folder.path, '${const IdGenerator().next()}.jpg');
      await File(picked.path).copy(destination);
      return ReceiptPhoto(destination);
    } on PlatformException catch (error) {
      throw ReceiptUnavailable(error.message ?? 'The camera could not be opened');
    }
  }

  void discard(Receipt receipt) {
    if (receipt is ReceiptPhoto) {
      final file = File(receipt.path);
      if (file.existsSync()) file.deleteSync();
    }
  }
}

class ReceiptUnavailable implements Exception {
  const ReceiptUnavailable(this.reason);

  final String reason;

  @override
  String toString() => reason;
}
