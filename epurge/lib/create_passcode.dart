import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CreatePassCode extends StatefulWidget {
  const CreatePassCode({ Key? key }) : super(key: key);

  @override
  State<CreatePassCode> createState() => _CreatePassCodeState();
}

class _CreatePassCodeState extends State<CreatePassCode> {

  TextEditingController _passcodeController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Navigator.of(context).pop(),
  ),
      ),
      body:Center(
        child: Column(
          mainAxisAlignment:MainAxisAlignment.center,
          children: [
            Text('You can create a passcode only using 0-9 digits',style: TextStyle(fontSize: 16,color: Colors.black),),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _passcodeController,
              obscureText: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Passcode',
                
              ),
            )
            ),

            MaterialButton(
  padding: EdgeInsets.only(left: 50,right: 50),
  color: Theme.of(context).primaryColor,
  child: Text('Save Passcode',style: TextStyle(color: Colors.white,
      fontWeight: FontWeight.bold,fontSize: 17),),
  onPressed: () {
    _savePasCode();
  },
)

          ],
        ),
      )
    );
  }

  void _savePasCode() async{

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String passcode = _passcodeController.text;
  int passcodeLen = passcode.length;

 if(!isNumeric(passcode)){
   _showSnack("Passcode must only contains 0-9 digits");
 }else if(passcodeLen != 6){
   _showSnack("Passcode lenght should be 6");
 }else{

prefs.setString("passcode", passcode);
prefs.setBool("_isLoggedIn", true);

_showSnack("Passcode created successfully");

Timer(const Duration(seconds: 3), () {
  Navigator.pop(context);
});

 }

  }




  bool isNumeric(String s) {
 if (s == null) {
   return false;
 }
 return double.tryParse(s) != null;
}

  void _showSnack(String message) {
 
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