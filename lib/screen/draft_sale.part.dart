part of 'draft_sale.dart';

class DraftSaleModel {
  final scancodeTextController = TextEditingController();
  final scancodeFocus = FocusNode();
  var draftId = '';
  List<Map<String, dynamic>> goods = [];
}

class AppStateSearchBarcode extends AppStateFinished {
  AppStateSearchBarcode({required super.data});
}

class AppStateTotal extends AppStateFinished {
  AppStateTotal({required super.data});
}

class AppEventSearchBarcode extends AppEventLoading {
  AppEventSearchBarcode(
      super.text, super.route, super.data, super.callback, super.state);
}

extension EDraftSale on WMDraftSale {
  void searchBarcode(String b) {
    if (b.isEmpty) {
      return;
    }
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventLoading(
        model.tr('Add goods'), 'engine/shop/add-goods-to-draft.php', {
      'barcode': b,
      'store': Prefs.config['store'] ?? 0,
      'id': _model.draftId
    }, (e, d) {
      _model.scancodeTextController.clear();
      _model.draftId = d['f_draftid'];
      _model.goods.add(d..addAll(<String, dynamic>{'f_qty': 0}));
    }, AppStateSearchBarcode(data: null)));
  }

  void readBarcode() {
    model.navigation.readBarcode().then((value) {
      if (value != null) {
        _model.scancodeTextController.text = value;
        searchBarcode(_model.scancodeTextController.text);
      }
    });
  }

  void addGoodsToDraft() async {
    searchBarcode(_model.scancodeTextController.text);
  }

  void removeGoodsAt(int i) {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventLoading(
        model.tr('Remove goods'),
        'engine/shop/remove-goods-from-draft.php',
        {'bodyid': _model.goods[i]['f_bodyid'], 'id': _model.draftId}, (e, d) {
      _model.goods.removeAt(i);
      countTotal();
    }, AppStateSearchBarcode(data: null)));
  }

  void openDraft() async {
    BlocProvider.of<AppBloc>(prefs.context()).add(
        AppEventLoading(model.tr('Opening'), 'engine/shop/open-draft.php', {
      'id': _model.draftId,
    }, (e, d) {
      _model.goods.clear();
      _model.draftId = d['ds']['f_id'];
      _model.goods.addAll(List<Map<String, dynamic>>.from(d['goods']));
      countTotal();
    }, AppStateSearchBarcode(data: null)));
  }

  void changeQty(String bodyid, double qty) {
    QtyDialog().getQty().then((value) {
      if (value == null) {
        return;
      }
      BlocProvider.of<AppBloc>(prefs.context()).add(AppEventLoading(
          model.tr('Add goods'),
          'engine/shop/update-goods-in-draft.php',
          {'f_qty': value, 'bodyid': bodyid, 'id': _model.draftId}, (e, d) {
        for (int i = 0; i < _model.goods.length; i++) {
          var a = _model.goods[i];
          if (a['f_bodyid'] == bodyid) {
            a['f_qty'] = value;
            _model.goods[i] = a;
            break;
          }
        }
        countTotal();
      }, AppStateSearchBarcode(data: null)));
    });
  }

  void countTotal() async {
    var total = 0.0;
    for (final e in _model.goods) {
      total += e['f_qty'] * e['f_price1'];
    }
    BlocProvider.of<AppBloc>(prefs.context()).emit(AppStateTotal(data: total));
  }
}
