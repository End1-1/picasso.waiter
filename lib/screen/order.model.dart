part of 'order.dart';

class AppLoadOpenOrder extends AppEventLoading {
  AppLoadOpenOrder(
      super.text, super.route, super.data, super.callback, super.state);
}

class AppLoadDishes extends AppEventLoading {
  AppLoadDishes() : super('', '', {}, null, AppStateDishes());
}

class AppOpenOrderState extends AppStateFinished {
  AppOpenOrderState({required super.data});
}

class AppStateDishes extends AppStateFinished {
  AppStateDishes() : super(data: null);
}

class OrderModel {
  static const show_part1 = 1;
  static const show_dishes = 2;

  late final int table;
  var tableName = '??';
  var locked = false;
  var showMenu = false;
  final menu = Menu();
  var currentMenuName = '';
  var currentPart1Filter = '';
  var currentPart2Filter = '';
  var showMode = show_part1;
  var order = <String, dynamic>{};
  final dishes = [];

  OrderModel(int t) {
    table = t;
    refresh();
    if (menu.menu.isNotEmpty) {
      currentMenuName = menu.menu.entries.first.key;
    }
  }

  void refresh() {
    BlocProvider.of<AppBloc>(prefs.context())
        .add(AppLoadOpenOrder('Wait', '/engine/waiter/order.php', {
      'action': 'open',
      'locksrc': 'mobilewaiter-${prefs.getInt('userid')}',
      'hostinfo': 'mobilewaiter-${prefs.getInt('userid')}',
      'createifempty': true,
      'current_staff': prefs.getInt('userid'),
      'table': table
    }, (e, d) {
      locked = e;
      if (e) {
        return;
      }
      tableName = d['table']['f_name'];
      order = d['header'];
      dishes.addAll(d['dishes']);
      BlocProvider.of<AppBloc>(prefs.context()).add(AppLoadDishes());
    }, AppOpenOrderState(data: null)));
  }
}

extension WMEOrder on WMOrder {
  void showDishMenu() {
    if (_model.showMenu) {
      BlocProvider.of<AppAnimateBloc>(prefs.context())
          .add(AppAnimateEventHideMenu());
    } else {
      BlocProvider.of<AppAnimateBloc>(prefs.context())
          .add(AppAnimateEventShowMenu());
    }
    _model.showMenu = !_model.showMenu;
  }

  void printService() {
    BlocProvider.of<AppBloc>(prefs.context())
        .add(AppLoadOpenOrder('Wait', '/engine/waiter/order.php', {
      'action': 'order',
      'order': {'action': 'printservice', 'id': _model.order['f_id']}
    }, (e, d) {
      if (e) {
        return;
      }
      Navigator.pop(prefs.context());
    }, AppOpenOrderState(data: null)));
  }

  void topLevel() {
    _model.showMenu = true;
    _model.showMode = OrderModel.show_part1;
    BlocProvider.of<AppAnimateBloc>(prefs.context())
        .add(AppAnimateEventShowMenu());
  }

  void filterDishes(String filter) {
    _model.currentPart2Filter = filter;
    _model.showMode = OrderModel.show_dishes;
    _model.showMenu = true;
    BlocProvider.of<AppAnimateBloc>(prefs.context())
        .add(AppAnimateEventShowMenu());
  }

  void addDish(dynamic e) {
    if (_model.locked) {
      BlocProvider.of<AppBloc>(prefs.context())
          .add(AppEventError(model.tr('View only')));
      return;
    }
    final d = <String, dynamic>{};
    d['action'] = 'adddish';
    d['header'] = _model.order['f_id'];
    d['dish'] = e['f_dish'];
    d['price'] = e['f_price'];
    d['f_working_day'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
    d['service_factor'] = _model.order['f_servicefactor'];
    d['discount'] = _model.order['f_discountfactor'];
    d['store'] = e['f_store'];
    d['print1'] = e['f_print1'];
    d['print2'] = e['f_print2'];
    d['adgcode'] = e['f_adgcode'];
    d['canservice'] = e['f_service'];
    d['candiscount'] = e['f_discount'];
    d['emarks'] = (e['f_emarks'] ?? '').isEmpty ?  null : e['f_emarks'];
    BlocProvider.of<AppBloc>(prefs.context())
        .add(AppLoadOpenOrder('Wait', '/engine/waiter/order.php', d, (err, d) {
      if (err) {
        return;
      }
      final newdish = Map.from(e);
      newdish['f_id'] = d['obody']['f_id'];
      newdish['f_qty2'] = 0.0;
      _model.dishes.add(newdish);
      BlocProvider.of<AppBloc>(prefs.context()).add(AppLoadDishes());
      _scrollController.animateTo(100000,
          duration: const Duration(milliseconds: 100), curve: Curves.ease);
    }, AppOpenOrderState(data: null)));
  }

  void removeDish(String id) {
    if (_model.locked) {
      BlocProvider.of<AppBloc>(prefs.context())
          .add(AppEventError(model.tr('View only')));
      return;
    }
    final e = _model.dishes.firstWhere((element) => element['f_id'] == id);
    if (e['f_qty2'] > 0) {
      BlocProvider.of<AppBloc>(prefs.context())
          .add(AppEventError(model.tr('Call to manager')));
      return;
    }
    final d = <String, dynamic>{};
    d['action'] = 'removedish';
    d['id'] = id;
    BlocProvider.of<AppBloc>(prefs.context())
        .add(AppLoadOpenOrder('Wait', '/engine/waiter/order.php', d, (err, d) {
      if (err) {
        return;
      }
      _model.dishes.removeWhere((element) => element['f_id'] == id);
      BlocProvider.of<AppBloc>(prefs.context()).add(AppLoadDishes());
    }, AppOpenOrderState(data: null)));
  }

  void changeQty(dynamic ddd) {
    if (ddd['f_qty2'] > 0) {
      return;
    }
    final _controller = TextEditingController();
    var alert = AlertDialog(
      title: Text(ddd['f_name']),
      content: TextField(
        style: const TextStyle(decoration: TextDecoration.none),
        maxLines: 1,
        keyboardType: TextInputType.number,
        autofocus: true,
        enabled: true,
        onSubmitted: (String text) {
          var qty = double.tryParse(text) ?? 1;
          Navigator.pop(prefs.context(), qty);
        },
        controller: _controller,
        decoration: InputDecoration(
          errorStyle: const TextStyle(color: Colors.redAccent),
          border: UnderlineInputBorder(
            borderSide: const BorderSide(
              color: Color.fromRGBO(40, 40, 40, 1.0),
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: const BorderSide(
              color: Color.fromRGBO(40, 40, 40, 1.0),
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: const BorderSide(
              color: Color.fromRGBO(40, 40, 40, 1.0),
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          prefixIcon: const Icon(
            Icons.playlist_add,
            size: 18.0,
          ),
        ),
      ),
    );

    showDialog(
      context: prefs.context(),
      builder: (context) {
        return alert;
      },
    ).then((value) {
      if (value != null && value > 0) {
        final d = <String, dynamic>{};
        d['action'] = 'modifydish';
        d['id'] = ddd['f_id'];
        d['emarks'] = ddd['f_emarks'];
        d['comment'] = ddd['f_comment'];
        d['emarks'] = '';
        d['qty1'] = value;
        BlocProvider.of<AppBloc>(prefs.context()).add(
            AppLoadOpenOrder('Wait', '/engine/waiter/order.php', d, (err, dd) {
          if (err) {
            return;
          }
          final dish = _model.dishes
              .firstWhere((element) => element['f_id'] == ddd['f_id']);
          dish['f_qty1'] = value;
          BlocProvider.of<AppBloc>(prefs.context()).add(AppLoadDishes());
        }, AppOpenOrderState(data: null)));
      }
    });
  }

  void changeQty1(dynamic e) {
    if (e['f_qty2'] > 0) {
      return;
    }
    final d = <String, dynamic>{};
    final qty = e['f_qty1'] + 1;
    d['action'] = 'modifydish';
    d['id'] = e['f_id'];
    d['emarks'] = e['f_emarks'];
    d['comment'] = e['f_comment'];
    d['emarks'] = '';
    d['qty1'] = qty;
    BlocProvider.of<AppBloc>(prefs.context())
        .add(AppLoadOpenOrder('Wait', '/engine/waiter/order.php', d, (err, d) {
      if (err) {
        return;
      }
      final dish =
          _model.dishes.firstWhere((element) => element['f_id'] == e['f_id']);
      dish['f_qty1'] = qty;
      BlocProvider.of<AppBloc>(prefs.context()).add(AppLoadDishes());
    }, AppOpenOrderState(data: null)));
  }

  void _readQr() {
    Navigator.push(
        prefs.context(),
        MaterialPageRoute(
            builder: (bulilder) => BarcodeScannerWithOverlay())).then((v) {
      if (v != null) {
        var barcode = '';
        if (v.length == 13 || v.length == 8) {
          barcode = v;
        } else if (v.length > 28) {
          if (v.substring(0, 6) == '000000') {
            barcode = v.substring(3, 11);
          } else if (v.substring(0, 3) == '010') {
            if (v.substring(0, 8) == '01000000') {
              barcode = v.substring(8, 16);
            } else {
              barcode = v.substring(3, 16);
            }
          }
        }
        if (barcode.isEmpty) {
          if (kDebugMode) {
            print('wrong barcode 1, $v');
          }
          BlocProvider.of<AppBloc>(prefs.context())
              .add(AppEventError(locale().wrongBarcode));
          return;
        }

        final dish =
            _model.menu.firstDishOfBarcode(_model.currentMenuName, barcode);
        if (dish == null) {
          if (kDebugMode) {
            print('wrong barcode 2, $v $barcode');
          }
          BlocProvider.of<AppBloc>(prefs.context())
              .add(AppEventError(locale().wrongBarcode));
          return;
        }
        HttpQuery('engine/picasso.waiter/').request(
            {'class': 'waiter', 'method': 'checkQr', 'qr': v}).then((reply) {
          if (reply['status'] == 1) {
            dish['f_emarks'] = v;
            addDish(dish);
          } else {
            BlocProvider.of<AppBloc>(prefs.context())
                .add(AppEventError(reply['data']));
          }
        });
      }
    });
  }
}
