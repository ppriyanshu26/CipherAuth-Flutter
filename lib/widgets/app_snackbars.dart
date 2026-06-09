import 'package:flutter/material.dart';

class AppSnackBars {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showCustomSnackBar({required BuildContext context, required String message, required Color textColor, String? actionLabel, VoidCallback? onActionPressed,}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    final calculatedDuration = const Duration(seconds: 2);

    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: calculatedDuration, 
        content: Center(
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: const ShapeDecoration(
                color: Colors.black,
                shape: StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(color: textColor, fontSize: 16.0),
                  ),
                  if (actionLabel != null && onActionPressed != null) ...[
                    const SizedBox(width: 12.0),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        onActionPressed();
                      },
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    )
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}