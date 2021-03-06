import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gank/activity/activity_detail.dart';
import 'package:flutter_gank/constant/strings.dart';
import 'package:flutter_gank/net/gank_api.dart';
import 'package:flutter_gank/utils/time_utils.dart';
import 'package:flutter_gank/widget/indicator_factory.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HistoryActivity extends StatefulWidget {
  @override
  _HistoryActivityState createState() => _HistoryActivityState();
}

class _HistoryActivityState extends State<HistoryActivity> with GankApi {
  int _page = 1;
  bool _isLoading = true;
  RefreshController _refreshController;
  List _historyContentData;

  @override
  void initState() {
    super.initState();
    _refreshController = new RefreshController();
    _getHistoryContentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(STRING_HISTORY_DATA),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Offstage(
              offstage: _isLoading,
              child: SmartRefresher(
                  controller: _refreshController,
                  headerBuilder: buildDefaultHeader,
                  footerBuilder: (context, mode) =>
                      buildDefaultFooter(context, mode, () {
                        _refreshController.sendBack(
                            false, RefreshStatus.refreshing);
                      }),
                  onRefresh: _onRefresh,
                  enablePullUp: true,
                  child: ListView.builder(
                      itemCount: _historyContentData?.length ?? 0,
                      itemBuilder: (context, index) {
                        String content = _historyContentData[index]['content'];
                        String date = formatDateStr(
                            _historyContentData[index]['publishedAt']);
                        RegExp exp = new RegExp(r'src=\"(.+?)\"');
                        String imageUrl = exp.firstMatch(content).group(1);
                        if (imageUrl.contains('large')) {
                          imageUrl = imageUrl.replaceFirst("large", "mw690");
                        }
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => DetailActivity(date)));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 10.0),
                            child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(6.0),
                                    image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                            imageUrl),
                                        fit: BoxFit.cover)),
                                child: Stack(
                                  children: <Widget>[
                                    SizedBox.expand(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0x33000000),
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(6.0),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 14.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Text(
                                              date,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .title
                                                  .copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 10.0, right: 50),
                                              child: Text(
                                                _historyContentData[index]
                                                    ['title'],
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .body2
                                                    .copyWith(
                                                        color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                          ),
                        );
                      }))),
          Offstage(
            offstage: !_isLoading,
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          )
        ],
      ),
    );
  }

  void _getHistoryContentData({bool loadMore = false}) async {
    List historyContentData = await getHistoryContentData(_page);
    if (loadMore) {
      _refreshController.sendBack(false, RefreshStatus.idle);
      setState(() {
        _historyContentData.addAll(historyContentData);
        _isLoading = false;
      });
    } else {
      _refreshController.sendBack(true, RefreshStatus.completed);
      setState(() {
        _historyContentData = historyContentData;
        _isLoading = false;
      });
    }
  }

  void _onRefresh(bool up) {
    if (!up) {
      _page++;
      _getHistoryContentData(loadMore: true);
    } else {
      _page = 1;
      _getHistoryContentData();
    }
  }
}
