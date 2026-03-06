import 'package:flutter/material.dart';

/// Responsive breakpoints following Material 3 adaptive layout specs.
class Breakpoints {
  Breakpoints._();

  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

/// Layout type derived from current screen width.
enum LayoutType { compact, medium, expanded, large }

/// Returns the [LayoutType] for the given [width].
LayoutType layoutTypeOf(double width) {
  if (width < Breakpoints.compact) return LayoutType.compact;
  if (width < Breakpoints.medium) return LayoutType.medium;
  if (width < Breakpoints.expanded) return LayoutType.expanded;
  return LayoutType.large;
}

/// Responsive scaffold that adds a NavigationRail on medium+ screens
/// and constrains content width on large screens.
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationRailDestination> destinations;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.floatingActionButton,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final layout = layoutTypeOf(width);

    if (layout == LayoutType.compact) {
      // Mobile — caller handles BottomNavigationBar
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }

    // Tablet / Desktop — NavigationRail + constrained content
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: layout == LayoutType.large,
            backgroundColor: Theme.of(context).colorScheme.surface,
            destinations: destinations,
            labelType: layout == LayoutType.large
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a child in a constrained width container on wide screens.
class ContentConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
