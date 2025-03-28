import 'package:picassowaiter/bloc/app_bloc.dart';
import 'package:picassowaiter/screen/app.dart';
import 'package:picassowaiter/utils/prefs.dart';
import 'package:picassowaiter/utils/qty_dialog.dart';
import 'package:picassowaiter/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'draft_sale.part.dart';

class WMDraftSale extends WMApp {
  final _model = DraftSaleModel();

  WMDraftSale({super.key, required super.model, required String draftid}) {
    _model.draftId = draftid;
    if (_model.draftId.isNotEmpty) {
      openDraft();
    }
  }

  @override
  String titleText() {
    return model.tr('Draft order');
  }

  @override
  Widget body() {
    return Column(children: [
      Expanded(
          child: SingleChildScrollView(
              child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Styling.textFormField(
                      _model.scancodeTextController, model.tr('Barcode'),
                      onSubmit: searchBarcode,
                      autofocus: true,
                      focusNode: _model.scancodeFocus)),
              IconButton(
                  onPressed: () {
                    _model.scancodeTextController.clear();
                    _model.scancodeFocus.requestFocus();
                  },
                  icon: const Icon(Icons.clear_sharp)),
              IconButton(
                  onPressed: readBarcode, icon: const Icon(Icons.qr_code)),
              IconButton(
                  onPressed: addGoodsToDraft,
                  icon: const Icon(Icons.add_circle_outline_sharp))
            ],
          ),
          Divider(),
          Styling.textCenter(model.tr('List of goods')),
          BlocBuilder<AppBloc, AppState>(builder: (builder, state) {
            return Column(
              children: [
                for (int i = 0; i < _model.goods.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 40, child: Text('${i + 1}')),
                      SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Styling.text(_model.goods[i]['f_goodsname']),
                            Styling.text('${_model.goods[i]['f_price1']}')
                          ])),
                      InkWell(onTap:(){changeQty(_model.goods[i]['f_bodyid'], _model.goods[i]['f_qty'] * 1.0);}, child: SizedBox(
                          width: 50,
                          child: Styling.text('${_model.goods[i]['f_qty']}'))),
                      SizedBox(
                          width: 50,
                          child:
                              Styling.text('${_model.goods[i]['f_storeqty']}')),
                      Expanded(child: Container()),
                      IconButton(
                          onPressed: () {
                            removeGoodsAt(i);
                          },
                          icon: const Icon(Icons.highlight_remove_sharp))
                    ],
                  )
                ]
              ],
            );
          }),
        ],
      ))),
      BlocBuilder<AppBloc, AppState>(
          buildWhen: (p, c) => c is AppStateTotal,
          builder: (builder, state) {
            if (state is AppStateTotal) {
              return Row(children: [
                Styling.text(model.tr('Total')),
                Expanded(child: Container()),
                Styling.text('${state.data}')
              ]);
            }
            return Container();
          }),
      const SizedBox(height: 5)
    ]);
  }
}
