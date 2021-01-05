import 'package:FSOUNotes/ui/shared/app_config.dart';
import 'package:flutter/material.dart';

class DrawerHeaderView extends StatelessWidget {
  const DrawerHeaderView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: App(context).appHeight(0.23),
      child: DrawerHeader(
        margin: EdgeInsets.all(0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            colors: [
              Colors.teal.shade300,
              Colors.teal.shade400,
            ],
            end: Alignment.bottomRight,
            stops: [0, 1],
          ),
        ),
        child: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              //color: Colors.yellow,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'OU Notes',
                    textAlign: TextAlign.left,
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        .copyWith(fontSize: 25),
                  ),
                ],
              ),
            ),
            Container(
              height: App(context).appHeight(0.14),
              width: App(context).appWidth(0.3),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.3,
                  child: Image(image: AssetImage("assets/images/apnaicon.png")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
