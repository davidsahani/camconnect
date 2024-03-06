import 'dart:io';

import 'package:flutter/material.dart';

void showIpDropdownEntriesDialog(
  BuildContext context,
  List<(NetworkInterface, InternetAddress)> addresses,
  void Function((NetworkInterface, InternetAddress)) onSelected,
) {
  showDialog(
    context: context,
    builder: (context) => SimpleDialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 30.0),
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: const Text(
        "Select Network Interface",
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        _IPDropdownEntries(
          addresses: addresses,
          onSelected: (address) {
            onSelected(address);
            Navigator.pop(context);
          },
        )
      ],
    ),
  );
}

class _IPDropdownEntries extends StatelessWidget {
  const _IPDropdownEntries({
    required this.addresses,
    required this.onSelected,
  });

  final List<(NetworkInterface, InternetAddress)> addresses;
  final void Function((NetworkInterface, InternetAddress)) onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: addresses.map((address) {
            return SimpleDialogOption(
              padding: const EdgeInsets.fromLTRB(25.0, 16.0, 25.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.$1.name,
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Divider(height: 0.0, thickness: 1.2),
                  Text(
                    address.$2.address,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
              onPressed: () => onSelected(address),
            );
          }).toList(),
        ),
      ),
    );
  }
}
