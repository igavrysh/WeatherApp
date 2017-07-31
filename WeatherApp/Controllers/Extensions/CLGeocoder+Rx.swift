import CoreLocation
import RxSwift

public extension CLGeocoder {
    
    class func rx_geocodeAddressString(address: String) -> Observable<[CLPlacemark]> {
        return Observable<[CLPlacemark]>.create { observer in
            CLGeocoder().geocodeAddressString(address) { (placemarks, error) in
                if let error = error {
                    print(error)
                    
                    return
                }
                
                guard let placemarks = placemarks else {
                    observer.onNext([CLPlacemark]())
                    
                    return
                }
                
                observer.onNext(placemarks)
            }
            
            return Disposables.create()
        }
    }
}


