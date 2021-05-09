/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Combine

class MainViewController: UIViewController {
  
  // MARK: - Outlets

  @IBOutlet weak var imagePreview: UIImageView! {
    didSet {
      imagePreview.layer.borderColor = UIColor.gray.cgColor
    }
  }
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

  // MARK: - Private properties
  private var subscriptions = Set<AnyCancellable>()
  private let images = CurrentValueSubject<[UIImage], Never>([])

  // MARK: - View controller
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let collageSize = imagePreview.frame.size
    
    images
        .handleEvents(receiveOutput: { [weak self] photos in
            self?.updateUI(photos: photos)
        })
        .map { photos in
            UIImage.collage(images: photos, size: collageSize)
        }
        .assign(to: \.image, on: imagePreview)
        .store(in: &subscriptions)
  }
  
  private func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }
  
  // MARK: - Actions
  
  @IBAction func actionClear() {
    images.send([])
  }
  
  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    
    // 1: sink(receiveCompletion: receiveValue:)를 사용하여 Subscribe
    PhotoWriter.save(image)
      .sink(receiveCompletion: { [unowned self] completion in
        // 2: 실패 할 경우 -> showMessage를 사용하여 화면에 오류내용 출력
        if case .failure(let error) = completion {
          self.showMessage("Error", description: error.localizedDescription)
        }
        self.actionClear()
      }, receiveValue: { [unowned self] id in
        // 3: 성공 할 경우 -> showMessage를 사용하여 화면에 Identifier 출력
        self.showMessage("Saved with id: \(id)")
      })
      .store(in: &subscriptions)
  }
  
  @IBAction func actionAdd() {
//    let newImages = images.value + [UIImage(named: "IMG_1907.jpg")!]
//    images.send(newImages)
    
    let photos = storyboard!.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
    // 기존에 선택 되어있는 사진의 개수로 초기화를 해준다.
    photos.selectedPhotosCount = self.images.value.count
    navigationController!.pushViewController(photos, animated: true)
    
    photos.$selectedPhotosCount
      .filter { $0 > 0 }
      .map { "Selected \($0) photos" }
      .assign(to: \.title, on: self)
      .store(in: &subscriptions)
    
    let newPhotos = photos.selectedPhotos.share()
    newPhotos
        .map { [unowned self] newImage in
            return self.images.value + [newImage]
        }
        .assign(to: \.value, on: images)
        .store(in: &subscriptions)
  }
  
  private func showMessage(_ title: String, description: String? = nil) {
//    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
//    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { alert in
//      self.dismiss(animated: true, completion: nil)
//    }))
//    present(alert, animated: true, completion: nil)
    alert(title: title, text: description)
      .sink(receiveValue: { _ in })
      .store(in: &subscriptions)
  }
}
