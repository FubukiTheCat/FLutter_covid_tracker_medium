import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:novel_covid_19/controllers/covid_api.dart';
import 'package:novel_covid_19/custom_widgets/statistic_card.dart';
import 'package:novel_covid_19/custom_widgets/virus_loader.dart';
import 'package:novel_covid_19/global.dart';
import 'package:novel_covid_19/models/country_model.dart';
import 'package:novel_covid_19/models/global_info_model.dart';
import 'package:novel_covid_19/views/country_detail.dart';

class GlobalInfoPage extends StatefulWidget {
  @override
  _GlobalInfoPageState createState() => _GlobalInfoPageState();
}

class _GlobalInfoPageState extends State<GlobalInfoPage> {
  GlobalInfo _stats;
  double deathPercentage;
  double activePercentage;
  bool _isLoading = false;
  CovidApi api = CovidApi();
  double recoveryPercentage;
  String flagDir = "assets/flag/";
  HomeCountry _homeCountry;

  @override
  void initState() {
    super.initState();
    _fetchHomeCountry();
    _fetchGlobalStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? VirusLoader()
          : _stats == null
              ? buildErrorMessage()
              : ListView(
                  children: <Widget>[
                    if (_homeCountry != null)
                      ListTile(
                        leading: SvgPicture.asset(
                          flagDir + _homeCountry.name + '.svg',
                          height: 36,
                        ),
                        title: Text(_homeCountry.name),
                        subtitle: Text(
                          _homeCountry.cases + '--' + _homeCountry.deaths,
                        ),
                        trailing: Icon(Icons.arrow_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CountryDetailPage(
                              countryName: _homeCountry.name,
                            ),
                          ),
                        ),
                      ),
                    ListTile(
                      leading: SvgPicture.asset(
                        flagDir + 'World.svg',
                        height: 36,
                      ),
                      title: Text(
                        "World",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CountryDetailPage(
                            countryName: "World",
                          ),
                        ),
                      ),
                    ),
                    StatisticCard(
                      color: Colors.orange,
                      text: '  \n SỐ CA NHIỄM   ',
                      icon: Icons.sick,
                      stats: _stats.cases,
                    ),
                    StatisticCard(
                      color: Colors.redAccent,
                      text: '   \n HỒI PHỤC   ',
                      icon: Icons.favorite,
                      stats: _stats.recovered,
                    ),
                    StatisticCard(
                      color: Colors.red,
                      text: '  \n TỬ VONG   ',
                      icon: Icons.airline_seat_individual_suite,
                      stats: _stats.deaths,
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
                          title: Text('Phần trăm hồi phục'),
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

  void _fetchGlobalStats() async {
    setState(() => _isLoading = true);
    try {
      var stats = await api.getGlobalInfo();
      deathPercentage = (stats.deaths / stats.cases) * 100;
      recoveryPercentage = (stats.recovered / stats.cases) * 100;
      activePercentage = 100 - (deathPercentage + recoveryPercentage);

      setState(() => _stats = stats);
    } catch (ex) {
      setState(() => _stats = null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _fetchHomeCountry() async {
    var list = await mySharedPreferences.fetchHomeCountry();
    if (list != null) {
      setState(() {
        _homeCountry = HomeCountry(
          name: list[0],
          cases: list[1],
          deaths: list[2],
        );
      });
    }
  }
}
