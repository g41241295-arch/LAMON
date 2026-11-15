import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_background.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 520;

        // Latar bg_beranda_polos.png menggantikan gradient kuning polos lama.
        // Scaffold di dalamnya tetap transparan agar latar tembus.
        Widget content = AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            body: SafeArea(
              child: body,
            ),
            bottomNavigationBar: bottomNavigationBar,
          ),
        );

        if (isLargeScreen) {
          final maxH = constraints.maxHeight.isFinite
              ? constraints.maxHeight.clamp(0.0, 880.0)
              : 860.0;
          return Scaffold(
            backgroundColor: AppColors.desktopBackground,
            body: Center(
              child: Container(
                width: 420,
                height: maxH,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                    width: 3,
                  ),
                ),
                child: content,
              ),
            ),
          );
        }

        return content;
      },
    );
  }
}
