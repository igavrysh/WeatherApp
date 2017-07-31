import Alamofire
import Foundation
import ObjectMapper
import SwiftyJSON

extension Optional {
    func `do`(execute: (Wrapped) -> ()) {
        self.map(execute)
    }
}

struct DailyForecast: Mappable {
    var series: [DailyForecastPoint]?
    
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        series <- map["list"]
    }
}

struct DailyForecastPoint: Mappable {
    var temp: DailyTemperature?
    var weather: DailyWeather?
    var humidity: Int?
    var date: Date?
    var cloudliness: Int?
    var windDirection: Int?
    var pressure: Float?
    var windSpeed: Float?
    
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        date <- (map["dt"], DateTransform())
        temp <- map["temp"]
        weather <- map["weather.0"]
        cloudliness <- map["clouds"]
        humidity <- map["humidity"]
        windDirection <- map["deg"]
        pressure <- map["pressure"]
        windSpeed <- map["speed"]
    }
}

struct DailyTemperature: Mappable {
    var night: Float?
    var min: Float?
    var eve: Float?
    var day: Float?
    var max: Float?
    var morn: Float?
    
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        night <- map["night"]
        min <- map["min"]
        eve <- map["eve"]
        day <- map["day"]
        max <- map["max"]
        morn <- map["morn"]
    }
}

struct DailyWeather: Mappable {
    var id: Int?
    var main: String?
    var icon: String?
    var description: String?
    
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        id <- map["id"]
        main <- map["main"]
        icon <- map["icon"]
        description <- map["description"]
    }
}

class WeatherGetter {
    private let openWeatherMapBaseURL = "http://api.openweathermap.org/data/2.5"
    private let currentWeatherPathComponent = "weather"
    private let forecastPathComponent  = "forecast/daily/"
    private let openWeatherMapAPIKey = "5735e06e382e84b140f3ebca838a4a31"
    
    private func appid() -> String {
        return "APPID=\(openWeatherMapAPIKey)"
    }
    
    private func q(city: String) -> String {
        return "q=\(city)"
    }
    
    func getCurrentWeather(city: String) {
        let session = URLSession.shared
        
        var requestString = openWeatherMapBaseURL;
        requestString.append("/\(currentWeatherPathComponent)?\(self.appid())&\(self.q(city: city))")
        
        let requestURL = URL(string: requestString)
    
        requestURL.do {
            let dataTask = session.dataTask(with: $0) { (data:Data?, response:URLResponse?, error:Error?) in
                if let error = error {
                    print("Error:\n\(error)")
                }
                else {
                    let json = JSON(data: data!)
                    let forecastDays = json["list"].arrayValue;
                    
                    print("Human-readable json:\n\(json)")
                }
            }
            
            dataTask.resume()
        }
    }
    
    func getWeatherForecast(city: String) {
        let session = URLSession.shared
        
        var requestString = openWeatherMapBaseURL;
        requestString.append("/\(forecastPathComponent)?\(self.appid())&\(self.q(city: city))&lang=ua&units=metric&cnt=16")
        
        let requestURL = URL(string: requestString)
        
        requestURL.do {
            let dataTask = session.dataTask(with: $0) { (data:Data?, response:URLResponse?, error:Error?) in
                if let error = error {
                    print("Error:\n\(error)")
                } else {
                    data.do {
                        let json = try! JSONSerialization.jsonObject(with: $0, options: [])
                        if let dictionary = json as? [String: Any] {
                            let series = ObjectMapper.Mapper<DailyForecast>().map(JSON: dictionary)
                        }
                        
                        var sample1 = "Lug"
                        var sample2 = "Lugansk"
                        
                        let temp = sample1.scoreAgainst(sample2)
                        var s = 1;
                    }
                }
            }
            
            dataTask.resume()
        }
    }
    
    /*
    private func parseForecastPoint(json: JSON) -> ForecastPoint {
        var date = Date(timeIntervalSinceReferenceDate: json["dt"].intValue)
        var
            
        } Date(timeIntervalSinceReferenceDate: )
        var forecastPoint = ForecastPoint(date: D, temp: <#T##ForecastPoint.Temperature#>, weather: <#T##ForecastPoint.Weather#>)
    }
 
 */
}
