import CoreLocation
import MapKit
import UIKit

// MARK: - Location Manager

final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let manager = CLLocationManager()

    var currentLocation: CLLocation? { manager.location }

    private override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func reverseGeocode(_ location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        guard let place = placemarks?.first else { return nil }
        return [place.locality, place.administrativeArea]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

// MARK: - Map Popup

final class MapPopupViewController: UIViewController {
    private let coordinate: CLLocationCoordinate2D
    private let address: String

    private let mapView = MKMapView()
    private let addressLabel = UILabel()
    private let openMapsButton = UIButton(type: .system)
    private let containerView = UIView()

    init(coordinate: CLLocationCoordinate2D, address: String) {
        self.coordinate = coordinate
        self.address = address
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        setupContainer()
        setupMapView()
        setupAddressLabel()
        setupOpenMapsButton()
    }

    private func setupContainer() {
        containerView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            containerView.heightAnchor.constraint(equalToConstant: 320)
        ])
    }

    private func setupMapView() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isUserInteractionEnabled = false
        containerView.addSubview(mapView)

        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        mapView.setRegion(region, animated: false)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalToConstant: 180)
        ])
    }

    private func setupAddressLabel() {
        addressLabel.text = address
        addressLabel.textColor = .white
        addressLabel.font = .systemFont(ofSize: 16, weight: .medium)
        addressLabel.textAlignment = .center
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(addressLabel)

        NSLayoutConstraint.activate([
            addressLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 16),
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            addressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }

    private func setupOpenMapsButton() {
        openMapsButton.setTitle("Open in Maps", for: .normal)
        openMapsButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        openMapsButton.backgroundColor = UIColor(white: 0.2, alpha: 1)
        openMapsButton.layer.cornerRadius = 8
        openMapsButton.translatesAutoresizingMaskIntoConstraints = false
        openMapsButton.addTarget(self, action: #selector(openInMaps), for: .touchUpInside)
        containerView.addSubview(openMapsButton)

        NSLayoutConstraint.activate([
            openMapsButton.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 16),
            openMapsButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            openMapsButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            openMapsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            dismiss(animated: true)
        }
    }

    @objc private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = address
        mapItem.openInMaps(launchOptions: nil)
    }
}

extension MapPopupViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view
    }
}
