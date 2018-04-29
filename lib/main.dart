import 'package:awesome_dev/config/application.dart';
import 'package:awesome_dev/config/routes.dart';
import 'package:awesome_dev/ui/archives.dart';
import 'package:awesome_dev/ui/favorites.dart';
import 'package:awesome_dev/ui/latest_news.dart';
import 'package:awesome_dev/ui/tags.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:logging/logging.dart';

void main() => runApp(new AwesomeDevApp());

class AwesomeDevApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Logger.root // Optional
      ..level = Level.ALL
      ..onRecord.listen((rec) {
        print('${rec.level.name}: ${rec.time}: ${rec.message}');
      });

    return new MaterialApp(
      title: 'Awesome Dev',
      theme: new ThemeData(
        primaryColor: Colors.green,
        backgroundColor: Colors.white,
      ),
      home: new AwesomeDev(),
    );
  }
}

class AwesomeDev extends StatefulWidget {
  static const String routeName = '/material/bottom_navigation';

  @override
  State<StatefulWidget> createState() => new _AwesomeDevState();

  static _AwesomeDevState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_AwesomeDevInheritedWidget)
            as _AwesomeDevInheritedWidget)
        .data;
  }
}

class _AwesomeDevState extends State<AwesomeDev> with TickerProviderStateMixin {
  SearchBar searchBar;
  int _currentIndex = 0;
  List<NavigationIconView> _navigationViews;
  String _searchValue;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void onAppBarMenuItemSelected(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
      title: const Text('Awesome Dev'),
      actions: <Widget>[
        searchBar.getSearchAction(context),
        new PopupMenuButton<String>(
          onSelected: onAppBarMenuItemSelected,
          itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                const PopupMenuItem<String>(
                    value: 'settings', child: const Text('Settings')),
                const PopupMenuItem<String>(
                    value: 'about', child: const Text('About')),
              ],
        ),
      ],
    );
  }

  _AwesomeDevState() {
    final router = new Router();
    Routes.configureRoutes(router);
    Application.router = router;

    searchBar = new SearchBar(
        inBar: true,
        setState: setState,
        onSubmitted: (value) {
          print("Input search value: $value");
          setState(() {
            _searchValue = value;
          });
        },
        buildDefaultAppBar: buildAppBar);
  }

  @override
  void initState() {
    super.initState();

    _navigationViews = <NavigationIconView>[
      new NavigationIconView(
        icon: const Icon(Icons.new_releases),
        title: 'Latest',
//        color: Colors.deepPurple,
        vsync: this,
      ),
      new NavigationIconView(
        icon: const Icon(Icons.favorite),
        title: 'Favorites',
        color: Colors.indigo,
        vsync: this,
      ),
      new NavigationIconView(
        icon: const Icon(Icons.archive),
        title: 'Archives',
        color: Colors.deepOrange,
        vsync: this,
      ),
      new NavigationIconView(
        icon: const Icon(Icons.label),
        title: 'Tags',
        color: Colors.teal,
        vsync: this,
      ),
    ];

    for (NavigationIconView view in _navigationViews) {
      view.controller.addListener(_rebuild);
    }
    _navigationViews[_currentIndex].controller.value = 1.0;
  }

  @override
  void dispose() {
    for (NavigationIconView view in _navigationViews) view.controller.dispose();
    super.dispose();
  }

  void _rebuild() {
    setState(() {
      // Rebuild in order to animate views.
    });
  }

  Widget _buildTransitionsStack() {
    if (_currentIndex == 0) {
      return new LatestNews(search: _searchValue);
    }
    if (_currentIndex == 1) {
      return new FavoriteNews(search: _searchValue);
    }
    if (_currentIndex == 2) {
      return new ArticleArchives(search: _searchValue);
    }
    if (_currentIndex == 3) {
      return new Tags(search: _searchValue);
    }

    final List<FadeTransition> transitions = <FadeTransition>[];

    for (NavigationIconView view in _navigationViews) {
      transitions.add(view.transition(BottomNavigationBarType.fixed, context));
    }

    // We want to have the newly animating (fading in) views on top.
    transitions.sort((FadeTransition a, FadeTransition b) {
      final Animation<double> aAnimation = a.opacity;
      final Animation<double> bAnimation = b.opacity;
      final double aValue = aAnimation.value;
      final double bValue = bAnimation.value;
      return aValue.compareTo(bValue);
    });

    return new Stack(children: transitions);
  }

  @override
  Widget build(BuildContext context) {
    final BottomNavigationBar botNavBar = new BottomNavigationBar(
      items: _navigationViews
          .map((NavigationIconView navigationView) => navigationView.item)
          .toList(),
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        setState(() {
          _navigationViews[_currentIndex].controller.reverse();
          _currentIndex = index;
          _navigationViews[_currentIndex].controller.forward();
        });
      },
    );

    return new _AwesomeDevInheritedWidget(
      data: this,
      child: new Scaffold(
        appBar: searchBar.build(context),
        body: new Center(child: _buildTransitionsStack()),
        bottomNavigationBar: botNavBar,
      ),
    );
  }
}

class _AwesomeDevInheritedWidget extends InheritedWidget {
  final _AwesomeDevState data;

  _AwesomeDevInheritedWidget({Key key, this.data, Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_AwesomeDevInheritedWidget old) => true;
}

class NavigationIconView {
  NavigationIconView({
    Widget icon,
    String title,
    Color color,
    TickerProvider vsync,
  })  : _icon = icon,
        _color = color,
        _title = title,
        item = new BottomNavigationBarItem(
          icon: icon,
          title: new Text(title),
          backgroundColor: color,
        ),
        controller = new AnimationController(
          duration: kThemeAnimationDuration,
          vsync: vsync,
        ) {
    _animation = new CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );
  }

  final Widget _icon;
  final Color _color;
  final String _title;
  final BottomNavigationBarItem item;
  final AnimationController controller;
  CurvedAnimation _animation;

  FadeTransition transition(
      BottomNavigationBarType type, BuildContext context) {
    Color iconColor;
    if (type == BottomNavigationBarType.shifting) {
      iconColor = _color;
    } else {
      final ThemeData themeData = Theme.of(context);
      iconColor = themeData.brightness == Brightness.light
          ? themeData.primaryColor
          : themeData.accentColor;
    }

    return new FadeTransition(
      opacity: _animation,
      child: new SlideTransition(
        position: new Tween<Offset>(
          begin: const Offset(0.0, 0.02), // Slightly down.
          end: Offset.zero,
        ).animate(_animation),
        child: new IconTheme(
          data: new IconThemeData(
            color: iconColor,
            size: 120.0,
          ),
          child: new Semantics(
            label: 'Placeholder for $_title tab',
            child: _icon,
          ),
        ),
      ),
    );
  }
}
