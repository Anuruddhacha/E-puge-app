import 'dart:async';
import 'dart:io';
import 'package:disk_space/disk_space.dart';
import 'package:epurge/Aes_encryption/AesEncrypt.dart';
import 'package:epurge/create_passcode.dart';
import 'package:epurge/data_files.dart';
import 'package:epurge/main.dart';
import 'package:epurge/purging_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';
import 'package:passcode_screen/passcode_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({ Key? key }) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {

  final StreamController<bool> _verificationNotifier = StreamController<bool>.broadcast();
  bool isAuthenticated = false;
  bool isPurgeStart = false;

  @override
  void dispose() {
    _verificationNotifier.close();
    super.dispose();
  }

double _total = 0;
  double _diskSpace = 0;
  Map<Directory, double> _directorySpace = {};
  
  @override
  void initState() {
    super.initState();
    initDiskSpace();
  }

  Future<void> initDiskSpace() async {
    double? diskSpace = 0;
   

    diskSpace = await DiskSpace.getFreeDiskSpace;

    List<Directory> directories;
    Map<Directory, double> directorySpace = {};

    if (Platform.isIOS) {
      directories = [await getApplicationDocumentsDirectory()];
    } else if (Platform.isAndroid) {
      directories =
          await getExternalStorageDirectories(type: StorageDirectory.movies)
              .then(
        (list) async => list ?? [await getApplicationDocumentsDirectory()],
      );
    } else {
      return;
    }

    for (var directory in directories) {
      var space = await DiskSpace.getFreeDiskSpaceForPath(directory.path);
      directorySpace.addEntries([MapEntry(directory, space!)]);
      var total = await DiskSpace.getTotalDiskSpace;
      setState(() {
        _total = total!;
      });
    }

    if (!mounted) return;

    setState(() {
      _diskSpace = diskSpace!;
      _directorySpace = directorySpace;
      
    });
  }

@override
  Widget build(BuildContext context) {

   

    return !isAuthenticated ? Scaffold(
       body: Center(
         child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Text('You are ${isAuthenticated ? '' : 'not'}'
          ' authenticated',style: TextStyle(fontSize: 16,color: Colors.white),),
      SizedBox(height: 10,),
      _lockScreenButton(context),
      SizedBox(height: 10,),
       Text('You can create a passcode only once',style: TextStyle(fontSize: 16,color: Colors.red),),
       _signupToAppButton(context)
    ],
  ),
       ),
       backgroundColor: Colors.grey.withOpacity(0.2),
    ) : Scaffold(

     

     appBar: AppBar(title: const Text('EPurge')),
     backgroundColor: Colors.grey.withOpacity(0.2),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                ),
                child: Column(
                  children:[
                    Center(
              child: Text( _total < 1024 ?'Total Space on device (MB): ${_total.toStringAsFixed(2)}\n'
                          :'Total Space on device (GB): ${(_total/1024).toStringAsFixed(2)}\n'
              ,style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
            ),
                   Center(
              child: Text(_diskSpace < 1024 ? 'Free Space on device (MB): ${_diskSpace.toStringAsFixed(2)}\n'
                        :'Free Space on device (GB): ${(_diskSpace/1024).toStringAsFixed(2)}\n',
              style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
            ),
           

                  ]
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async{
                  final result  = await FilePicker.platform.pickFiles();
                  if(result == null){
                    return;
                  }
                final file  = result.files.first;
                 
                final newFile = await saveFilePermenantly(file);
                
                 final SharedPreferences prefs = await SharedPreferences.getInstance();

                 
                 DataFile dataFile = DataFile(name:file.name,path: newFile.path, extension: file.extension,size: file.size);

                 // Encode and store data in SharedPreferences
                final String encodedData = DataFile.encode([dataFile]);

                final firstTime = await prefs.getBool("isFirst");

                //for first time
                if(firstTime == null){
                  await prefs.setString('data_files', encodedData);
                  await prefs.setBool("isFirst",false);
                  print("datafiles saved first time");
                }
                else if(firstTime == false){//second and other times
                  // Fetch and decode data
              final String? datafilesString = await prefs.getString('data_files');
              final List<DataFile> datafileslist = DataFile.decode(datafilesString!);

              datafileslist.add(dataFile);
              final String encoded_data = DataFile.encode(datafileslist);
              await prefs.setString('data_files', encoded_data);
      
             //  final String? datafilesString_new = await prefs.getString('data_files');
             // final List<DataFile> datafileslist_new = DataFile.decode(datafilesString_new!);
               //delete current file
               

               openDataFiles(datafileslist);
                }

               },
              child: const Text('Add Files'),
            ),
            ElevatedButton(onPressed: (){
             
             _goToAllFilesPage();

            },
             child: const Text("Show All Files"))
          ],
        ),
      ),




    );



  }


_lockScreenButton(BuildContext context) => MaterialButton(
  padding: EdgeInsets.only(left: 50,right: 50),
  color: Theme.of(context).primaryColor,
  child: Text('Enter Passcode',style: TextStyle(color: Colors.white,
      fontWeight: FontWeight.bold,fontSize: 17),),
  onPressed: () async{

 SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? _isLoggedIn = prefs.getBool('_isLoggedIn');
  if(_isLoggedIn == null ){
     _showSnakBar("Create a passcode first!");
  }
  else if(_isLoggedIn == true){
    _showLockScreen(
      context,
      opaque: false,
      cancelButton: Text(
        'Cancel',
        style: const TextStyle(fontSize: 16, color: Colors.white,),
        semanticsLabel: 'Cancel',
      ),
    );
  }
    
    
  },
);
 _signupToAppButton(BuildContext context){
  return  MaterialButton(
  padding: EdgeInsets.only(left: 50,right: 50),
  color: Theme.of(context).primaryColor,
  child: Text('Create Passcode',style: TextStyle(color: Colors.white,
      fontWeight: FontWeight.bold,fontSize: 17),),
  onPressed: () {
    _createPasscode();
  },
);
}
  

_showLockScreen(BuildContext context,
    {bool? opaque,
      CircleUIConfig? circleUIConfig,
      KeyboardUIConfig? keyboardUIConfig,
      Widget? cancelButton,
      List<String>? digits}) async{

        


  Navigator.push(
      context,
      PageRouteBuilder(
        opaque: opaque!,
        pageBuilder: (context, animation, secondaryAnimation) => PasscodeScreen(
          title: Text(
            'Enter Passcode',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 28),
          ),
          circleUIConfig: circleUIConfig,
          keyboardUIConfig: keyboardUIConfig,
          passwordEnteredCallback: _passcodeEntered,
          cancelButton: cancelButton,
          deleteButton: Text(
            'Delete',
            style: const TextStyle(fontSize: 16, color: Colors.white),
            semanticsLabel: 'Delete',
          ),
          shouldTriggerVerification: _verificationNotifier.stream,
          backgroundColor: Colors.black.withOpacity(0.8),
          cancelCallback: _passcodeCancelled,
          digits: digits,
          passwordDigits: 6,
          bottomWidget: _passcodeRestoreButton(),
        ),
      ));
}

var enteredTimes = 0;


_passcodeEntered(String enteredPasscode) async{
  print(enteredTimes);
  enteredTimes++;
  if(enteredTimes == 2){

    _showSnakBar("You have only two attempt");

  }
    String? passcode;
        SharedPreferences prefs = await SharedPreferences.getInstance();
      
       bool? _isliggedin = prefs.getBool("_isLoggedIn");
       if(_isliggedin!){
         passcode = prefs.getString("passcode");
       }


  var storedPasscode = passcode;
  
  bool isValid = storedPasscode == enteredPasscode;

  if(enteredTimes == 3 && !isValid){
    print("purging will start in 4 secs....");

    Timer(Duration(seconds: 3), () {

    _curruptAndPurge();
    Get.to(PurgingScreen());  //////// routing changed
});


  }
  _verificationNotifier.add(isValid);
  if (isValid) {
    setState(() {
      this.isAuthenticated = isValid;
      

    });
  //  Get.to(HomePage());   //////// routing changed
  }
}



  _passcodeCancelled() {
    Navigator.maybePop(context);
  }


_passcodeRestoreButton() => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10.0, top: 20.0),
      child: FlatButton(
        child: Text(
          "Reset passcode",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w300),
        ),
        splashColor: Colors.white.withOpacity(0.4),
        highlightColor: Colors.white.withOpacity(0.2),
        onPressed: _resetApplicationPassword,
      ),
    ),
  );

  _resetApplicationPassword() {
    Navigator.maybePop(context).then((result) {
      if (!result) {
        return;
      }
      _restoreDialog(() {
        Navigator.maybePop(context);
      });
    });
  }


  _restoreDialog(VoidCallback onAccepted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.teal[50],
          title: Text(
            "Reset passcode",
            style: const TextStyle(color: Colors.black87),
          ),
          content: Text(
            "Passcode reset is a non-secure operation!",
            style: const TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            FlatButton(
              child: Text(
                "Cancel",
                style: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.maybePop(context);
              },
            ),
            FlatButton(
              child: Text(
                "Ok",
                style: const TextStyle(fontSize: 18),
              ),
              onPressed: onAccepted,
            ),
          ],
        );
      },
    );
  }



  _createPasscode() async{
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? _isLoggedIn = prefs.getBool('_isLoggedIn');

 if(_isLoggedIn == null){

  Navigator.of(context).push(MaterialPageRoute(builder: ((context) => CreatePassCode())));
  

 }
 else if (_isLoggedIn = true){

  _showSnakBar("You have already created a passcode");

 }
  


  }

  void _showSnakBar(String message) {

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


  void _curruptAndPurge() async{


final SharedPreferences prefs = await SharedPreferences.getInstance();

     final firstTime = await prefs.getBool("isFirst");

                //for first time
                if(firstTime == null){//first visit
                  print("first time no files in app");
                  _showSnakBar("No files available");
                }
                else if(firstTime == false){//second and other times
                  // Fetch and decode data
              final String? datafilesString = await prefs.getString('data_files');
              final List<DataFile> datafileslist = DataFile.decode(datafilesString!);

              
                  if(datafileslist.isNotEmpty){

                  List<String>? purgedList=[];

                  datafileslist.forEach((file) {
                  
                  if(!purgedList.contains(file.path)){
                    purgedList.add(file.path!);
                    var enc_path =   AesEncrypt.encrypt_file(file.path!);
                  print("done destructing");
              
                  File? encFile1 = File(enc_path);
                  File? acFile = File(file.path!);
                  
                  acFile.delete();
                  encFile1.delete();
                  }
                  
                  
                  });

                  
                  purgedList.clear();

                 }


                   final String encoded_data = DataFile.encode([]);
                   await prefs.setString('data_files', encoded_data);
                   prefs.setString("purgingDate",'');
                   print("done destructing");
               
                }



  }


  
  void openFile(PlatformFile file) {
    OpenFile.open(file.path);
   
  }

 

 Future<File> saveFilePermenantly(PlatformFile file) async{

  final appStorage = await getApplicationDocumentsDirectory();
  final newFile = File('${appStorage.path}/${file.name}');
  
  
  
  return File(file.path!).copy(newFile.path);

  }

  

  void openDataFiles(List<DataFile> datafileslist) {


  Navigator.of(context).push(MaterialPageRoute(
     builder: ((context) => DataFiles(files: datafileslist))
  ));


  }

  void _goToAllFilesPage() async{
     final SharedPreferences prefs = await SharedPreferences.getInstance();

     final firstTime = await prefs.getBool("isFirst");

                //for first time
                if(firstTime == null){//first visit
                  print("first time no files in app");
                  _showSnakBar("No files available");
                }
                else if(firstTime == false){//second and other times
                  // Fetch and decode data
              final String? datafilesString = await prefs.getString('data_files');
              final List<DataFile> datafileslist = DataFile.decode(datafilesString!);
                 if(datafileslist.isEmpty){
                   _showSnakBar("No files available");
                 }
                 else{
                   openDataFiles(datafileslist);
                 }
               
                }
     
    

  }

  


 




}

  




