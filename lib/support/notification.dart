import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:studentsocial/models/object/schedule.dart';
import 'package:studentsocial/support/date.dart';

class Notification {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  var initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_logo');

//  var initializationSettingsIOS = IOSInitializationSettings(
//      onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  var initializationSettingsIOS = IOSInitializationSettings();
  var initializationSettings;
  DateSupport _dateSupport;
  String msv;

  Notification() {
    init();
    //TODO('nhảy đến đúng ngày khi bấm vào notifi')
  }

  void init() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
    _dateSupport = DateSupport();
  }

  void initSchedulesNotification(
      Map<String, List<Schedule>> entriesOfDay, String msv) async {
    this.msv = msv;
    // ban đầu sẽ hủy toàn bộ notifi đã lên lịch từ trước để lên lịch lại từ đầu. đảm bảo các notifi sẽ luôn đc cập nhật chính xác trong mỗi lần mở app hay có thay đổi lịch.
    cancelAllNotifi();
    DateTime scheduledNotificationDateTime, dateTimeForGetData;
    List<Schedule> entries;
    //nếu mở app vào lúc > 19:30 thì sẽ không thông báo ngày hôm nay nữa
    int i = 0;
    if(_dateSupport.getHour() >= 19){
      if(_dateSupport.getHour()==19){
        if(_dateSupport.getMinute() >=30){
          i = 1;
        }
      }else{
        i = 1;
      }
    }
    for (; i < 14; i++) {
      //thông báo liên tiếp 2 tuần tiếp theo
      scheduledNotificationDateTime = _dateSupport.getDate(i);
      dateTimeForGetData = _dateSupport.getDate(i +
          1); // ví dụ ngày hôm nay thì phải lấy lịch của ngày hôm sau để thông báo
//      print(_dateSupport.format(scheduledNotificationDateTime));
      entries = entriesOfDay[_dateSupport.format(dateTimeForGetData)];
//      print(entries);
      scheduleOneNotifi(
          scheduledNotificationDateTime, dateTimeForGetData, i,entries);
    }
    print('set schedule notification done !');
  }

  void cancelAllNotifi() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  void scheduleOneNotifi(DateTime scheduledNotificationDateTime,
      DateTime dateTimeForGetData, int id, List<Schedule> entriesOfDay) async {
    String body = getBody(entriesOfDay);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'student_notifi_id',
        'student_notifi_name',
        'student_notifi_description',
        importance: Importance.Max,
        priority: Priority.High,
        style: AndroidNotificationStyle.BigText,
        autoCancel: false,
        styleInformation: BigTextStyleInformation(body),
        icon: '@mipmap/ic_logo',
        largeIcon: '@mipmap/ic_logo');

    var iOSPlatformChannelSpecifics = IOSNotificationDetails();

    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
        id,
        getTitle(dateTimeForGetData, entriesOfDay),
        body,
        scheduledNotificationDateTime,
        platformChannelSpecifics);
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      print('notification payload: ' + payload);
    }
//    await Navigator.push(
//      context,
//      new MaterialPageRoute(builder: (context) => new SecondScreen(payload)),
//    );
  }

  String getTitle(DateTime dateTimeForGetData, List<Schedule> entriesOfDay) {
    if (entriesOfDay == null || entriesOfDay.isEmpty) {
      return 'Lịch cá nhân ngày ${dateTimeForGetData.day}-${dateTimeForGetData.month}-${dateTimeForGetData.year}';
    } else {
      return '${entriesOfDay.length} Lịch cá nhân ngày ${dateTimeForGetData.day}-${dateTimeForGetData.month}-${dateTimeForGetData.year}';
    }
  }

  String getBody(List<Schedule> entriesOfDay) {
    if (entriesOfDay == null || entriesOfDay.isEmpty) {
      return 'Ngày mai bạn rảnh ^_^';
    }
    String msg = '';
    for (int i = 0; i < entriesOfDay.length; i++) {
      msg += getContentByEntri(entriesOfDay[i]);
      if (i != entriesOfDay.length - 1) msg += '\n•\n';
    }
    return msg;
  }

  String getContentByEntri(Schedule entri) {
    if (entri.LoaiLich == 'LichHoc') {
      return 'Môn học: ${entri.TenMon}\nThời gian: ${entri.ThoiGian} ${_dateSupport.getThoiGian(entri.ThoiGian,msv)}\nĐịa điểm: ${entri.DiaDiem}\nGiảng viên: ${entri.GiaoVien}';
    } else if (entri.LoaiLich == 'LichThi') {
      return 'Môn thi: ${entri.TenMon}\nSố báo danh: ${entri.SoBaoDanh}\nThời gian: ${entri.ThoiGian}\nĐịa điểm: ${entri.DiaDiem}\nHình thức: ${entri.HinhThuc}';
    } else if (entri.LoaiLich == 'Note') {
      return 'Tiêu đề: ${entri.MaMon}\nNội dung: ${entri.ThoiGian}';
    }
    return 'unknown';
  }
}
