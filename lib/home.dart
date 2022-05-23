import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:recognition_app/main.dart';
import 'package:tflite/tflite.dart';

class homepage extends StatefulWidget {
  const homepage({Key? key}) : super(key: key);

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  late CameraImage imgcamera;
  bool isWorking = false;
  String result = "";
  CameraController cameraController =
      CameraController(cameras[0], ResolutionPreset.medium);
  loadModel() async {
    await Tflite.loadModel(
      model: "assets/mobilenet_v1_1.0_224.tflite",
      labels: "assets/mobilenet_v1_1.0_224.txt",
    );
  }

  initCamera() async {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        // CameraImage imgcamera;
        cameraController.startImageStream((imagefromStream) => {
              // CameraImage imgcamera = imagefromStream,
              if (!isWorking)
                {
                  isWorking = true,
                  imgcamera = imagefromStream,
                  runModelOnStreamFrames(imagefromStream),
                }
            });
      });
    });
  }

  runModelOnStreamFrames(CameraImage imagefromStream) async {
    // List<Uint8List> f = [];
    if (imgcamera != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: imagefromStream.planes.map((plane) {
            return plane.bytes;
          }).toList(), // required
          imageHeight: imagefromStream.height,
          imageWidth: imagefromStream.width,
          imageMean: 127.5, // defaults to 127.5
          imageStd: 127.5, // defaults to 127.5
          rotation: 90, // defaults to 90, Android only
          numResults: 2, // defaults to 5
          threshold: 0.1, // defaults to 0.1
          asynch: true // defaults to true
          );
      result = "";
      recognitions!.forEach((element) {
        result += element["label"] +
            " " +
            (element["confidence"] as double).toStringAsFixed(2) +
            "\n\n";
      });
      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadModel();
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
          child: Scaffold(
        body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(
                        "https://image.shutterstock.com/image-photo/ancient-temple-ruins-gadi-sagar-600w-786126286.jpg"))),
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 320,
                        width: 360,
                        child: Image.network(
                            "https://image.shutterstock.com/image-photo/ancient-temple-ruins-gadi-sagar-600w-786126286.jpg"),
                      ),
                    ),
                    Center(
                      child: FlatButton(
                        child: Container(
                          margin: EdgeInsets.only(top: 35),
                          height: 270,
                          width: 360,
                          child: imgcamera == null
                              ? Container(
                                  height: 270,
                                  width: 360,
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                  ),
                                )
                              : AspectRatio(
                                  aspectRatio:
                                      cameraController.value.aspectRatio,
                                  child: CameraPreview(cameraController),
                                ),
                        ),
                        onPressed: () {
                          initCamera();
                        },
                      ),
                    )
                  ],
                ),
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 50),
                    child: SingleChildScrollView(
                        child: Text(
                      result,
                      style: TextStyle(
                          backgroundColor: Colors.black,
                          fontSize: 30,
                          color: Colors.white),
                    )),
                  ),
                )
              ],
            )),
      )),
    );
  }
}
