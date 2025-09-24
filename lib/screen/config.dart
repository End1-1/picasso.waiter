import 'package:picassowaiter/utils/prefs.dart';
import 'package:picassowaiter/utils/styles.dart';
import 'package:flutter/material.dart';

import 'app.dart';

class WMConfig extends WMApp {
  WMConfig({super.key, required super.model});

  @override
  Widget body() {
    return SingleChildScrollView(child:  Column(children: [
      Styling.columnSpacingWidget(),
      Row(
        children: [
          Expanded(
              child: Styling.textFormField(
                  model.serverTextController, model.tr('Server address'))),
        ],
      ),
      Styling.columnSpacingWidget(),
      Row(children: [
        Expanded(
            child: Styling.textFormField(
                model.serverUserTextController, model.tr('Server user')))
      ]),
      Styling.columnSpacingWidget(),
      Row(children: [
        Expanded(
            child: Styling.textFormField(model.serverPasswordTextController,
                model.tr('Server password')))
      ]),
      Styling.columnSpacingWidget(),
      Row(children: [Expanded(child:  _HttpRadioGroup())]),
      Styling.columnSpacingWidget(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Styling.textButton(model.registerOnServer, model.tr('Register on server'))
      ]),
      Row(children: [
        Expanded(child: Styling.textCenter(prefs.string('appversion')))
      ],),
      Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Styling.textButton(model.downloadLatestVersion, model.tr('Download latest version'))
          ]
      ),
    ]));
  }
}

class _HttpRadioGroup extends StatefulWidget {


  const _HttpRadioGroup({
    super.key
  });

  @override
  State<_HttpRadioGroup> createState() => __HttpRadioGroupState();
}

class __HttpRadioGroupState extends State<_HttpRadioGroup> {

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
    Expanded(
    child:  RadioListTile<bool>(
          title: const Text('http'),
          value: false,
          groupValue: prefs.getBool('https') ?? false,
          onChanged: (value) {
            setState(()  {});
            prefs.setBool('https', false);
          },
        )),
    Expanded(
    child:  RadioListTile<bool>(
          title: const Text('https'),
          value: true,
          groupValue: prefs.getBool('https') ?? false,
          onChanged: (value) {
            setState(() {});
            prefs.setBool('https', true);
          },
        )),
      ],
    );
  }
}
