//
//  ViewController.swift
//  Weather R
//
//  Created by 김재만 on 8/11/25.
//

import UIKit
import CoreLocation

class WeatherViewController: UIViewController {
    // 배경 이미지 뷰
    let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "sky") // 프로젝트에 'sky'라는 이미지 추가 필요
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    // MARK: - UI 컴포넌트
    let cityLabel: UILabel = {
        let label = UILabel()
        label.text = "도시"
        label.font = .boldSystemFont(ofSize: 28)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let temperatureLabel: UILabel = {
        let label = UILabel()
        label.text = "온도"
        label.font = .systemFont(ofSize: 70, weight: .thin)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let weatherDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "날씨 설명"
        label.font = .systemFont(ofSize: 20)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let humidityLabel: UILabel = {
        let label = UILabel()
        label.text = "습도"
        label.font = .systemFont(ofSize: 18)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let windSpeedLabel: UILabel = {
        let label = UILabel()
        label.text = "풍속"
        label.font = .systemFont(ofSize: 18)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let weatherIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    let citySelectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("도시 선택", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let unitToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("화씨로 보기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let refreshControl = UIRefreshControl()

    // MARK: - 속성
    let locationManager = CLLocationManager()
    let apiKey = "b4a0395f8de6886654cfc4447ff43d5e" // OpenWeatherMap API 키
    
    var isCelsius = true
    var currentTempCelsius: Double?
    var currentLatitude: Double?
    var currentLongitude: Double?

    // MARK: - 생명주기
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupLocation()
    }

    // MARK: - UI 셋업
    func setupUI() {
        // 기본 배경색

        // 배경 이미지 뷰 (날씨에 따라 바뀜)
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.tag = 999
        backgroundImageView.alpha = 0.5
        view.insertSubview(backgroundImageView, at: 0)

        [cityLabel, temperatureLabel, weatherDescriptionLabel, weatherIconView,
         humidityLabel, windSpeedLabel, citySelectButton, unitToggleButton].forEach {
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cityLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),

            temperatureLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            temperatureLabel.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 10),

            weatherIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            weatherIconView.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 10),
            weatherIconView.widthAnchor.constraint(equalToConstant: 100),
            weatherIconView.heightAnchor.constraint(equalToConstant: 100),

            weatherDescriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            weatherDescriptionLabel.topAnchor.constraint(equalTo: weatherIconView.bottomAnchor, constant: 10),

            humidityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            humidityLabel.topAnchor.constraint(equalTo: weatherDescriptionLabel.bottomAnchor, constant: 10),

            windSpeedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            windSpeedLabel.topAnchor.constraint(equalTo: humidityLabel.bottomAnchor, constant: 10),

            citySelectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60),
            citySelectButton.topAnchor.constraint(equalTo: windSpeedLabel.bottomAnchor, constant: 30),

            unitToggleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60),
            unitToggleButton.centerYAnchor.constraint(equalTo: citySelectButton.centerYAnchor)
        ])

        // Pull to Refresh 추가
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        view.insertSubview(scrollView, aboveSubview: backgroundImageView)
        scrollView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refreshWeather), for: .valueChanged)
    }

    func setupActions() {
        citySelectButton.addTarget(self, action: #selector(selectCityTapped), for: .touchUpInside)
        unitToggleButton.addTarget(self, action: #selector(toggleUnit), for: .touchUpInside)
    }

    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // MARK: - 날씨 업데이트 UI 반영
    func updateWeatherUI(with result: WeatherResponse) {
        cityLabel.text = result.name
        currentTempCelsius = result.main.temp
        updateTemperatureLabel()
        weatherDescriptionLabel.text = result.weather.first?.description.capitalized ?? ""
        humidityLabel.text = "습도: \(result.main.humidity)%"
        windSpeedLabel.text = "풍속: \(result.wind.speed) m/s"
        weatherIconView.image = UIImage(systemName: iconName(for: result.weather.first?.main ?? ""))
        updateBackgroundImage(condition: result.weather.first?.main ?? "")
    }

    func updateTemperatureLabel() {
        guard let tempC = currentTempCelsius else { return }
        if isCelsius {
            temperatureLabel.text = "\(Int(tempC))°C"
            unitToggleButton.setTitle("화씨로 보기", for: .normal)
        } else {
            let tempF = tempC * 9/5 + 32
            temperatureLabel.text = "\(Int(tempF))°F"
            unitToggleButton.setTitle("섭씨로 보기", for: .normal)
        }
    }

    // MARK: - 배경 이미지 업데이트
    func updateBackgroundImage(condition: String) {
        guard let bgImageView = view.viewWithTag(999) as? UIImageView else { return }
        switch condition.lowercased() {
        case "clear": bgImageView.image = UIImage(named: "clear")
        case "clouds": bgImageView.image = UIImage(named: "clouds")
        case "rain": bgImageView.image = UIImage(named: "rain")
        case "snow": bgImageView.image = UIImage(named: "snow")
        case "thunderstorm": bgImageView.image = UIImage(named: "thunderstorm")
        default: bgImageView.image = UIImage(named: "defaultBackground")
        }
    }

    // MARK: - 도시 선택 액션
    @objc func selectCityTapped() {
        let alert = UIAlertController(title: "도시 선택", message: nil, preferredStyle: .actionSheet)
        let cities = ["Seoul", "Busan", "Daegu", "Gwangju", "Gangneung"]
        for city in cities {
            alert.addAction(UIAlertAction(title: city, style: .default, handler: { _ in
                print("도시 선택됨: \(city)")
                self.fetchWeatherByCityName(city: city)
            }))
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }


    func fetchWeatherByCityName(city: String) {
        print("도시 이름으로 날씨 요청: \(city)")
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&appid=\(apiKey)&units=metric&lang=kr"
        requestWeather(urlString: urlString)
    }

    func requestWeather(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("잘못된 URL: \(urlString)")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("네트워크 에러 발생: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("데이터가 없습니다.")
                return
            }

            do {
                let result = try JSONDecoder().decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    print("날씨 데이터 파싱 성공: \(result.name)")
                    self.updateWeatherUI(with: result)
                }
            } catch {
                print("파싱 오류: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("서버 응답: \(responseString)")
                }
            }
        }.resume()
    }


    // MARK: - 온도 단위 토글
    @objc func toggleUnit() {
        isCelsius.toggle()
        updateTemperatureLabel()
    }

    // MARK: - 새로고침 액션
    @objc func refreshWeather() {
        if let lat = currentLatitude, let lon = currentLongitude {
            fetchWeather(latitude: lat, longitude: lon)
        }
        refreshControl.endRefreshing()
    }

    // MARK: - 날씨 가져오기 (위치)
    func fetchWeather(latitude: Double, longitude: Double) {
        currentLatitude = latitude
        currentLongitude = longitude
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric&lang=kr"
        requestWeather(urlString: urlString)
    }

    // MARK: - 날씨 가져오기 (도시 이름)


    // MARK: - 아이콘 이름 매핑
    func iconName(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear": return "sun.max.fill"
        case "clouds": return "cloud.fill"
        case "rain": return "cloud.rain.fill"
        case "snow": return "snow"
        case "thunderstorm": return "cloud.bolt.fill"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - 위치 관리자 델리게이트
extension WeatherViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        fetchWeather(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 오류: \(error.localizedDescription)")
    }
}

// MARK: - UIScrollViewDelegate (Pull to Refresh를 위해)
extension WeatherViewController: UIScrollViewDelegate {}

// MARK: - 모델
struct WeatherResponse: Decodable {
    let name: String
    let main: Main
    let weather: [Weather]
    let wind: Wind
}

struct Main: Decodable {
    let temp: Double
    let humidity: Int
}

struct Weather: Decodable {
    let main: String
    let description: String
}

struct Wind: Decodable {
    let speed: Double
}
