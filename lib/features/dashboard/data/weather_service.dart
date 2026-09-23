import 'package:skindisease/core/constants/api_constants.dart';
import 'package:skindisease/core/network/api_client.dart';

class WeatherService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    final url = '${ApiConstants.baseUrlWeather}/data/2.5/weather';

    final data = await _client.get(
      url,
      params: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'appid': ApiConstants.weatherApiKey,
        'units': 'metric',   // suhu Celcius
      },
    );

    return data as Map<String, dynamic>;
  }
}
