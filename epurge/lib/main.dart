import 'dart:io';
import 'package:disk_space/disk_space.dart';
import 'package:epurge/auth_page.dart';
import 'package:epurge/data_files.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EPurge',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: AuthPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {


  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    return Scaffold(

     

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
              child: Text('Total Space on device (MB): ${_total.toStringAsFixed(2)}\n',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
            ),
                   Center(
              child: Text('Free Space on device (MB): ${_diskSpace.toStringAsFixed(2)}\n',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
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



class DataFile {
  final String? path,extension,name;
  final int size;
  

  DataFile({
    required this.name,
    required this.path,
    required this.extension,
    required this.size,
    
  });

  factory DataFile.fromJson(Map<String, dynamic> jsonData) {
    return DataFile(
      name: jsonData['name'],
      path: jsonData['path'],
      size: jsonData['size'],
      extension: jsonData['extension'],
     
    );
  }

  static Map<String, dynamic> toMap(DataFile dataFile) => {
        'path': dataFile.path,
        'size': dataFile.size,
        'extension': dataFile.extension,
         'name': dataFile.name
      };

  static String encode(List<DataFile> dataFiles) => json.encode(
        dataFiles
            .map<Map<String, dynamic>>((dataFile) => DataFile.toMap(dataFile))
            .toList(),
      );

  static List<DataFile> decode(String dataFiles) =>
      (json.decode(dataFiles) as List<dynamic>)
          .map<DataFile>((item) => DataFile.fromJson(item))
          .toList();
}
