import 'dart:io';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

enum FeedType { RSS, Atom }

Future<RssFeed> _getFeedData(
    http.Client client, String url, FeedType type) async {
  http.Response response = await client.get(url);
  String body = response.body;

  var feed;
  switch (type) {
    case FeedType.RSS:
      feed = RssFeed.parse(body);
      break;
    case FeedType.Atom:
      feed = AtomFeed.parse(body);
      break;
    default:
      print("Type must be RSS or Atom");
  }

  return feed;
}

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewsHub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark(),
      home: MyHomePage(title: 'NewsHub'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var client = http.Client();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: _getFeedData(client, "https://9to5mac.com/feed/", FeedType.RSS),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(
                child: CircularProgressIndicator(),
              );
            default:
              if (snapshot.hasError)
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              else {
                var feed = snapshot.data;
                return ListView.builder(
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        ExpansionTile(
                          title: Text(feed.items[index].title),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Html(data: feed.items[index].description),
                            ),
                            MaterialButton(
                              onPressed: () async {
                                String url = feed.items[index].link;
                                if (await canLaunch(url)) {
                                  await launch(
                                    url,
                                    forceSafariVC: true,
                                    forceWebView: true,
                                  );
                                } else {
                                  throw 'Could not launch $url';
                                }
                              },
                              color: Theme.of(context).primaryColor,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.launch),
                                  SizedBox(
                                    width: 8.0,
                                  ),
                                  Text('launch'.toUpperCase())
                                ],
                              ),
                            )
                          ],
                        ),
                        Divider(),
                      ],
                    );
                  },
                  itemCount: feed.items.length,
                );
              }
          }
        },
      ),
    );
  }
}
