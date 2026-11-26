import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('recommendation cards flow into the shorter column', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cards = [
      for (final (i, title) in [
        '短标题',
        '推荐视频的长标题，需要显示成两行以测试卡片真实高度',
        '下一张',
      ].indexed)
        RcmdVideoItemAppModel.fromJson({
          'param': '${i + 1}',
          'card_goto': 'av',
          'cover_left_text_1': '152',
          'cover_left_text_2': '8',
          'title': title,
        }),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverMasonryGrid.extent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childCount: cards.length,
                itemBuilder: (_, i) => VideoCardV(videoItem: cards[i]),
              ),
            ],
          ),
        ),
      ),
    );
    final tiles = find.byType(VideoCardV);
    final first = tester.getRect(tiles.at(0));
    final second = tester.getRect(tiles.at(1));
    final third = tester.getRect(tiles.at(2));
    expect(first.top, second.top);
    expect(first.height, lessThan(second.height));
    expect(third.left, first.left);
    expect(third.top, closeTo(first.bottom + 8, 0.01));
    expect(tester.takeException(), isNull);
  });
}
