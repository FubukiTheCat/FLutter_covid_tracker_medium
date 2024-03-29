import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:novel_covid_19/controllers/covid_api.dart';
import 'package:novel_covid_19/custom_widgets/statistic_card.dart';
import 'package:novel_covid_19/custom_widgets/theme_switch.dart';
import 'package:novel_covid_19/custom_widgets/virus_loader.dart';
import 'package:novel_covid_19/models/country_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../global.dart';
//import 'dart:io' as io;

class CountryDetailPage extends StatefulWidget {
  final String countryName;

  CountryDetailPage({@required this.countryName});

  @override
  _CountryDetailPageState createState() => _CountryDetailPageState();
}

class _CountryDetailPageState extends State<CountryDetailPage> {
  Country _countryInfo;
  double deathPercentage;
  double activePercentage;
  bool _isLoading = false;
  bool _isHome = false;
  CovidApi api = CovidApi();
  double recoveryPercentage;
  bool _isSettingCountry = false;
  String flagDir = "assets/flag/";
  @override
  void initState() {
    super.initState();
    _initiateSharedPreferences();
    _fetchCountryDetails();
  }

  @override
  Widget build(BuildContext context) {
    final SvgPicture flag = SvgPicture.asset(
      flagDir + widget.countryName + '.svg',
      height: 48,
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          flag != null
              ? flag
              : SvgPicture.asset(
                  flagDir + 'empty.svg',
                  height: 48,
                ),
          Text(
            '  ' + widget.countryName,
            style: TextStyle(color: Theme.of(context).accentColor),
          ),
        ]),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.arrow_back,
            color: Theme.of(context).accentColor,
          ),
        ),
        actions: <Widget>[
          ThemeSwitch(),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? VirusLoader()
            : _countryInfo == null
                ? buildErrorMessage()
                : ListView(
                    children: <Widget>[
                      if (!_isHome)
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: GestureDetector(
                                onTap: _isSettingCountry
                                    ? null
                                    : () async {
                                        setState(() {
                                          _isSettingCountry = true;
                                        });
                                        await mySharedPreferences
                                            .setHomeCountry(HomeCountry(
                                          name: _countryInfo.country,
                                          cases: _countryInfo.cases.toString(),
                                          deaths:
                                              _countryInfo.deaths.toString(),
                                        ));
                                        setState(() {
                                          _isHome = true;
                                          _isSettingCountry = false;
                                        });
                                      },
                                child: Container(
                                  padding: const EdgeInsets.all(4.0),
                                  margin: const EdgeInsets.all(16.0),
                                  child: Text(
                                    _isSettingCountry
                                        ? '...'
                                        : 'Chọn làm quốc gia mặc định',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2
                                        .copyWith(
                                            color:
                                                Theme.of(context).primaryColor),
                                  ),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Theme.of(context).accentColor),
                                ),
                              ),
                            )
                          ],
                        ),
                      StatisticCard(
                        color: Colors.orange,
                        text: ' \nTỔNG SỐ CA NHIỄM   ',
                        icon: Icons.sick,
                        stats: _countryInfo.cases,
                      ),
                      StatisticCard(
                        color: Colors.redAccent,
                        text: '   \nPHỤC HỒI   ',
                        icon: Icons.favorite,
                        stats: _countryInfo.recovered,
                      ),
                      StatisticCard(
                        color: Colors.blue,
                        text: '   \nĐANG ĐIỀU TRỊ   ',
                        icon: Icons.wifi_protected_setup,
                        stats: _countryInfo.active,
                      ),
                      StatisticCard(
                        color: Colors.red,
                        text: '  \nCA NGHIÊM TRỌNG  ',
                        icon: Icons.local_fire_department,
                        stats: _countryInfo.critical,
                      ),
                      StatisticCard(
                        color: Colors.lightBlue,
                        text: ' \nTỔNG MẪU TEST',
                        icon: Icons.youtube_searched_for,
                        stats: _countryInfo.totalTests,
                      ),
                      StatisticCard(
                        color: Colors.red,
                        text: '  \n TỬ VONG',
                        icon: Icons.airline_seat_individual_suite,
                        stats: _countryInfo.deaths,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Card(
                          elevation: 4.0,
                          child: ListTile(
                            leading: Icon(Icons.sentiment_very_dissatisfied),
                            title: Text('Phần trăm tử vong'),
                            trailing: Text(
                              deathPercentage.toStringAsFixed(2) + ' %',
                              style: TextStyle(
                                  color: Theme.of(context).accentColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Card(
                          elevation: 4.0,
                          child: ListTile(
                            leading: Icon(Icons.sentiment_very_satisfied),
                            title: Text('Phần trăm phục hồi'),
                            trailing: Text(
                              recoveryPercentage.toStringAsFixed(2) + ' %',
                              style: TextStyle(
                                  color: Theme.of(context).accentColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
      ),
    );
  }

  Center buildErrorMessage() {
    return Center(
      child: Text(
        'Unable to fetch data',
        style: Theme.of(context).textTheme.title.copyWith(color: Colors.grey),
      ),
    );
  }

  void _fetchCountryDetails() async {
    setState(() => _isLoading = true);
    try {
      var countryInfo = await api.getCountryByName(widget.countryName);

      deathPercentage = (countryInfo.deaths / countryInfo.cases) * 100;
      recoveryPercentage = (countryInfo.recovered / countryInfo.cases) * 100;
      activePercentage = 100 - (deathPercentage + recoveryPercentage);

      setState(() => _countryInfo = countryInfo);
    } catch (ex) {
      print(ex);
      setState(() => _countryInfo = null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initiateSharedPreferences() async {
    var list = await mySharedPreferences.fetchHomeCountry();
    if (list != null && list[0].compareTo(widget.countryName) == 0)
      setState(() {
        _isHome = true;
      });
  }
}
