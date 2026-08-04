import 'package:flclashx/enum/enum.dart';
import 'package:flclashx/models/models.dart';
import 'package:flclashx/views/views.dart';
import 'package:flutter/material.dart';

class Navigation {

  factory Navigation() {
    _instance ??= Navigation._internal();
    return _instance!;
  }

  Navigation._internal();
  static Navigation? _instance;

  List<NavigationItem> getItems({
    bool openLogs = false,
    bool hasProxies = false,
  }) => [
      const NavigationItem(
        icon: Icon(Icons.shield_rounded),
        label: PageLabel.praxaHome,
        view: PraxaHomeView(
          key: GlobalObjectKey(PageLabel.praxaHome),
        ),
        modes: [NavigationItemMode.mobile, NavigationItemMode.desktop],
      ),
      const NavigationItem(
        icon: Icon(Icons.public_rounded),
        label: PageLabel.praxaServers,
        view: PraxaServersView(
          key: GlobalObjectKey(PageLabel.praxaServers),
        ),
        modes: [NavigationItemMode.mobile, NavigationItemMode.desktop],
      ),
      const NavigationItem(
        icon: Icon(Icons.account_circle_rounded),
        label: PageLabel.profiles,
        view: ProfilesView(
          key: GlobalObjectKey(PageLabel.profiles),
        ),
      ),
      const NavigationItem(
        icon: Icon(Icons.settings_rounded),
        label: PageLabel.tools,
        view: ToolsView(
          key: GlobalObjectKey(PageLabel.tools),
        ),
        modes: [NavigationItemMode.desktop, NavigationItemMode.mobile],
      ),
    ];
}

final navigation = Navigation();
