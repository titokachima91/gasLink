import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads vendor shop photos to Firebase Storage.
///
/// The app uses its own Firestore-based session, so uploads perform a
/// short-lived anonymous Firebase Auth sign-in to satisfy the storage rules
/// (`request.auth != null`), then sign out again. Identity resolution in the
/// rest of the app is untouched because no Firebase Auth user exists outside
/// the upload window.
class VendorImageService {
  VendorImageService._();
  static final VendorImageService instance = VendorImageService._();

  /// Hard cap enforced by storage rules and validated client-side.
  static const int maxBytes = 5 * 1024 * 1024; // 5 MB

  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  ];

  /// Pure validation helpers (unit-testable without Firebase).
  static String? validateType(String? mimeType) {
    if (mimeType == null ||
        !allowedMimeTypes.contains(mimeType.toLowerCase())) {
      return 'Tafadhali chagua picha (JPG, PNG, WEBP, GIF).';
    }
    return null;
  }

  static String? validateSize(int bytes) {
    if (bytes > maxBytes) {
      return 'Picha ni kubwa kuliko ${maxBytes ~/ (1024 * 1024)} MB.';
    }
    return null;
  }

  /// File extension used for the stored object, based on the MIME type.
  static String extensionFor(String? mimeType) {
    switch ((mimeType ?? '').toLowerCase()) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      default:
        return 'jpg';
    }
  }

  /// Uploads [file] under `vendor_images/{vendorId}/` and returns the
  /// download URL. Throws on auth, size, or network failures.
  Future<String> uploadShopImage({
    required String vendorId,
    required XFile file,
  }) async {
    final typeError = validateType(file.mimeType);
    if (typeError != null) {
      throw FormatException(typeError);
    }

    final bytes = await file.readAsBytes();
    final sizeError = validateSize(bytes.length);
    if (sizeError != null) {
      throw FormatException(sizeError);
    }

    final auth = FirebaseAuth.instance;
    var signedInHere = false;
    try {
      // Storage rules require an authenticated identity. Best-effort: if the
      // anonymous provider is disabled this throws and the caller surfaces a
      // friendly error.
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        signedInHere = true;
      }

      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance.ref(
        'vendor_images/$vendorId/shop_$stamp.${extensionFor(file.mimeType)}',
      );
      final metadata = SettableMetadata(
        contentType: file.mimeType ?? 'image/jpeg',
      );
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } finally {
      if (signedInHere) {
        try {
          await auth.signOut();
        } catch (_) {
          // Keep the local session regardless of sign-out failures.
        }
      }
    }
  }
}
