import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sprintf/sprintf.dart';

import 'main.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  ImagePicker picker = ImagePicker();
  String secondButtonText = 'Record video';

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 5), () {
      setState(() {
        _recordVideo();
      });
    });
  }

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
        // GallerySaver.saveVideo(recordedVideo.path, albumName: 'MyVideos')
        //     .then((value) {
        //
        // });
        setState(() {
          secondButtonText = 'Video Saved!';
          Navigator.pop(
              context,
              MaterialPageRoute(
                builder: (context) => Myapp(),
              ));
        });

        // Get the internal storage directory
        // final storage = await getExternalStorageDirectory();
        //
        // // Create a custom album directory
        // final customAlbum = Directory('${storage!.path}/MyVideos');
        // await customAlbum.create(recursive: true);
        //
        // // Define the path where the video will be saved
        // final String filePath = '${customAlbum}${DateTime.now()}.mp4';
        //
        // File videoFile = File(recordedVideo!.path);
        //
        // //String fileFormat = recordedVideo!.path.split('.').last;
        //
        // await videoFile.copy(
        //   filePath,
        // );

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
        // GallerySaver.saveVideo(recordedVideo.path, albumName: "RPSApp123")
        //     .then((value) {
        //
        // });
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
        // await dio.download(url, saveFile.path,
        //     onReceiveProgress: (value1, value2) {
        //       setState(() {
        //         progress = value1 / value2;
        //       });
        //     });
        // if (Platform.isIOS) {
        //   await ImageGallerySaver.saveFile(saveFile.path,
        //       isReturnPathOfIOS: true);
        // }
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

  // downloadFile() async {
  //   setState(() {
  //     loading = true;
  //     progress = 0;
  //   });
  //   bool downloaded = await saveVideo(
  //       "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4",
  //       "video.mp4");
  //   if (downloaded) {
  //     print("File Downloaded");
  //   } else {
  //     print("Problem Downloading File");
  //   }
  //   setState(() {
  //     loading = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        //   child: loading
        //       ? Padding(
        //           padding: const EdgeInsets.all(8.0),
        //           child: CircularProgressIndicator(
        //             value: progress,
        //           ),
        //         )
        //       : ElevatedButton.icon(
        //           icon: Icon(
        //             Icons.download_rounded,
        //             color: Colors.white,
        //           ),
        //           onPressed: _recordVideo,
        //           label: Text(
        //             "Download Video",
        //             style: TextStyle(color: Colors.white, fontSize: 25),
        //           )),
        child: InkWell(
          onTap: () {
            setState(() {
              Navigator.pop(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Myapp(),
                  ));
            });
          },
        ),
      ),
    );
  }
}
