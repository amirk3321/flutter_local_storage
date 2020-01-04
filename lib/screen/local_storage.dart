import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_storage/services/permission_service.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as client;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class LocalStorageScreen extends StatefulWidget {
  LocalStorageScreen({Key key}) : super(key: key);

  @override
  _LocalStorageScreenState createState() => _LocalStorageScreenState();
}

class _LocalStorageScreenState extends State<LocalStorageScreen> {
  //permission service instance
  PermissionService _permissionService = PermissionService();


  final _path = "sdcard/Local Storage";
  Directory _directoryPath;
  Directory _imageDirectory;
  Directory _docDirectory;
  List<FileSystemEntity> _localStoreImages = [];
  List<FileSystemEntity> _localStoreDocuments = [];
  String progressBar = "";
  bool _isDownloading = false;
  bool _isSwitchListView = false;
  TextEditingController _editingController = TextEditingController();

  @override
  void initState() {
    _createLocalStorageDir();
    _editingController.addListener(() {
      setState(() {});
      _editingController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _editingController.text.length,
          affinity: TextAffinity.upstream,
          isDirectional: true);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              SizedBox(
                height: 20,
              ),
              _isDownloading==false?Text("(No Data)"):Column(
                children: <Widget>[
                  CircularProgressIndicator(),
                  Text("Downloading continue.. wait for moument")
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10)
                ),
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  controller: _editingController,
                  decoration: InputDecoration(
                      hintText: "Url e.g https://example/img.jpg",
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search)),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              RaisedButton(
                onPressed: _editingController.text.isEmpty
                    ? null
                    : () {
                    _downloadFiles(url: _editingController.text);
                    print("_isDownloading $_isDownloading");
                      },
                child: Text("Download from internet"),
              ),
              SizedBox(
                height: 10,
              ),
              RaisedButton(
                child: Text("Pick documents"),
                onPressed: () async {
                    _permissionService.checkPermission();
                    final file = await FilePicker.getMultiFile(
                        type: FileType.CUSTOM, fileExtension: 'pdf');

                    _storeDocAndImgInLocalStorage(
                        file: file[0], extension: "pdf");
                },
              ),
              SizedBox(
                height: 10,
              ),
              RaisedButton(
                child: Text("Pick image"),
                onPressed: () async {
                    _permissionService.checkPermission();
                    final file =
                    await FilePicker.getMultiFile(type: FileType.IMAGE);

                    _storeDocAndImgInLocalStorage(
                        file: file[0], extension: "png");
                },
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    child: Text("Read Images"),
                    onPressed: () {
                        _loadImagesFromStorage();
                        setState(() {
                          _isSwitchListView=false;
                        });
                    },
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  RaisedButton(
                    child: Text("Read Docuemnts"),
                    onPressed: () {
                        _loadDocumetsFromStorage();
                        setState(() {
                          _isSwitchListView=true;
                        });
                    },
                  ),
                ],
              ),
              _localStoreImages.isEmpty && _localStoreDocuments.isEmpty
                  ? Text("")
                  : Expanded(
                      child: ListView.builder(
                          itemCount: _isSwitchListView==false?_localStoreImages.length:_localStoreDocuments.length,
                          itemBuilder: (context, index) {
                            // _localStoreDocuments[index].path
                            if (_isSwitchListView==false){
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(_localStoreImages[index],fit: BoxFit.cover,),
                              );
                            }else
                            return InkWell(
                              onTap: () {
                                OpenFile.open(_localStoreDocuments[index].path);
                              },
                              child: _listViewItemPdf(name:getNameOnly( _localStoreDocuments[index].path),size:File(_localStoreDocuments[index].path).readAsBytesSync().length),
                            );
                          }),
                    )
            ],
          ),
        ),
      ),
    );
  }

  Widget  _listViewItemPdf({String name,int size}) {
    return Container(
      padding:EdgeInsets.all(5),
      margin: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black12.withOpacity(.3),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            child: Image.asset('assets/pdficon.png',fit: BoxFit.cover,),
          ),
          SizedBox(width: 10,),
          Text(name),
          Spacer(),
          Text("size:$size kb")
        ],
      ),
    );
  }

  //create Directories if not exit
  _createLocalStorageDir() async {
    final dir = _createDirectory(path: "$_path");
    final imagePath = "$_path/images";
    final documentPath = "$_path/documents";
    _imageDirectory = _createDirectory(path: "$imagePath");
    _docDirectory = _createDirectory(path: "$documentPath");

    if (!(await dir.exists())) {
      dir.create();
    }
  }

  //network operation download images or documents from internet
  _downloadFiles({String url}) async {
    final httpClient = client.Client();
    setState(() {
      _isDownloading = true;
    });
    final response = await httpClient.get(url);
    if (response.statusCode == 200) {
      print("success");
      final extension = _filterUrlGetExtension(url);
      setState(() {
        progressBar =
        "${((response.contentLength / response.bodyBytes.length) * 100).toStringAsFixed(2)} %";
        print("progressBar $progressBar");
        _isDownloading = false;
      });
      //store download image in local storage
      _storeDocAndImgInLocalStorage(
          extension: extension,
          bytesFile: response.bodyBytes,
          fileNameUrl: url);
    } else {
      print("failure");
      setState(() {
        _isDownloading = false;
      });
    }
  }


  //save documnets and images in local storage
  //path : /sdcard/local storage/{images or documents}
  _storeDocAndImgInLocalStorage(
      {File file,
        List<int> bytesFile,
        String extension,
        String fileNameUrl}) async {
    if (extension.contains("png") ||
        extension.contains("jpg") ||
        extension.contains("gif") ||
        extension.contains("tif")) {
      //path Image dir inside Local Storage parent dir

      //if dir not exist then create
      if (!(await _imageDirectory.exists())) _imageDirectory.create();
      //if file not null then save locally in documents dir
      if (file != null) {
        try {
          //covert file into bytes
          final bytes = await file.readAsBytes();
          //bytes into image format
          final image = img.decodeImage(bytes);
          //save image
          File("${_imageDirectory.path}/${getNameOnly(file.path)}")
            ..writeAsBytesSync(img.encodeJpg(image, quality: 95));
          //notify message optional
          print("file store byte Lenth is ${bytes.length}");
        } catch (e) {
          print("errorImage is : ${e.toString()}");
        }
      } else {
        final image = img.decodeImage(bytesFile);
        File("${_imageDirectory.path}/${getNameOnly(fileNameUrl)}")
          ..writeAsBytesSync(img.encodeJpg(image, quality: 95));
        print("file store byte Lenth is ${bytesFile.length}");
      }
    } else {
      if (!(await _docDirectory.exists())) _docDirectory.create();
      //if file not null then save locally in documents dir
      if (file != null) {
        try {
          //covert file into bytes
          final bytes = await file.readAsBytes();
          File("${_docDirectory.path}/${getNameOnly(file.path)}")
            ..writeAsBytesSync(bytes);
          //notify message optional
          print("file store byte Lenth is ${bytes.length}");
        } catch (e) {
          print("errorDocument is :${e.toString()}");
        }
      } else {
        File("${_docDirectory.path}/${getNameOnly(fileNameUrl)}")
          ..writeAsBytesSync(bytesFile);
        print("file store byte Lenth is ${bytesFile.length}");
      }
    }
  }

  //createDirectory (Parameter : path) return Directory object
  Directory _createDirectory({String path}) {
    if (_directoryPath != null) _directoryPath = null;
    return _directoryPath = Directory(path);
  }

  //get file name eg : xyz.png or xyz.pdf
  String getNameOnly(String path) {
    return path.split('/').last;
  }

  //filter Url get extension of eg : pdf or png
  String _filterUrlGetExtension(String path) {
    return path.split('/').last.split('.').last;
  }

  //load all images from /sdcard/local storage/images
  Future<void> _loadImagesFromStorage() async {
    List<FileSystemEntity> _imageFile =
    _imageDirectory.listSync(recursive: true, followLinks: false);
    _localStoreDocuments.clear();
    _localStoreDocuments = List<FileSystemEntity>();
    for (FileSystemEntity entity in _imageFile) {
      _localStoreImages.add(entity);
    }
    setState(() {
      _localStoreDocuments = null;
    });
  }

  //load all documents form /sdcard/local storage/documents
  Future<void> _loadDocumetsFromStorage() {
    List<FileSystemEntity> _documentsFile =
    _docDirectory.listSync(recursive: true, followLinks: false);
    _localStoreImages.clear();
    _localStoreDocuments = List<FileSystemEntity>();
    for (FileSystemEntity entity in _documentsFile) {
      _localStoreDocuments.add(entity);
    }
    setState(() {});
  }
}
