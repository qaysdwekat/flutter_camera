import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../flutter_camera.dart';

class MediaTypeSwitch extends StatefulWidget {
  const MediaTypeSwitch({
    super.key,
    required this.supportedTypes,
    required this.onChanged,
  });
  final List<CameraMediaType> supportedTypes;
  final void Function(CameraMediaType) onChanged;

  @override
  State<StatefulWidget> createState() => _MediaTypeSwitchState();
}

class _MediaTypeSwitchState extends State<MediaTypeSwitch> {
  late CameraMediaType type;
  @override
  void initState() {
    type = widget.supportedTypes.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStyle = GoogleFonts.roboto(
      fontWeight: FontWeight.w500,
      fontSize: 14,
      color: Color(0xFFFFD60A),
    );

    final unSelectedStyle = GoogleFonts.roboto(
      fontWeight: FontWeight.normal,
      fontSize: 14,
      color: Color(0xFFFFFFFF),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        ...widget.supportedTypes.map(
          (item) => GestureDetector(
            onTap: () {
              type = item;
              widget.onChanged.call(item);
              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                item.name.toUpperCase(),
                style: item == type ? selectedStyle : unSelectedStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
