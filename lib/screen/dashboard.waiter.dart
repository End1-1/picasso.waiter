part of 'dashboard.dart';

extension WaiterDashboard on WMDashboard {
  void getDashboardWaiter() {
    BlocProvider.of<AppBloc>(prefs.context()).add(
        AppEventLoading(model.tr('Wait, please'), 'engine/waiter/init.php', {
      'version': prefs.getInt('dataversion') ?? 0,
      'date': prefs.dateMySqlText(prefs.workingDay())
    }, (e, d) {
      if (e) {
        return;
      }
      if (d['nochanges']) {
        return;
      }
      _model.halls.clear();
      _model.filteredTables.clear();
      for (final e in d['h_halls'].keys) {
        _model.halls.add(d['h_halls'][e]);
        _model.filteredTables[d['h_halls'][e]['f_id']] = [];
      }
      _model.tables.clear();
      for (final e in d['h_tables'].keys) {
        _model.tables.add(d['h_tables'][e]);
        _model.filteredTables[d['h_tables'][e]['f_hall']].add(d['h_tables'][e]);
      }
      _model.openTables.clear();
      for (final e in d['orders'].keys) {
        _model.openTables[d['orders'][e]['f_table']] = d['orders'][e];
      }

      final m = Menu();
      m.build(d);
    }, AppStateDashboard(data: _model)));
  }

  Widget bodyWaiter() {
    return BlocBuilder<AppBloc, AppState>(
        buildWhen: (p, c) => c is AppStateDashboard,
        builder: (builder, state) {
          if (state is! AppStateDashboard) {
            return Container();
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              InkWell(
                                  onTap: () {
                                    filterTables(0);
                                  },
                                  child: Styling.text(model.tr('All'))),
                              Styling.rowSpacingWidget(),
                              InkWell(
                                  onTap: () {
                                    filterTables(-1);
                                  },
                                  child: Styling.text(model.tr('My'))),
                              Styling.rowSpacingWidget(),
                              for (final f in _model.halls) ...[
                                InkWell(
                                    onTap: () {
                                      filterTables(f['f_id']);
                                    },
                                    child: Styling.text(f['f_name'])),
                                Styling.rowSpacingWidget(),
                              ]
                            ],
                          )))
                ]),
                const Divider(),
                ...[...hallWidget()]
              ],
            ),
          );
        });
  }

  void filterTables(int hallid) {
    _model.hallFilter = hallid;
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventLoading(
        model.tr('Wait'),
        '',
        {},
        (p0, p1) => null,
        AppStateDashboard(data: _model)));
  }

  List<Widget> hallWidget() {
    if (_model.hallFilter < 0) {
      return [
        Align(
            alignment: Alignment.topLeft,
            child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.start,
                runAlignment: WrapAlignment.start,
                alignment: WrapAlignment.start,
                children: tablesWidgets(-1)))
      ];
    }
    final hl = _model.hallFilter > 0
        ? _model.halls.where((element) => element['f_id'] == _model.hallFilter)
        : _model.halls;

    return [
      for (final h in hl) ...[
        Row(children: [Styling.text(h['f_name'])]),
        const Divider(),
        Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              runAlignment: WrapAlignment.start,
              alignment: WrapAlignment.start,
              children: tablesWidgets(h['f_id']),
            ))
      ]
    ];
  }

  Color tableColor(dynamic table) {
    if (_model.openTables.containsKey(table['f_id'])) {
      final o = _model.openTables[table['f_id']];
      if (o['f_precheck'] > 0) {
        return Color(0xffff9797);
      }
      return Color(0xff6fff76);
    }
    return Colors.white;
  }

  dynamic orderValue(dynamic table, String key) {
    if (_model.openTables.containsKey(table['f_id'])) {
      final o = _model.openTables[table['f_id']];
      return o[key] ?? '???';
    }
    return '';
  }

  List<dynamic> myTables() {
    final l = [];
    for (final t in _model.tables) {
      if (_model.openTables.containsKey(t['f_id'])) {
        final o = _model.openTables[t['f_id']];
        if (o['f_staff'] == prefs.getInt('userid')) {
          l.add(t);
        }
      }
    }
    return l;
  }

  List<Widget> tablesWidgets(int hall) {
    final tl = hall < 0 ? myTables() : _model.filteredTables[hall];
    return [
      for (final t in tl) ...[
        InkWell(
            onTap: () {
              model.navigation
                  .openWaiterTable(t['f_id'])
                  .then((value) => unlockTable(t['f_id']));
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                border:
                    Border.fromBorderSide(BorderSide(color: Colors.black12)),
                color: tableColor(t),
              ),
              height: 100,
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Styling.text(t['f_name']),
                  Styling.text(orderValue(t, 'f_staffname')),
                  Expanded(child: Container()),
                  Styling.text('${orderValue(t, 'f_amounttotal')}')
                ],
              ),
            ))
      ]
    ];
  }

  void unlockTable(int id) {
    BlocProvider.of<AppBloc>(prefs.context())
        .add(AppEventLoading('Wait', '/engine/waiter/order.php', {
      'action': 'unlocktable',
      'locksrc': 'mobilewaiter-${prefs.getInt('userid')}',
      'hostinfo': 'mobilewaiter-${prefs.getInt('userid')}',
      'createifempty': true,
      'current_staff': prefs.getInt('userid'),
      'table': id
    }, (e, d) {
      if (e) {
        return;
      }
    }, AppStateDashboard(data: model)));
  }
}
