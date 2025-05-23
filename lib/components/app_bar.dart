import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/home/search_provider.dart';
import 'package:window_manager/window_manager.dart';

class SimpleAppbar extends ConsumerStatefulWidget {
  final String title;
  final Widget? leading;
  final bool showSearchBar;
  const SimpleAppbar({
    super.key,
    required this.title,
    this.leading,
    this.showSearchBar = true,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SimpleAppbarState();
}

class _SimpleAppbarState extends ConsumerState<SimpleAppbar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onPanStart: (details) {
            if (defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux ||
                defaultTargetPlatform == TargetPlatform.macOS) {
              windowManager.startDragging();
            }
          },
          child: AppBar(
            leading: widget.leading,
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text(widget.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.minimize),
                onPressed: () async {
                  await windowManager.minimize();
                },
              ),
              IconButton(
                icon: const Icon(Icons.crop_square),
                onPressed: () async {
                  await windowManager.maximize();
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: Colors.red.shade600,
                onPressed: () async {
                  await windowManager.close();
                },
              ),
            ],
          ),
        ),

        Visibility(
          visible: widget.showSearchBar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withAlpha(200),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ],
    );
  }
}
