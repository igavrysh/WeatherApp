import UIKit
import ScrollableGraphView
import RxSwift
import RxCocoa
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet var graphView : ScrollableGraphView!
    @IBOutlet weak var geoLocationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var locationTipTableView: UITableView!
    
    let bag = DisposeBag()
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        style()
        
        _ = self.searchCityName.rx.text
            .filter { ($0 ?? "").characters.count > 0 }
            .map { $0! }
            .flatMap { text in
                CLGeocoder.rx_geocodeAddressString(address: text)
            }
            .map({ (placemarks: [CLPlacemark]) -> [CLPlacemark] in
                return placemarks.filter { ($0.locality ?? "").characters.count > 0  }
            })
            .do(onNext: {
                self.locationTipTableView.isHidden = $0.count == 0
            })
            .filter { (placemarks: [CLPlacemark]) -> Bool in
                return placemarks.count > 0
            }
            .map({ placemarks -> [String] in
                placemarks.map { "\($0.locality ?? ""), \($0.country ?? "")" }
            })
            .do(onNext: { localities in
                print(localities)
            })
            .bind(to: self.locationTipTableView.rx.items) { (tableView: UITableView, index: Int, element: String) in
                let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
                cell.textLabel?.text = element
                
                return cell
            }.addDisposableTo(self.bag)
        
        let searchInput = self.locationTipTableView.rx.modelSelected(String.self)
            .do(onNext: { model in
                self.locationTipTableView.isHidden = true
            })
            .filter { $0.characters.count > 0 }
        
        let textSearch = searchInput
            .flatMap { text in
                return ApiController.shared.currentWeather(city: text)
                    .catchErrorJustReturn(ApiController.Weather.dummy)
        }

        
        let geoInput = self.geoLocationButton.rx.tap.asObservable()
            .do(onNext: { _ in
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            })
        
        let currentLocation = self.locationManager.rx.didUpdateLocations
            .map { locations in
                return locations[0]
            }
            .filter { location in
                return location.horizontalAccuracy < kCLLocationAccuracyHundredMeters
        }
        
        let geoLocation = geoInput
            .flatMap {
                return currentLocation.take(1)
        }
        
        let geoSearch = geoLocation
            .flatMap { location in
                return ApiController.shared.currentWeather(lat: location.coordinate.latitude,
                                                           lon: location.coordinate.longitude)
                    .catchErrorJustReturn(ApiController.Weather.dummy)
        }

        
        let search = Observable
            .from([geoSearch, textSearch])
            .merge()
            .asDriver(onErrorJustReturn: ApiController.Weather.dummy)
        
        
        let running = Observable.from([
            searchInput.map { _ in true },
            geoInput.map { _ in true },
            search.map { _ in false }.asObservable()
            ])
            .merge()
            .startWith(true)
            .asDriver(onErrorJustReturn: false)
        
        running
            .skip(1)
            .drive(self.activityIndicator.rx.isAnimating)
            .addDisposableTo(self.bag)
        
        running
            .drive(self.tempLabel.rx.isHidden)
            .addDisposableTo(self.bag)
        
        running
            .drive(self.iconLabel.rx.isHidden)
            .addDisposableTo(self.bag)
        
        running
            .drive(self.humidityLabel.rx.isHidden)
            .addDisposableTo(self.bag)
        
        search.map { "\($0.temperature)℃" }
            .drive(self.tempLabel.rx.text)
            .addDisposableTo(self.bag)
        
        search.map { $0.icon }
            .drive(self.iconLabel.rx.text)
            .addDisposableTo(self.bag)
        
        search.map { "\($0.humidity)%" }
            .drive(self.humidityLabel.rx.text)
            .addDisposableTo(self.bag)
        
        search.map { $0.cityName }
            .drive(self.searchCityName.rx.text)
            .addDisposableTo(self.bag)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    
    // MARK: - Style
    
    private func style() {
        view.backgroundColor = UIColor.aztec
        self.searchCityName.attributedPlaceholder
            = NSAttributedString(string: self.searchCityName.placeholder ?? "",
                                 attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        self.searchCityName.textColor = UIColor.ufoGreen
        self.tempLabel.textColor = UIColor.cream
        self.humidityLabel.textColor = UIColor.cream
        self.iconLabel.textColor = UIColor.cream
        self.locationTipTableView.backgroundColor = UIColor.aztec
        self.locationTipTableView.tintColor = UIColor.ufoGreen
    }
}

