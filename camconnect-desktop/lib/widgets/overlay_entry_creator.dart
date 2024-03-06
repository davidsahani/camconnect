import 'package:flutter/material.dart';

class OverlayEntryCreator {
  OverlayEntryCreator(this.context);

  final BuildContext context;

  OverlayEntry? _overlayEntry;

  void create(Widget widget, int widgetChildrenLength) {
    final overlayEntry = _createOverlayEntry(widget, widgetChildrenLength);
    Overlay.of(context).insert(overlayEntry);
    _overlayEntry = overlayEntry;
  }

  void remove() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry(Widget widget, int widgetChildrenLength) {
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    // Size? size = renderBox?.size;
    Offset? offset = renderBox?.localToGlobal(Offset.zero);
    bool layoutCompleted = false;

    return OverlayEntry(
      builder: (context) => LayoutBuilder(builder: (context, constraints) {
        try {
          var _ = (context.findRenderObject() as RenderBox?)?.size;
          if (layoutCompleted) {
            remove(); // on widget resize
          }
        } catch (_) {} // expected to fail at first widget load.
        layoutCompleted = true;

        return Stack(children: [
          GestureDetector(
            // Remove when tapped outside
            onTap: remove,
          ),
          Positioned(
            left: offset == null ? null : offset.dx - 35.0,
            top: offset == null
                ? null
                : widgetChildrenLength == 1
                    ? offset.dy - 10
                    : widgetChildrenLength <= 10
                        ? offset.dy / (widgetChildrenLength * 0.6)
                        : offset.dy / 3.2,
            // width: size?.width,
            width: 365.0,
            child: Material(
              elevation: 4.0,
              child: widget,
            ),
          ),
        ]);
      }),
    );
  }
}
