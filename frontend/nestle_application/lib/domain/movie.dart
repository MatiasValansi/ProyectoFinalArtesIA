import 'info_interface.dart';


class Movie implements InfoInterface {
  final String title;
  final String director;
  final int? year;
  final String _gener;


  Movie({
    required this.title,
    required this.director,
    this.year,
    String gener = 'Unknown',
  }) : _gener = gener;

  @override
  String getInfo() {
    return 'Movie: $title, Director: $director, Year: $year, Genre: $_gener';
  }
}