import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_storage/screen/local_storage.dart';
import 'package:flutter_local_storage/services/permission_service.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:http/http.dart' as client;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
    MyApp({Key key}) :super(key : key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Demo",
      theme: ThemeData(primarySwatch: Colors.purple),
      home: Scaffold(
          appBar: AppBar(
            title: Text("Flutter local Storage"),
          ),
          body: LocalStorageScreen()
      ),
    );
  }
}

