
import 'package:permission_handler/permission_handler.dart';

class PermissionService{
  PermissionHandler _permissionHandler=PermissionHandler();
  Future<bool> _isOpenSetting()async =>
    await _permissionHandler.openAppSettings();

  Future<bool> isShowRationale()async =>
      await _permissionHandler.shouldShowRequestPermissionRationale(PermissionGroup.storage);

  Future<PermissionStatus> checkPermission() async {
    PermissionStatus permissionStatus= await _permissionHandler.checkPermissionStatus(PermissionGroup.storage);

    if (permissionStatus==PermissionStatus.denied){
      print("permission Denined check permission");
        var permissionCheck=await _requestPermissionForStorage();
        switch(permissionCheck[PermissionGroup.storage]){
          case PermissionStatus.granted :
            print("permission Granted");
            break;
          case PermissionStatus.denied :{
            print("permission denied");
            break;
          }
          case PermissionStatus.disabled :
            print("permission disabled");
            break;
          case PermissionStatus.restricted :
            print("permission restricted");
            break;
        }
        return permissionStatus;
    }else if (permissionStatus== PermissionStatus.granted)
      return permissionStatus;
  }
  Future<Map<PermissionGroup, PermissionStatus>> _requestPermissionForStorage() async =>
    await _permissionHandler.requestPermissions([PermissionGroup.storage]);



}