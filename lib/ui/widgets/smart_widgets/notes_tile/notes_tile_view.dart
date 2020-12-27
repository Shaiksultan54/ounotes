import 'package:FSOUNotes/misc/constants.dart';
import 'package:FSOUNotes/enums/enums.dart';
import 'package:FSOUNotes/models/download.dart';
import 'package:FSOUNotes/models/notes.dart';
import 'package:FSOUNotes/models/vote.dart';
import 'package:FSOUNotes/ui/shared/app_config.dart';
import 'package:FSOUNotes/ui/widgets/dumb_widgets/progress.dart';
import 'package:FSOUNotes/ui/widgets/smart_widgets/notes_tile/notes_tile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:share/share.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stacked/stacked.dart';
import 'package:FSOUNotes/AppTheme/AppStateNotifier.dart';

class NotesTileView extends StatelessWidget {
  final Note note;
  final List<Vote> votes;
  final List<Download> downloadedNotes;
  final bool notification;
  final bool isPinned;
  final Function refresh;

  const NotesTileView({
    Key key,
    this.note,
    this.votes,
    this.downloadedNotes,
    this.notification = false,
    this.isPinned = false,
    this.refresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.onPrimary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final String title =
        note.title != null ? note.title.toUpperCase() : "title";
    final String author =
        note.author != null ? note.author.toUpperCase() : "author";
    final date = note.uploadDate;
    var format = new DateFormat("dd/MM/yy");
    var dateString = format.format(date);
    final int view = note.view;
    final String size = note.size.toString();
    final votevalue = note.votes;
    var theme = Theme.of(context);

    return ViewModelBuilder<NotesTileViewModel>.reactive(
        onModelReady: (model) {
          model.checkIfUserVotedAndDownloadedNote(
              voteval: votevalue,
              downloadedNotebySub: downloadedNotes,
              note: note,
              votesbySub: votes);
        },
        builder: (context, model, child) {
          return FractionallySizedBox(
            widthFactor: 0.99,
            child: model.isBusy
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Container(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: AppStateNotifier.isDarkModeOn || !isPinned
                        ? Constants.mdecoration.copyWith(
                            color: Theme.of(context).colorScheme.background,
                            boxShadow: [],
                          )
                        : Constants.mdecoration.copyWith(
                            color: Theme.of(context).colorScheme.background,
                          ),
                    child: notification
                        ? Shimmer.fromColors(
                            baseColor: Colors.teal,
                            highlightColor: Colors.white,
                            child: NotesColumnWidget(
                              refresh: refresh,
                              title: title,
                              primary: primary,
                              theme: theme,
                              note: note,
                              secondary: secondary,
                              author: author,
                              dateString: dateString,
                              view: view,
                              size: size,
                              model: model,
                              isPinned: isPinned,
                            ),
                          )
                        : NotesColumnWidget(
                            refresh: refresh,
                            title: title,
                            primary: primary,
                            theme: theme,
                            note: note,
                            secondary: secondary,
                            author: author,
                            dateString: dateString,
                            view: view,
                            size: size,
                            model: model,
                            isPinned: isPinned,
                          ),
                  ),
          );
        },
        viewModelBuilder: () => NotesTileViewModel());
  }
}

class NotesColumnWidget extends StatelessWidget {
  const NotesColumnWidget({
    Key key,
    @required this.title,
    @required this.primary,
    @required this.theme,
    @required this.note,
    @required this.secondary,
    @required this.author,
    @required this.dateString,
    @required this.view,
    @required this.size,
    @required this.model,
    @required this.isPinned,
    @required this.refresh,
  }) : super(key: key);

  final String title;
  final Color primary;
  final ThemeData theme;
  final Note note;
  final Color secondary;
  final String author;
  final String dateString;
  final int view;
  final String size;
  final NotesTileViewModel model;
  final bool isPinned;
  final Function refresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FittedBox(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 10,
              ),
              Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(right: 25),
                    height: App(context).appScreenHeightWithOutSafeArea(0.11),
                    width: App(context).appScreenWidthWithOutSafeArea(0.2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/pdf.png',
                        ),
                        // colorFilter: ColorFilter.mode(
                        //     Colors.black.withOpacity(0.1), BlendMode.dstATop),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Container(
                          width: 160,
                          child: Row(
                            children: <Widget>[
                              Container(
                                constraints: model.isnotedownloaded
                                    ? BoxConstraints(maxWidth: 140)
                                    : BoxConstraints(maxWidth: 160),
                                child: Text(
                                  title,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                              isPinned
                                  ? Icon(
                                      MdiIcons.pin,
                                      color: theme.iconTheme.color,
                                      size: 18,
                                    )
                                  : SizedBox(),
                              // model.isnotedownloaded
                              //     ? Icon(
                              //         Icons.done_all,
                              //         color: theme.iconTheme.color,
                              //         size: 18,
                              //       )
                              //     : SizedBox(),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            MdiIcons.shareOutline,
                            color: theme.primaryColor,
                          ),
                          onPressed: () {
                            final RenderBox box = context.findRenderObject();
                            Share.share(
                                "Notes Name: ${note.title}\n\nSubject Name: ${note.subjectName}\n\nLink:${note.GDriveLink}\n\nFind Latest Notes | Question Papers | Syllabus | Resources for Osmania University at the OU NOTES App\n\nhttps://play.google.com/store/apps/details?id=com.notes.ounotes",
                                sharePositionOrigin:
                                    box.localToGlobal(Offset.zero) & box.size);
                          },
                        ),
                        Flexible(
                          child: PopupMenuButton(
                            padding: EdgeInsets.zero,
                            onSelected: (Menu selectedValue) {
                              if (selectedValue == Menu.Report) {
                                model.reportNote(
                                  doc: note,
                                  id: note.id,
                                  subjectName: note.subjectName,
                                  title: note.title,
                                  type: Constants.notes,
                                );
                              } else if (selectedValue == Menu.Pin) {
                                if (isPinned) {
                                  model.unpinNotes(note, refresh);
                                } else {
                                  model.pinNotes(note, refresh);
                                }
                              }
                            },
                            icon: Icon(Icons.more_vert),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                child: Text('Report'),
                                value: Menu.Report,
                              ),
                              PopupMenuItem(
                                child: isPinned
                                    ? Text('Un-Pin Notes')
                                    : Text('Pin Notes'),
                                value: Menu.Pin,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.person,
                          color: secondary,
                          size: 20,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text("Author :$author",
                            style: TextStyle(
                                color: primary,
                                fontSize: 13,
                                letterSpacing: .3)),
                      ],
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.calendar_today,
                          color: secondary,
                          size: 20,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text("Upload Date :$dateString",
                            style: TextStyle(
                                color: primary,
                                fontSize: 13,
                                letterSpacing: .3)),
                      ],
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.remove_red_eye,
                          color: secondary,
                          size: 20,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          view.toString(),
                          style: TextStyle(
                              color: primary, fontSize: 13, letterSpacing: .3),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          size,
                          style: TextStyle(
                              color: primary, fontSize: 13, letterSpacing: .3),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        GestureDetector(
                          onTap: () {
                            model.handleVotes(
                                model.vote, Constants.upvote, note);
                          },
                          child: Container(
                            width: 30,
                            child: IconButton(
                                padding: EdgeInsets.all(0.0),
                                icon: FaIcon(FontAwesomeIcons.longArrowAltUp),
                                color: model.vote == Constants.upvote
                                    ? Colors.green
                                    : Colors.white,
                                iconSize: 30,
                                onPressed: () {
                                  model.handleVotes(
                                      model.vote, Constants.upvote, note);
                                }),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            model.handleVotes(
                                model.vote, Constants.downvote, note);
                          },
                          child: Container(
                            width: 30,
                            child: IconButton(
                                icon: FaIcon(FontAwesomeIcons.longArrowAltDown),
                                color: model.vote == Constants.downvote
                                    ? Colors.red
                                    : Colors.white,
                                iconSize: 30,
                                onPressed: () {
                                  model.handleVotes(
                                      model.vote, Constants.downvote, note);
                                }),
                          ),
                        ),
                        model.isBusy
                            ? circularProgress()
                            : Container(
                                height: 20,
                                width: 20,
                                child: FittedBox(
                                  child: Text(
                                    model.numberOfVotes[note.title].toString(),
                                    style: theme.textTheme.subtitle1
                                        .copyWith(fontSize: 18),
                                  ),
                                ),
                              ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        model.isAdmin
            ? Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Container(
                  child: RaisedButton(
                    child: Text("EDIT", style: TextStyle(color: Colors.white)),
                    color: Colors.blue,
                    onPressed: () async {
                      await model.navigateToEditView(note);
                    },
                  ),
                ),
                Container(
                  child: RaisedButton(
                    child:
                        Text("DELETE", style: TextStyle(color: Colors.white)),
                    color: Colors.red,
                    onPressed: () async {
                      await model.deleteFromGdrive(note);
                    },
                  ),
                ),
              ])
            : Container(),
      ],
    );
  }
}
