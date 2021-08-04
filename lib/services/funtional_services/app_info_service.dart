

import 'package:FSOUNotes/app/app.logger.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:package_info/package_info.dart';

Logger log = getLogger("AdmobService");
class AppInfoService{
  PackageInfo _packageInfo;

  getPackageInfo() async {
    if(kIsWeb){return null;}
    if(_packageInfo == null)_packageInfo = await PackageInfo.fromPlatform();
    return _packageInfo;
  }
  
}