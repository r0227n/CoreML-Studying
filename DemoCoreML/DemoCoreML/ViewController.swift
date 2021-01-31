//
//  ViewController.swift
//  DemoCoreML
//
//  Created by RyoNishimura on 2021/01/31.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate,
                      UINavigationControllerDelegate {

    let label: UILabel = UILabel()
    let cameraView: UIImageView = UIImageView(image: UIImage(systemName: "nosign")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initImageView()
        initLabel()
        initButton(positionX: 0, buttonTitle: "Filming", action: #selector(takeAPicture(_:)))
        initButton(positionX: 150, buttonTitle: "Save", action: #selector(savePicture(_:)))
        initButton(positionX: 300, buttonTitle: "Album", action: #selector(showAlbum(_:)))
    }
    
    private func initImageView(){
        let screenWidth: CGFloat = view.frame.size.width
        let screenHeight: CGFloat = view.frame.size.height
        
        let rect: CGRect = CGRect(x: 0, y: 0,
                                  width: 300, height: 300)
        cameraView.frame = rect;
        cameraView.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
        self.view.addSubview(cameraView)
    }
    
    private func initLabel(){
        let screenWidth: CGFloat = view.frame.size.width
        let screenHeight: CGFloat = view.frame.size.height
        
        label.frame = CGRect(x: 0, y: screenHeight - 300,
                                width: screenWidth, height: 300)
        label.text = "Tap the [Start] to take a picture"
        self.view.addSubview(label)
    }
    
    private func initButton(positionX: CGFloat, buttonTitle: String, action: Selector){
        let screenHeight:CGFloat = self.view.frame.height

        let button: UIButton = UIButton()
        button.frame = CGRect(x: positionX, y: screenHeight  - 100,
                              width: 150, height: 100)
        button.setTitle(buttonTitle, for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        button.backgroundColor = UIColor.black
        button.addTarget(self,
                         action: action,
                         for: UIControl.Event.touchDown)
        self.view.addSubview(button)
    }
    
    @objc func takeAPicture(_ sendar: UIButton){
        let sourceType:UIImagePickerController.SourceType = UIImagePickerController.SourceType.camera
        // カメラが利用可能かチェック
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        }else{
            label.text = "error"
        }
    }
    
    //　撮影が完了時した時に呼ばれる
    func imagePickerController(_ imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        // dismiss
        imagePicker.dismiss(animated: true, completion: nil)
        if let pickedImage = info[.originalImage] as? UIImage {
            cameraView.contentMode = .scaleAspectFit
            cameraView.image = pickedImage
                
            photoPredict(pickedImage)
        }
    }
    
    
    // MARK: -- ここでVisionAPI(Resnet50)を叩く
    func photoPredict(_ targetPhoto: UIImage){
        // 学習モデルのインスタンス生成
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else{
            print("error model")
            return
        }
        // リクエスト
        let request = VNCoreMLRequest(model: model){ request, error in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            // 確率を整数にする
            let conf = Int(results[0].confidence * 100)
            // 候補の１番目
            let name = results[0].identifier
            if conf >= 50{
                self.label.text = "\(name) です。確率は\(conf)% \n"
            } else {
                self.label.text = "もしかしたら、\(name) かも。確率は\(conf)% \n"
            }
        }
            
        // 画像のリサイズ
        request.imageCropAndScaleOption = .centerCrop
        // CIImageに変換
        guard let ciImage = CIImage(image: targetPhoto) else {
            return
        }
        // 画像の向き
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(targetPhoto.imageOrientation.rawValue))!
        // ハンドラを実行
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        do{
            try handler.perform([request])
        }catch {
            print("error handler")
        }
    }

    // 撮影がキャンセルされた時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc func savePicture(_ sendar: UIButton){
        let image:UIImage! = cameraView.image
        if image != nil {
            UIImageWriteToSavedPhotosAlbum(image,
                                           self,
                                           #selector(ViewController.image(_:didFinishSavingWithError:contextInfo:)),
                                           nil)
        } else {
            label.text = "image Failed !"
        }
    }
    
    
    // 書き込み完了結果の受け取り
    @objc func image(_ image: UIImage,
                     didFinishSavingWithError error: NSError!,
                    contextInfo: UnsafeMutableRawPointer) {
        if error != nil {
            print(error.code)
            label.text = "Save Failed !"
        }else{
            label.text = "Save Succeeded"
        }
    }
    
    @objc func showAlbum(_ sendar: UIButton){
        let sourceType:UIImagePickerController.SourceType = UIImagePickerController.SourceType.photoLibrary
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            // インスタンスの作成
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
                    
            label.text = "Tap the [Start] to save a picture"
        }else{
            label.text = "error"
        }
    }
}

