//
//  ViewController.swift
//  TenYearChallenge
//
//  Created by MAC on 2020/11/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // youtube網址為網頁，須取得影片網址
    //var player = AVPlayer(url: URL(string: "放youtube網址")!)
    
    // 建立型別為[Photo]的物件
    var photos = [Photo]()
    let apiKey = "e76411f1f95ab39119c946666f01ffcb"
    var imageURL: URL!
    var years = [2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019]
    var timer: Timer?
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker! {
        didSet {
            // 設定樣式
            datePicker.preferredDatePickerStyle = .wheels
            // 設定只選擇日期
            datePicker.datePickerMode = .date
        }
    }
    
    @IBOutlet weak var dateSlider: UISlider! {
        didSet {
            dateSlider.maximumValue = 2019
            dateSlider.minimumValue = 2009
            
            // 初始時間
            dateSlider.value = 2009
        }
    }
    @IBOutlet weak var autoSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //player.play()
        
        // 設定導覽列字型
        navigationController?.navigationBar.prefersLargeTitles = true
        if let customFont = UIFont(name: "Goldman-Regular", size: 30) {
            navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.font: customFont, NSAttributedString.Key.foregroundColor: UIColor.black]
            print("navigaionBar largeTitleText setting success")
        }
        
        // 初始datepicker的日期
        initDatepickerTime()
        
        // 初始photo陣列
        initPhotos()
        
        // 至flickr抓取圖片
        fetchData()
        
        // 顯示年份
        yearLabel.text = String(Int(dateSlider.value))
        
        // 將switch設為off
        autoSwitch.setOn(false, animated: true)
        

    }
    
    
    @IBAction func dateSlide(_ sender: UISlider) {
        // 取得slider年份
        let year = sender.value
        
        // 設定與datePicker同步年份
        // 建立DateComponents物件
        var dateComponents = DateComponents()
        // 取得目前日曆物件(用於計算時間)
        dateComponents.calendar = Calendar.current
        // 存取當前選到的年份
        dateComponents.year = Int(year)
        // 將組成之日期傳給datepicker
        datePicker.date = dateComponents.date!
        
        // 同步label年份
        yearLabel.text = String(Int(year))
        
        // update
        let index = Int(year) - 2009
        showImage(index)
    }
    
    @IBAction func datePick(_ sender: UIDatePicker) {
        
        // 設定與dateSlider同步年份
        let comp = sender.calendar.dateComponents([.year], from: sender.date)
        print(comp)
        print(comp.year!)
        dateSlider.value = Float(comp.year!)
        
        // 同步label年份
        yearLabel.text = String(comp.year!)
        
        // update imageView
        let index = comp.year! - 2009
        showImage(index)
    }
    
    @IBAction func autoPlaySwitch(_ sender: UISwitch) {
        if sender.isOn {
            // 每隔1.5秒自動播放下一張圖片，並無限重複
            timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { block  in
                var currentYear = Int(self.yearLabel.text!)
                var index = currentYear! - 2009
                
                // 判斷年份若超過2019則重新回到2009
                (index >= 10) ? (index = 0) : (index += 1)
                print("index:", index)
                print("Auto Play")
                    
                self.showImage(index)
                
                // update slider & datepicker
                currentYear = index + 2009
                self.yearLabel.text = String(currentYear!)
                self.dateSlider.setValue(Float(currentYear!), animated: true)
                
                var dateComponents = DateComponents()
                dateComponents.calendar = Calendar.current
                dateComponents.year = currentYear
                self.datePicker.date = dateComponents.date!
                print("update Date done")
            }
        } else {
            // 關閉timer，停止自動播放
            timer?.invalidate()
            print("stop auto play")
        }
    }

    // 利用API送出指定url獲取Data後解析
    func fetchData() {
        // 抓取2009-2019年間的Data
        for year in years {
            let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=Kobe+Bryant&tags=NBA&per_page=1&max_taken_date=\(year)-12-31%2023:59:59&min_taken_date=\(year)-01-01%2000:00:00&format=json&nojsoncallback=1"
                print("url success!")
                print(url)
            let index = (year - 2009)
            if let url = URL(string: url) {
                    // 抓取Data
                    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                        // 解析JSON
                        if let data = data, let searchData = try? JSONDecoder().decode(SearchData.self, from: data) {
                            print("index:\(index)", year, searchData.photos.photo)
                            self.photos.remove(at: index)
                            self.photos.insert(contentsOf: searchData.photos.photo, at: index)
                            self.showImage(0)
                        }
                        print(self.photos)
                    }
                    // 啟動任務
                    task.resume()
            }
        }
    }
    
    // 利用回傳的Data重組url後download image
    func downloadImage(url: URL, handler: @escaping (UIImage?) -> ()) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, let image = UIImage(data: data) {
                handler(image)
            } else {
                handler(nil)
            }
        }
        task.resume()
    }
    
    func showImage(_ index: Int) {
        print("showImage")
        let photo = photos[index]
        imageURL = photo.imageUrl
        downloadImage(url: imageURL) { (image) in
            if self.imageURL == photo.imageUrl, let image = image {
                DispatchQueue.main.async {
                    self.photoImageView.image = image
                }
            }
        }
    }
    
    func initPhotos() {
        photos = [Photo](repeating: Photo(farm: 0, secret: "", id: "", server: "", title: ""), count: years.count)
        print(photos)
    }
    
    func initDatepickerTime() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let maxDate = dateFormatter.date(from: "2019/12/31")
        let minDate = dateFormatter.date(from: "2009/01/01")
        
        datePicker.date = minDate!
        // 設定最大時間＆最小時間
        datePicker.maximumDate = maxDate
        datePicker.minimumDate = minDate
        
    }
    
}

