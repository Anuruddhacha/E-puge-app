



import 'dart:io';

import 'package:epurge/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epurge/Aes_encryption/AesEncrypt.dart';

class FileDestructor{


static void _curruptAndPurge(BuildContext context) async{


final SharedPreferences prefs = await SharedPreferences.getInstance();

     final firstTime = await prefs.getBool("isFirst");

                //for first time
                if(firstTime == null){//first visit
                  print("first time no files in app");
                  _showSnakBar("No files available",context);
                }
                else if(firstTime == false){//second and other times
                  // Fetch and decode data
              final String? datafilesString = await prefs.getString('data_files');
              final List<DataFile> datafileslist = DataFile.decode(datafilesString!);

              


                 if(datafileslist.isNotEmpty){
                  
                  datafileslist.forEach((file) {
                  var enc_path =   AesEncrypt.encrypt_file(file.path!);
                  print("done destructing");
              
                  File? encFile1 = File(enc_path);

                  encFile1.delete();
                  
                  });

                  
                  


                 }
                   final String encoded_data = DataFile.encode([]);
                   await prefs.setString('data_files', encoded_data);
                   print("done destructing");
               
                }



  }

 static void _showSnakBar(String message,BuildContext context) {

final snackBar = SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'Ok',
              onPressed: () {
                // Some code to undo the change.
              },
            ),
          );

          // Find the ScaffoldMessenger in the widget tree
          // and use it to show a SnackBar.
          ScaffoldMessenger.of(context).showSnackBar(snackBar);

  }

 
  




}