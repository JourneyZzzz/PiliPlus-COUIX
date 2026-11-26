import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/scroll_header_inset.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends CommonPageState<HomePage>
    with AutomaticKeepAliveClientMixin {
  late ColorScheme _colorScheme;
  final _homeController = Get.putOrFind(HomeController.new);
  final _mainController = Get.find<MainController>();

  @override
  bool get needsCorrection => _homeController.hideTopBar;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = ColorScheme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget tabBar;
    if (_homeController.tabs.length > 1) {
      tabBar = Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          height: 42,
          width: double.infinity,
          child: TabBar(
            controller: _homeController.tabController,
            tabs: _homeController.tabs.map((e) => Tab(text: e.label)).toList(),
            isScrollable: true,
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            splashBorderRadius: Style.mdRadius,
            tabAlignment: TabAlignment.center,
            onTap: (_) {
              feedBack();
              if (!_homeController.tabController.indexIsChanging) {
                _homeController.animateToTop();
              }
            },
          ),
        ),
      );
    } else {
      tabBar = const SizedBox(height: 6);
    }
    final body = onBuild(tabBarView(
      controller: _homeController.tabController,
      children: _homeController.tabs.map((e) => e.page).toList(),
    ));
    final hasToolbar = !_mainController.useSideBar && MediaQuery.isPortraitOf(context);
    final toolbar = hasToolbar ? customAppBar() : null;
    final dark = _colorScheme.brightness == Brightness.dark;

    Widget layout(double toolbarHeight) {
      final height = toolbarHeight + (_homeController.tabs.length > 1 ? 46 : 6);
      return Stack(
        fit: StackFit.expand,
        children: [
          ScrollHeaderInset(height: height, child: body),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _colorScheme.surfaceContainerLow.withValues(alpha: dark ? .78 : .72),
                        _colorScheme.surface.withValues(alpha: dark ? .68 : .60),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (toolbar != null)
                        ClipRect(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            heightFactor: toolbarHeight / Style.topBarHeight,
                            child: toolbar,
                          ),
                        ),
                      tabBar,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!hasToolbar) return layout(0);
    if (_homeController.hideTopBar) {
      if (_mainController.barOffset case final offset?) {
        return Obx(() => layout(Style.topBarHeight - offset.value));
      }
      if (_homeController.showTopBar case final visible?) {
        return Obx(() => TweenAnimationBuilder<double>(
          tween: Tween(end: visible.value ? Style.topBarHeight : 0.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubicEmphasized,
          builder: (context, height, _) => layout(height),
        ));
      }
    }
    return layout(Style.topBarHeight);
  }

  Widget customAppBar() {
    const padding = EdgeInsets.fromLTRB(14, 6, 14, 0);
    final child = Row(
      children: [
        searchBar(),
        const SizedBox(width: 6),
        msgBadge(_mainController, toolbarColor: _colorScheme.surface.withValues(alpha: .68)),
        Obx(() => IconButton(
          tooltip: '我的',
          onPressed: _mainController.toMinePage,
          style: _toolbarStyle(_colorScheme.surface.withValues(alpha: .68)),
          icon: Icon(_mainController.accountService.isLogin.value && MineController.anonymity.value
              ? MdiIcons.incognito
              : Icons.person_outline_rounded),
        )),
      ],
    );
    return Container(
      height: Style.topBarHeight,
      padding: padding,
      child: child,
    );
  }

  Widget searchBar() {
    const borderRadius = BorderRadius.all(Radius.circular(25));
    return Expanded(
      child: SizedBox(
        height: 44,
        child: Material(
          borderRadius: borderRadius,
          color: _colorScheme.surface.withValues(alpha: .68),
          child: InkWell(
            borderRadius: borderRadius,
            splashColor: _colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
            onTap: () => Get.toNamed(
              '/search',
              parameters: _homeController.enableSearchWord
                  ? {'hintText': _homeController.defaultSearch.value}
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_outlined,
                  color: _colorScheme.onSecondaryContainer,
                  semanticLabel: '搜索',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => Text(
                      _homeController.defaultSearch.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _colorScheme.outline),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget userAvatar({
  required ColorScheme colorScheme,
  required MainController mainController,
}) {
  return Semantics(
    label: "我的",
    child: Obx(
      () {
        if (mainController.accountService.isLogin.value) {
          return Stack(
            clipBehavior: .none,
            children: [
              NetworkImgLayer(
                type: .avatar,
                width: 34,
                height: 34,
                src: mainController.accountService.face.value,
              ),
              Positioned.fill(
                child: Material(
                  type: .transparency,
                  child: InkWell(
                    onTap: mainController.toMinePage,
                    splashColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    customBorder: const CircleBorder(),
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Obx(
                  () => MineController.anonymity.value
                      ? IgnorePointer(
                          child: Container(
                            padding: const .all(2),
                            decoration: BoxDecoration(
                              shape: .circle,
                              color: colorScheme.secondaryContainer,
                            ),
                            child: Icon(
                              size: 14,
                              MdiIcons.incognito,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          );
        }
        return SizedBox(
          width: 38,
          height: 38,
          child: IconButton(
            tooltip: '点击登录',
            style: IconButton.styleFrom(
              padding: .zero,
              backgroundColor: colorScheme.onInverseSurface,
            ),
            onPressed: mainController.toMinePage,
            icon: Icon(
              Icons.person_rounded,
              size: 22,
              color: colorScheme.primary,
            ),
          ),
        );
      },
    ),
  );
}

ButtonStyle _toolbarStyle(Color surface) => IconButton.styleFrom(
  backgroundColor: surface,
  fixedSize: const Size.square(40),
  iconSize: 22,
  padding: EdgeInsets.zero,
  shape: const CircleBorder(),
);

Widget msgBadge(MainController mainController, {Color? toolbarColor}) {
  return Obx(() {
    final loggedIn = mainController.accountService.isLogin.value;
    final count = mainController.msgUnReadCount.value;
    final isNumBadge = mainController.msgBadgeMode == .number;
    return IconButton(
      tooltip: '消息',
      style: toolbarColor == null ? null : _toolbarStyle(toolbarColor),
      onPressed: () {
        if (!loggedIn) {
          Get.toNamed('/loginPage');
          return;
        }
        mainController
          ..clearUnreadMsg()
          ..lastCheckUnreadAt = DateTime.now().millisecondsSinceEpoch;
        Get.toNamed('/whisper');
      },
      icon: Badge(
        isLabelVisible: loggedIn && mainController.msgBadgeMode != .hidden && count != null,
        alignment: isNumBadge
            ? const Alignment(0.0, -0.85)
            : const Alignment(1.0, -0.85),
        label: isNumBadge && count != null ? Text(count) : null,
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  });
}
