import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sprintf/sprintf.dart';
import 'package:video/video_collection.dart';

import 'gallery.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Myapp(),
    );
  }
}

class Myapp extends StatefulWidget {
  const Myapp({Key? key}) : super(key: key);

  @override
  State<Myapp> createState() => _MyappState();
}

class _MyappState extends State<Myapp> {
  ImagePicker picker = ImagePicker();
  String secondButtonText = 'Record video';

  @override
  void dispose() {
    super.dispose();
  }

  //  record video function
  void _recordVideo() async {
    ImagePicker.platform
        .pickVideo(source: ImageSource.camera)
        .then((recordedVideo) async {
      assert(recordedVideo != null);
      print(recordedVideo!.path);
      if (recordedVideo != null && recordedVideo.path != null) {
        setState(() {
          secondButtonText = 'saving in progress...';
        });

        // take a unik name always
        DateTime dateTime = DateTime.now();
        String pathString = sprintf('RPSApp_%d%02d%02d_%02d%02d%02d.mp4', [
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second
        ]);
        saveVideo(recordedVideo.path, pathString);
      }
    });
  }

  final Dio dio = Dio();
  bool loading = false;
  double progress = 0;

  Future<bool> saveVideo(String url, String fileName) async {
    Directory directory;
    try {
      if (Platform.isAndroid) {
        if (await _requestPermission(Permission.storage)) {
          directory = (await getExternalStorageDirectory())!;
          String newPath = "";
          print(directory);
          List<String> paths = directory.path.split("/");
          for (int x = 1; x < paths.length; x++) {
            String folder = paths[x];
            if (folder != "Android") {
              newPath += "/" + folder;
            } else {
              break;
            }
          }
          newPath = newPath + "/Movies/RPSApp";
          directory = Directory(newPath);
        } else {
          return false;
        }
      } else {
        if (await _requestPermission(Permission.photos)) {
          directory = await getTemporaryDirectory();
        } else {
          return false;
        }
      }
      File saveFile = File(directory.path + "/$fileName");
      File videoFile = File(url);
      print("saveFile = ${directory.path}/$fileName");
      if (!await directory.exists()) {
        print("directory exists.......not");
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        print("directory exists.......");
        await videoFile.copy(saveFile.path);
        print("videoFile copied to ${saveFile.path}");

        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Video Player')),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Center(
                child: IconButton(
                    onPressed: () {
                      _recordVideo();
                    },
                    icon: Icon(
                      Icons.video_camera_back,
                      size: 60,
                    )),
              ),
              Center(
                child: IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => gallery(),
                          ));
                    },
                    icon: Icon(
                      Icons.photo,
                      size: 60,
                    )),
              ),
            ],
          ),
          SizedBox(
            height: 50,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Center(
                child: IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerCustum(),
                          ));
                    },
                    icon: Icon(
                      Icons.video_collection,
                      size: 60,
                    )),
              ),
            ],
          )
        ],
      ),
    );
  }
}
