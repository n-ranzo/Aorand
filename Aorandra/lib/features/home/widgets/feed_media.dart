import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'feed_video_player.dart';

class FeedMedia extends StatelessWidget {
  final List<dynamic> mediaList;

  const FeedMedia({
    super.key,
    required this.mediaList,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width / (4 / 5);

    final pageController = PageController();
    final currentPage = ValueNotifier<int>(0);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [

          /// MEDIA VIEW
          PageView.builder(
            controller: pageController,
            itemCount: mediaList.length,
            onPageChanged: (i) => currentPage.value = i,
            itemBuilder: (context, i) {
              final url = mediaList[i].toString().toLowerCase();
              final isVideo =
                  url.endsWith('.mp4') || url.endsWith('.mov');

              if (isVideo) {
                return FeedVideoPlayer(
                  url: mediaList[i].toString(),
                );
              }

              return CachedNetworkImage(
                imageUrl: mediaList[i],
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.black12),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error),
              );
            },
          ),

          /// INDICATOR
          if (mediaList.length > 1)
            Positioned(
              top: 10,
              right: 10,
              child: ValueListenableBuilder<int>(
                valueListenable: currentPage,
                builder: (_, page, __) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${page + 1}/${mediaList.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}