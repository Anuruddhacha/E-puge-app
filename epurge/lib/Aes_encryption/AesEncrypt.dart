import 'package:aes_crypt/aes_crypt.dart';
import 'dart:typed_data';


class AesEncrypt{

static String encrypt_file(String path) {
    
    AesCrypt crypt = AesCrypt();
    crypt.setOverwriteMode(AesCryptOwMode.on);
    crypt.setPassword('my cool password');
    String? encFilepath;
    try {
      encFilepath = crypt.encryptFileSync(path);
      print('The encryption has been completed successfully.');
      print('Encrypted file: $encFilepath');
    } catch (e) {
     print("${e}");
    }
    return encFilepath!;
  }



}