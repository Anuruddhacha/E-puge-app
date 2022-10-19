import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:epurge/auth_page.dart';
import 'package:epurge/main.dart';
import 'package:epurge/purging_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';
import 'package:passcode_screen/passcode_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_countdown_clock/slide_countdown_clock.dart';
import 'package:epurge/file_destruction/FileDestructor.dart';
import 'package:epurge/Aes_encryption/AesEncrypt.dart';




class DataFiles extends StatefulWidget {
  final List<DataFile> files;
  


  const DataFiles({ Key? key,
  required this.files,
   }) : super(key: key);

  @override
  State<DataFiles> createState() => _DataFilesState();
}

class _DataFilesState extends State<DataFiles> {

  DateTime? _purgingDate;
  Duration? _duration = Duration(hours: 6);
  bool? isDateSetTimer1 = false;
  bool? isInit = false;
  bool? isDataSetTimer2 = false;
  int purgeDateChangeTime = 0;
  bool isLoading = false;


@override
void initState() {
  
    super.initState();
    
    
  }

  void init() async{
     SharedPreferences prefs = await SharedPreferences.getInstance();
   String? purDate =  prefs.getString("purgingDate");
    if(purDate != null && purDate != ''){
      setState(() {
        _purgingDate = DateTime.parse(purDate);
        _duration = _purgingDate?.difference(DateTime.now());
        isDateSetTimer1 = true;
        print("timer1 started");
        isInit = true;
        print(_duration);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if(!isInit!){
     init();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("All Files"),
        centerTitle: true,
        leading:  IconButton(onPressed: (){
            Navigator.pop(context);
          }, icon: Icon(Icons.arrow_back_ios)),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width:MediaQuery.of(context).size.width,
        child: Stack(
          children:[
            
         Padding(
           padding: const EdgeInsets.only(top: 100),
           child: Center(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing:8,
                crossAxisSpacing: 8),
                itemCount: widget.files.length,
               itemBuilder: (context,index){
                 final file = widget.files[index];
                   return buildFile(file);
               }),
               
               ),
         ),
        Container(
              width: MediaQuery.of(context).size.width,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2)
              ),
              child: Column(
                children: [

                 MaterialButton(
  padding: EdgeInsets.only(left: 50,right: 50),
  color: Theme.of(context).primaryColor,
  child: Text('Set time to purge',style: TextStyle(color: Colors.white,
      fontWeight: FontWeight.bold,fontSize: 17),),
  onPressed: () async{
     
  
    DateTime? purgingDate = await showDatePicker(
    context: context,
     initialDate: DateTime.now(),
      firstDate: DateTime(2020),
       lastDate: DateTime(2100));
     
       DateTime now = DateTime.now();

       Duration duration = purgingDate!.difference(now);
       

       if(purgingDate != null && duration.inMinutes > 0){
         setState(() {

           _purgingDate = purgingDate;
           _duration = _purgingDate!.difference(now);
           
           isDateSetTimer1  = true;
           
           print("timer2 started");
         });
         SharedPreferences prefs = await SharedPreferences.getInstance();
         prefs.setString("purgingDate", _purgingDate.toString());
        
           Navigator.of(context).push(MaterialPageRoute(builder: (context)=>AuthPage()));
        
       }
   print("new purge date =  $_purgingDate");
   print("new duration = $_duration");
      

  },
),

Text("Time till purge:",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),),

 
 isDateSetTimer1! ? SlideCountdownClock(
              duration: Duration(days: _duration!.inDays, minutes: _duration!.inMinutes),
              slideDirection: SlideDirection.Up,
              separator: ":",
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              shouldShowDays: true,
            
              onDone: () {
               _autoPurge();
              },
              
            ): SizedBox.shrink() ,
            

                ],
              ),
            ),




          ]
        ),
      ),
      
      //backgroundColor:Colors.grey.withOpacity(0.2),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {

           _showLockScreen(
      context,
      opaque: false,
      cancelButton: Text(
        'Cancel',
        style: const TextStyle(fontSize: 16, color: Colors.white,),
        semanticsLabel: 'Cancel',
      ),
    );

        },
        label: const Text('Purge'),
        backgroundColor: Colors.red,
      ),
  
    );
  }





 Widget buildFile(DataFile file) {
   final kb = file.size / 1024;
   final mb = kb / 1024;

   final fileSize = mb >=1 ? '${mb.toStringAsFixed(2)} MB' : '${kb.toStringAsFixed(2)} KB';
   final extension = file.extension ?? 'none';
   final color = getColor(extension);
   final name = file.name;
   

   return GestureDetector(
     onDoubleTap: (){


    // _deleteFile(file);

     },
     child: InkWell(
       onTap: () => OpenFile.open(file.path!),
       child: Container(
         padding: EdgeInsets.all(8),
         child:Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Expanded(child: Container(
               child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('.$extension',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),),
                    ],
                  )
               ),
             )),
             const SizedBox(height:8),
             Text('$name',
             style: TextStyle(
               fontSize: 18,
               fontWeight: FontWeight.bold,
               overflow: TextOverflow.ellipsis
             ),),
   
             Text(fileSize,
             style: TextStyle(fontSize: 10),)
   
           ],
         )
       ),
     ),
   );


  }

  getColor(String extension) {
    print(extension);
    if(extension == 'jpeg'){
      return Colors.green;
    }
    if(extension == 'mp3'){
      return Colors.pink;
    }
    if(extension == 'zip'){
      return Colors.yellow;
    }
     if(extension == 'pdf'){
      return Colors.blue;
    }else{
      return Colors.brown;
    }
  }

  void _deleteFile(DataFile file) async{

  

  
     final currentFile = File('${file.path}');

     print("current file path == "+currentFile.path);

     
      
     currentFile.delete();
     
     print("file deleted");
     

     final SharedPreferences prefs = await SharedPreferences.getInstance();
  
   final String? datafilesString = await prefs.getString('data_files');
   final List<DataFile> datafileslist = DataFile.decode(datafilesString!);

   datafileslist.remove(file);
   print(datafileslist.length);

   
   
   setState(() {
     widget.files.remove(file);
   });
   print(widget.files.length);

   final String encoded_data = DataFile.encode(widget.files);
   await prefs.setString('data_files', encoded_data);

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
         // bottomWidget: _passcodeRestoreButton(),
        ),
      ));
}



final StreamController<bool> _verificationNotifier = StreamController<bool>.broadcast();
bool isAuthenticated = false;


_passcodeEntered(String enteredPasscode) async{
 
    String? passcode;
        SharedPreferences prefs = await SharedPreferences.getInstance();
      
       bool? _isliggedin = prefs.getBool("_isLoggedIn");
       if(_isliggedin!){
         passcode =  prefs.getString("passcode");
       }


  var storedPasscode = passcode;
  
  bool isValid = storedPasscode == enteredPasscode;


  _verificationNotifier.add(isValid);
  if (isValid) {
    setState(() {
      this.isAuthenticated = isValid;
      
 
    });
    _purgeDialog();
  }
}


@override
  void dispose() {
    _verificationNotifier.close();
    super.dispose();
  }

  
  _passcodeCancelled() {
    Navigator.maybePop(context);
  }



  _purgeDialog() {
    Navigator.maybePop(context).then((result) {
      if (!result) {
        return;
      }
      _confirmPurgeDialog(() {
        Navigator.maybePop(context);
      });
    });
  }


  _confirmPurgeDialog(VoidCallback onAccepted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.teal[50],
          title: Text(
            "Confirm Purge",
            style: const TextStyle(color: Colors.black87),
          ),
          content: Text(
            "Confirm by tapping YES and WAIT",
            style: const TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            FlatButton(
              child: Text(
                "NO",
                style: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.maybePop(context);
               
              },
            ),
            FlatButton(
              
              child: Text(
                "YES",
                style: const TextStyle(fontSize: 18),
              ), 
              onPressed: (){
                Navigator.maybePop(context);
                
                
                _purge();
              },
            ),
           
          ],
        );
      },
    );
  }

  

  void _purge() {
      

      print("purging starting");

      _curruptAndPurge();

   // Navigator.of(context).push(MaterialPageRoute(builder: ((context) => PurgingScreen())));
    Get.off(PurgingScreen());

  }

  void _autoPurge() {

    _curruptAndPurge();
    Get.off(PurgingScreen());
    //Navigator.of(context).push(MaterialPageRoute(builder: ((context) => PurgingScreen())));
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

 
  






}