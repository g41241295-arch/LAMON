import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_background.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;
  final Gradient? backgroundGradient;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
    this.backgroundGradient,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 520;

        final scaffoldWidget = Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: SafeArea(
            child: body,
          ),
          bottomNavigationBar: bottomNavigationBar,
        );

        Widget content;
        if (backgroundColor != null || backgroundGradient != null) {
          content = Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              gradient: backgroundColor != null
                  ? null
                  : (backgroundGradient ??
                      const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.bgGradientTop,
                          AppColors.bgGradientMiddle,
                          AppColors.bgGradientBottom,
                        ],
                      )),
            ),
            child: scaffoldWidget,
          );
        } else {
          // Latar bg_beranda_polos.png menggantikan gradient kuning polos lama.
          // Scaffold di dalamnya tetap transparan agar latar tembus.
          content = AppBackground(
            child: scaffoldWidget,
          );
        }

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
