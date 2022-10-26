import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({Key? key}) : super(key: key);

  @override
  _DrawScreenState createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final controller = ScreenshotController();
  GlobalKey globalKey = GlobalKey();
  Color selectedColor = Colors.blue;
  Color pickerColor = Colors.blue;
  double strokeWidth = 2.0;
  double opacity = 1.0;
  bool showBottomList = false;
  StrokeCap strokeCap = (Platform.isAndroid) ? StrokeCap.butt : StrokeCap.round;
  Selected selected = Selected.stroke;
  List<Drawing?> points = [];
  List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.black
  ];

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: controller,
      child: Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                          icon: const Icon(Icons.brush_rounded,
                              color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              if (selected == Selected.stroke) {
                                showBottomList = !showBottomList;
                              }
                              selected = Selected.stroke;
                            });
                          }),
                      IconButton(
                          icon: const Icon(Icons.opacity_rounded,
                              color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              if (selected == Selected.opacity) {
                                showBottomList = !showBottomList;
                              }
                              selected = Selected.opacity;
                            });
                          }),
                      IconButton(
                          icon: const Icon(Icons.color_lens_rounded,
                              color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              if (selected == Selected.color) {
                                showBottomList = !showBottomList;
                              }
                              selected = Selected.color;
                            });
                          }),
                      IconButton(
                          icon: const Icon(Icons.delete_rounded,
                              color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              showBottomList = false;
                              points.clear();
                            });
                          }),
                      IconButton(
                          icon: const Icon(Icons.save_rounded,
                              color: Colors.blue),
                          onPressed: () async {
                            final image = await controller
                                .captureFromWidget(drawingSpace());
                            if (image == null) {
                              return;
                            }
                            saveIMG(image);
                            Fluttertoast.showToast(
                                msg: 'Draw Saved To Gallery !',
                                toastLength: Toast.LENGTH_SHORT,
                                textColor: Colors.white,
                                backgroundColor: Colors.blue);
                          }),
                    ],
                  ),
                  Visibility(
                    visible: showBottomList,
                    child: (selected == Selected.color)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: getColorList(),
                          )
                        : Slider(
                            value: (selected == Selected.stroke)
                                ? strokeWidth
                                : opacity,
                            max: (selected == Selected.stroke) ? 50.0 : 1.0,
                            min: 0.0,
                            onChanged: (val) {
                              setState(() {
                                if (selected == Selected.stroke) {
                                  strokeWidth = val;
                                } else {
                                  opacity = val;
                                }
                              });
                            }),
                  ),
                ],
              ),
            ),
          ),
          body: drawingSpace()),
    );
  }

  Widget drawingSpace() {
    return Container(
      color: Colors.white,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(Drawing(
                offset: renderBox.globalToLocal(details.globalPosition),
                paint: Paint()
                  ..strokeCap = strokeCap
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth));
          });
        },
        onPanStart: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(Drawing(
                offset: renderBox.globalToLocal(details.globalPosition),
                paint: Paint()
                  ..strokeCap = strokeCap
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth));
          });
        },
        onPanEnd: (details) {
          setState(() {
            points.add(null);
          });
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: Drawer(
            drawingList: points,
          ),
        ),
      ),
    );
  }

  getColorList() {
    List<Widget> listWidget = [];
    for (Color color in colors) {
      listWidget.add(colorCircle(color));
    }
    Widget colorPicker = GestureDetector(
      onTap: () {
        showDialog(
          builder: (context) => AlertDialog(
            title: const Text('Pick Color'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  pickerColor = color;
                },
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Done'),
                onPressed: () {
                  setState(() => selectedColor = pickerColor);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          context: context,
        );
      },
      child: ClipOval(
        child: Container(
          height: 25,
          width: 25,
          decoration: const BoxDecoration(
              gradient: SweepGradient(
            startAngle: math.pi * 0.2,
            endAngle: math.pi * 1.7,
            colors: <Color>[
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.pink,
            ],
            stops: <double>[0.0, 0.25, 0.5, 0.75, 1.0],
            tileMode: TileMode.clamp,
          )),
        ),
      ),
    );
    listWidget.add(colorPicker);
    return listWidget;
  }

  Widget colorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: ClipOval(
        child: Container(
          height: 25,
          width: 25,
          color: color,
        ),
      ),
    );
  }
}

Future<String> saveIMG(Uint8List image) async {
  await [Permission.storage].request();

  final time = DateTime.now()
      .toIso8601String()
      .replaceAll('.', '_')
      .replaceAll(':', '_');
  final name = 'drawIt_$time';
  final res = await ImageGallerySaver.saveImage(image, name: name);
  return res['file_path'];
}

class Drawer extends CustomPainter {
  List<Drawing?> drawingList = [];
  List<Offset> offsetList = [];

  Drawer({required this.drawingList});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < drawingList.length - 1; i++) {
      if (drawingList[i] != null && drawingList[i + 1] != null) {
        canvas.drawLine(drawingList[i]!.offset, drawingList[i + 1]!.offset,
            drawingList[i]!.paint);
      } else if (drawingList[i] != null && drawingList[i + 1] == null) {
        offsetList.clear();
        offsetList.add(drawingList[i]!.offset);
        offsetList.add(Offset(
            drawingList[i]!.offset.dx + 0.1, drawingList[i]!.offset.dy + 0.1));
        canvas.drawPoints(
            ui.PointMode.points, offsetList, drawingList[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Drawing {
  Paint paint;
  Offset offset;

  Drawing({required this.paint, required this.offset});
}

enum Selected { stroke, opacity, color }
