import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../globals.dart' as globals;

import 'Notification.dart';
import 'Student.dart';
import 'Camera.dart';
import 'NewStudent.dart';

import '../API/Server.dart';
import '../API/DataProvider.dart';

import "../DB/Image.dart";
import '../DB/Students.dart';
import '../DB/Groups.dart';

class GroupPage extends StatefulWidget {
  final Group currentGroup;

  GroupPage({
    this.currentGroup
  });

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {

  String searchBy;

  List<Student> students = [];
  List<ImageData> studentImages = [];

  reverseDate(String date) {
    var parts = date.split(" ");
    date = parts[0];

    parts = date.split("-");

    if (parts.length < 2) {
      return "";
    }

    date = parts[2] + "-" + parts[1] + "-" + parts[0];

    return date;
  }

  @override
  initState() {
    super.initState();
    init();
  }

  void init () async {
    List<GroupStudent> groupStudents = [];

    GroupStudent searchingStudents = new GroupStudent(
        groupID: widget.currentGroup.id
    );

    DataPack request = new DataPack(
        token: globals.authProvider.token,
        body: searchingStudents.toJson()
    );

    var response = await Server().getData("group-students", request.toJson());

    if ( response.statusCode != 200 ) {
      Notifications(context: context).serverError();
      return;
    }

    RespDynamic data = RespDynamic.fromJson(jsonDecode(response.body));

    if ( data.status != 200 ) {
      Notifications(context: context).customError(data.body.toString());
      return;
    }

    for ( Map<String, dynamic> student in data.body ) {
      groupStudents.add( GroupStudent.fromJson( student ) );
    }

    for ( GroupStudent student in groupStudents ) {
      Student requestedStudent = new Student(
          id: student.id
      );
      request.body = requestedStudent.toJson();

      response = await Server().getData("students", request.toJson());

      if ( response.statusCode != 200 ) {
        Notifications(context: context).serverError();
        return;
      }

      data = RespDynamic.fromJson( jsonDecode( response.body ) );

      if ( data.status != 200 ) {
        Notifications(context: context).customError(data.body.toString());
      }

      print(data.body);

      for ( Map<String, dynamic> item in data.body ) {
        students.add( Student.fromJson( item ) );
      }

      if ( students.last.image != 0 ) {
        ImageData searchingImage = new ImageData(
            id: students.last.image
        );

        request.body = searchingImage.toJson();
        response = await Server().getData("images", request.toJson());

        if ( response.statusCode != 200 ) {
          studentImages.add( new ImageData(id: -1) );
          continue;
        }

        data = RespDynamic.fromJson( jsonDecode( response.body ) );

        if ( data.status != 200 ) {
          studentImages.add( new ImageData(id: -1) );
          continue;
        }

        for ( Map<String, dynamic> image in data.body ) {
          studentImages.add( ImageData.fromJson(image) );
        }
      } else {
        studentImages.add( new ImageData(id: -1) );
      }

    }

    setState(() {});
  }

  Widget studentCard(BuildContext context, int index) {
    var currentStudent = students.elementAt(index);
    var currentImage = studentImages.elementAt(index);

    return Card(
      elevation: 1,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => StudentPage(
            currentStudent: currentStudent,
            userImage: currentImage,
          )));
        },
        child: Padding(
          padding: EdgeInsets.all(5),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                        alignment: Alignment.topCenter,
                        image: currentImage.id == -1 ?
                        AssetImage("assets/logo.jpg") :
                        NetworkImage("http://" + Server().serverUri + "/robotenok/images/" + currentImage.filename),
                        fit: BoxFit.fitWidth,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(5))
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 18),
                      Text(
                        currentStudent.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.cancel, size: 18),
                      Text(
                        "Не оплачено",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 18),
                      Text(
                        currentStudent.phone,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      )
                    ],
                  )
                ],
              ),
              // Spacer()
            ],

          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(0, 0, 0, 0),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_ios_outlined, color: Colors.black),
        ),
        title: Text("Суббота 10:00", style: TextStyle(color: Colors.black),),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Device device = Device();
          var request = DataPack(
            token: globals.authProvider.token,
            body: Device().toJson(),
          );
          var data = await Server().getData("addDevice", request.toJson());

          if ( data.statusCode != 200 ) {
            data.body != null
                ? Notifications(context: context).customError(data.body)
                : Notifications(context: context).serverError();
          }

          SingleResp response = SingleResp.fromJson( jsonDecode(data.body) );
          device = Device.fromJson( response.body );

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
                actions: [ Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    child: QrImage(
                      data: device.hash,
                      size: 280,
                      // embeddedImage: AssetImage("assets/logo.jpg"),
                      // embeddedImageStyle: QrEmbeddedImageStyle(
                      //   size: Size(100, 100)
                      // ),
                    ),
                  ),
                )
              ]
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20))
            ),
            child: TextField(
              minLines: 1,
              maxLines: 1,
              decoration: InputDecoration(
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: "Имя, тел",
                prefixIcon: Icon(Icons.search)
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              itemCount: students.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:  2, childAspectRatio: 0.75),
              padding: EdgeInsets.only(left: 15, right: 15),
              itemBuilder: (context, index) => studentCard(context, index),
            ),
          )
        ],
      ),
    );
  }
}
