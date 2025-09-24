import 'package:picassowaiter/bloc/app_bloc.dart';
import 'package:picassowaiter/bloc/question_bloc.dart';
import 'package:picassowaiter/main.dart';
import 'package:picassowaiter/model/model.dart';
import 'package:picassowaiter/screen/config.dart';
import 'package:picassowaiter/screen/draft_sale.dart';
import 'package:picassowaiter/screen/goods_info.dart';
import 'package:picassowaiter/screen/order.dart';
import 'package:picassowaiter/utils/barcode.dart';
import 'package:picassowaiter/utils/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Navigation {
  final WMModel model;

  Navigation(this.model);

  Future<void> config() {
    return Navigator.push(prefs.context(),
        MaterialPageRoute(builder: (builder) => WMConfig(model: model)));
  }



  Future<void> createDraftSale() {
    hideMenu();
    return Navigator.push(prefs.context(),
        MaterialPageRoute(builder: (builder) => WMDraftSale(model: model, draftid: '')));
  }



  Future<void> settings() {
    hideMenu();
    model.serverTextController.text = prefs.string('serveraddress');
    model.serverUserTextController.clear();
    model.serverPasswordTextController.clear();
    return Navigator.push(prefs.context(), MaterialPageRoute(builder: (builder) => WMConfig(model: model)));
  }

  void logout() {
    hideMenu();
    BlocProvider.of<QuestionBloc>(prefs.context()).add(QuestionEventRaise(model.tr('Logout?'), (){
      BlocProvider.of<QuestionBloc>(Prefs.navigatorKey.currentContext!)
          .add(QuestionEvent());
      BlocProvider.of<AppBloc>(prefs.context()).add(AppEventLoading(model.tr('Logout'), 'engine/logout.php', {}, (e, d) {

          prefs.setBool('stayloggedin', false);
          prefs.setString('sessionkey', '');
          Navigator.pushAndRemoveUntil(prefs.context(), MaterialPageRoute(builder: (builder) =>  App()), (route) => false);

      }, AppStateFinished(data: null)));
    }, null));

  }

  void hideMenu() {
    BlocProvider.of<AppAnimateBloc>(prefs.context()).add(AppAnimateEvent());
  }

  Future<String?> readBarcode() async {
    return Navigator.push(prefs.context(), MaterialPageRoute(builder: (builder) => BarcodeScannerWithOverlay()));
  }

  Future<Object?> goodsInfo(Map<String,dynamic> info) async {
    return Navigator.push(prefs.context(), MaterialPageRoute(builder: (builder) => WMGoodsInfo(info, model: model)));
  }




  Future<bool?> openWaiterTable(int table) {
    return Navigator.push(prefs.context(), MaterialPageRoute(builder: (builder) => WMOrder(model: model, table: table)));
  }
}
