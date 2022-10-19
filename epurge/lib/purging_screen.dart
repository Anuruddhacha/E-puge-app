import 'package:epurge/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PurgingScreen extends StatefulWidget {
  const PurgingScreen({ Key? key }) : super(key: key);

  @override
  State<PurgingScreen> createState() => _PurgingScreenState();
}

class _PurgingScreenState extends State<PurgingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  ListView(
          children: [
            // Load a Lottie file from your assets
            Lottie.asset('assets/99042-delete-files.json'), 
            SizedBox(height: 15,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Purged",style: TextStyle(fontSize: 20,color: Colors.red,fontWeight:FontWeight.bold,))),
            ),
             SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: MaterialButton(
  padding: EdgeInsets.only(left: 50,right: 50),
  color: Theme.of(context).primaryColor,
  child: Text('OK',style: TextStyle(color: Colors.white,
      fontWeight: FontWeight.bold,fontSize: 17),),
  onPressed: () {
    Navigator.of(context).push(MaterialPageRoute(builder: ((context) => AuthPage())));
  },
),
            )

          ],
        ),
    );
  }
}