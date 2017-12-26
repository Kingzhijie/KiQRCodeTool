//
//  KiQRCodeViewController.swift
//  KiQRCodeTool
//
//  Created by mbApple on 2017/12/14.
//  Copyright © 2017年 panda誌. All rights reserved.
//

import UIKit
import AssetsLibrary
import Photos
import AVFoundation

class KiQRCodeViewController: UIViewController ,AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
//MARK: - Public
    public lazy var tipTitle: UILabel = { //扫码区域下方提示文字
        let tipTitle = UILabel()
        tipTitle.bounds = CGRect(x: 0, y: 0, width: 300, height: 50)
        tipTitle.center = CGPoint(x: self.view.frame.width / 2, y: self.view.center.y + self.view.frame.size.width/2 - 35)
        tipTitle.font = UIFont.systemFont(ofSize: 13)
        tipTitle.textAlignment = .center
        tipTitle.numberOfLines = 0
        tipTitle.text = "将取景框对准二维码,即可自动扫描"
        tipTitle.textColor = .white
        return tipTitle
    }()
    public lazy var toolsView: UIView = { //底部显示的功能项 -box
        let toolsView = UIView(frame: CGRect(x: 0, y: self.view.frame.maxY - 64, width: self.view.frame.width, height: 64))
        toolsView.backgroundColor = UIColor.init(red: 0.212, green: 0.208, blue: 0.231, alpha: 1.0)
        return toolsView
    }()
    public lazy var photoBtn: UIButton = { //相册按钮
        let photoBtn = UIButton()
        return photoBtn
    }()
    public lazy var flashBtn: UIButton = { //闪光灯按钮
        let flashBtn = UIButton()
        return flashBtn
    }()

    
    /// 初始化二维码扫描控制器
    ///
    /// - Parameters:
    ///   - QrType: 扫码类型
    ///   - finish: 扫码完成回调
    init(QrType:KiQRCodeType,finish:@escaping (_ result:String,_ error:Error?)->Void) {
        self.scanFinish = finish
        self.scanType = QrType
        super.init(nibName: nil, bundle: nil)
    }
    
    /// 识别二维码
    ///
    /// - Parameters:
    ///   - image: UIImage对象
    ///   - finish: 识别结果
   class func recognizeQrCodeImage(image:UIImage,finish:@escaping (_ result:String)->Void) {
        if UIDevice.current.systemVersion.compare("8.0").rawValue == 1 {
            finish("只支持iOS8.0以上系统")
        }else{
            let context = CIContext.init(options: nil)
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
            let features = detector?.features(in: CIImage.init(cgImage: image.cgImage!))
            if Int(features?.count ?? 0) >= 1 {
                let feature = features![0] as! CIQRCodeFeature
                let scanResult = feature.messageString
                finish(scanResult ?? "")
            }else{
                finish("未识别到二维码")
            }
        }
    }
    
    /// 生成二维码【自定义颜色】
    ///
    /// - Parameters:
    ///   - content: 二维码内容字符串【数字、字符、链接等
    ///   - size: 生成图片的大小
    ///   - qrColor: 二维码颜色
    ///   - bkColor: 背景色
    /// - Returns: 二维码UIImage图片对象
    class func createQRImageWithString(content:String,size:CGSize,qrColor:UIColor,bkColor:UIColor) -> UIImage {
        let stringData = content.data(using: String.Encoding.utf8)
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        qrFilter?.setValue(stringData, forKey: "inputMessage")
        qrFilter?.setValue("H", forKey: "inputCorrectionLevel")
        let colorFilter = CIFilter(name: "CIFalseColor", withInputParameters: ["inputImage":qrFilter?.outputImage as Any,"inputColor0":CIColor(cgColor: qrColor.cgColor),"inputColor1":CIColor(cgColor: bkColor.cgColor)])
        let qrImage = colorFilter?.outputImage ?? CIImage()
        let cgImage = CIContext(options: nil).createCGImage(qrImage, from: qrImage.extent)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.interpolationQuality = .none
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(cgImage!, in: (context?.boundingBoxOfClipPath)!)
        let codeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return codeImage!
    }
    
    /// 生成条形码【自定义颜色】
    ///
    /// - Parameters:
    ///   - content: 条码内容【一般是数字】
    ///   - size: 生成条码图片的大小
    ///   - qrColor: 码颜色
    ///   - bkColor: 背景颜色
    /// - Returns: UIImage图片对象
    class func createBarCodeImageWithString(content:String,size:CGSize,qrColor:UIColor,bkColor:UIColor) -> UIImage {
        let stringData = content.data(using: String.Encoding.utf8)
        let qrFilter = CIFilter(name: "CICode128BarcodeGenerator")
        qrFilter?.setValue(stringData, forKey: "inputMessage")
        //上色
        let colorFilter = CIFilter(name: "CIFalseColor", withInputParameters: ["inputImage":qrFilter?.outputImage as Any,"inputColor0":CIColor(cgColor: qrColor.cgColor),"inputColor1":CIColor(cgColor: bkColor.cgColor)])
        let qrImage = colorFilter?.outputImage ?? CIImage()
        let cgImage = CIContext(options: nil).createCGImage(qrImage, from: qrImage.extent)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.interpolationQuality = .none
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(cgImage!, in: (context?.boundingBoxOfClipPath)!)
        let codeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return codeImage!
    }
    
   
//MARK: - Private
    fileprivate var scanRectView = KiQRCodeView()
    fileprivate var device:AVCaptureDevice?
    fileprivate var input:AVCaptureDeviceInput?
    fileprivate var output = AVCaptureMetadataOutput() //初始化摄像输出流
    fileprivate var session = AVCaptureSession() //初始化链接对象
    fileprivate var preview:AVCaptureVideoPreviewLayer?
    fileprivate var scanRect = CGRect()
    fileprivate var scanFinish:(_ result:String,_ error:Error?)->Void
    fileprivate var scanType:KiQRCodeType?
    fileprivate var appName:String?
    fileprivate var delayQRAction = true
    fileprivate var delayBarAction = false
    fileprivate lazy var scanTypeQrBtn: UIButton = { //修改扫码类型按钮
        let size = CGSize(width: UIScreen.main.bounds.size.width / 2, height: 64)
        let scanTypeQrBtn = UIButton(type: .custom)
        scanTypeQrBtn.frame = CGRect(x: 0, y: 0, width:size.width , height: size.height)
        scanTypeQrBtn.setTitle("二维码", for: .normal)
        scanTypeQrBtn.setTitleColor(UIColor.init(red: 0.165, green: 0.663, blue: 0.886, alpha: 1.0), for: .selected)
        scanTypeQrBtn.setTitleColor(.white, for: .normal)
        scanTypeQrBtn.setImage(UIImage.init(named: "scan_qr_normal"), for: .normal)
        scanTypeQrBtn.setImage(UIImage.init(named: "scan_qr_select"), for: .selected)
        scanTypeQrBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
        scanTypeQrBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scanTypeQrBtn.isSelected = true
        scanTypeQrBtn.addTarget(self, action: #selector(qrBtnClicked(btn:)), for: .touchUpInside)
        return scanTypeQrBtn
    }()
    fileprivate lazy var scanTypeBarBtn: UIButton = { //修改扫码类型按钮
        let size = CGSize(width: UIScreen.main.bounds.size.width / 2, height: 64)
        let scanTypeQrBtn = UIButton(type: .custom)
        scanTypeQrBtn.frame = CGRect(x: size.width, y: 0, width:size.width , height: size.height)
        scanTypeQrBtn.setTitle("条形码", for: .normal)
        scanTypeQrBtn.setTitleColor(UIColor.init(red: 0.165, green: 0.663, blue: 0.886, alpha: 1.0), for: .selected)
        scanTypeQrBtn.setTitleColor(.white, for: .normal)
        scanTypeQrBtn.setImage(UIImage.init(named: "scan_bar_normal"), for: .normal)
        scanTypeQrBtn.setImage(UIImage.init(named: "scan_bar_select"), for: .selected)
        scanTypeQrBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
        scanTypeQrBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scanTypeQrBtn.isSelected = false
        scanTypeQrBtn.addTarget(self, action: #selector(barBtnClicked(btn:)), for: .touchUpInside)
        return scanTypeQrBtn
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "二维码"
        self.view.backgroundColor = .black
        
        appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        
        if isAvailableCamera() == false {
            showSheet(vc: self, title: "无法获取相机权限", message: "是否从相册中获取图片")
        }else{
            initScanDevide() //获取设备摄像头权限
            drawTitle()
            drawScanView() //绘制扫描区域
            initScanType()
        }
        setNavItem(type: self.scanType!)
        // Do any additional setup after loading the view.
    }
    
    //MARK: -点击二维码按钮
    @objc private func qrBtnClicked(btn:UIButton) {
        if delayQRAction {
            return
        }
        btn.isSelected = !btn.isSelected
        scanTypeBarBtn.isSelected = false
        changeScanCodeType(tyep: .QRCode)
        setNavItem(type: .QRCode)
        delayQRAction = true
        delayBarAction = true
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {[weak self] in
            self?.delayBarAction = false
        }
    }
    //MARK: -点击条形码按钮
    @objc private func barBtnClicked(btn:UIButton) {
        if delayBarAction {
            return
        }
        btn.isSelected = !btn.isSelected
        scanTypeQrBtn.isSelected = false
        self.scanRectView.stopAnimating()
        changeScanCodeType(tyep: .BarCode)
        setNavItem(type: .BarCode)
        delayQRAction = true
        delayBarAction = true
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {[weak self] in
            self?.delayQRAction = false
        }
    }
    
    private func setNavItem(type:KiQRCodeType) {
        if type == .BarCode {
            navigationItem.rightBarButtonItem = nil
        }else{
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "相册", style: .plain, target: self, action: #selector(openPhoto))
        }
    }
    //打开相册
    @objc private func openPhoto() {
        if isAvailablePhoto() == false {
            let tipMessage = "是否前往手机系统的\n【设置】->【隐私】->【相机】\n对\(appName!)开启相机的访问权限"
            showSheet(vc: self, title: "", message: tipMessage)
        }else{
            openPhotoLibrary()
        }
    }
    
    //MARK: - 修改扫码类型 【二维码  || 条形码】
    private func changeScanCodeType(tyep:KiQRCodeType) {
        session.stopRunning()
        var scanSize = CGSizeFromString(scanRectWithScale(scale: 1)[1] as! String)
        if tyep == .BarCode {
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.ean13,AVMetadataObject.ObjectType.ean8,AVMetadataObject.ObjectType.code128]
            self.title = "条形码"
            scanRect = CGRectFromString(scanRectWithScale(scale: 3)[0] as! String)
            scanSize = CGSizeFromString(scanRectWithScale(scale: 3)[1] as! String)
        }else{
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            self.title = "二维码"
            scanRect = CGRectFromString(scanRectWithScale(scale: 1)[0] as! String)
            scanSize = CGSizeFromString(scanRectWithScale(scale: 1)[1] as! String)
        }
        
        DispatchQueue.main.async {[weak self] in
            self?.output.rectOfInterest = (self?.scanRect)!
            self?.scanRectView.codeType = tyep
            self?.tipTitle.text = tyep == .QRCode ? "将取景框对准二维码,即可自动扫描" : "将取景框对准条码,即可自动扫描"
            self?.session.startRunning()
        }
        UIView.animate(withDuration: 0.3) {[weak self] in
            self?.tipTitle.center = CGPoint(x: (self?.view.center.x)!, y: (self?.view.center.y)! + scanSize.height/2 + 25)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         //开始捕获
        session.startRunning()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    deinit {
        session.stopRunning()
        print("销毁")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

extension KiQRCodeViewController{
    //MARK: - 获取设备摄像头权限,及信息
    fileprivate func initScanDevide() {
        if isAvailableCamera() {
            //初始化摄像设备
            self.device = AVCaptureDevice.default(for: .video)
            do{
                //初始化摄像输入流
                self.input = try AVCaptureDeviceInput.init(device: self.device!)
            } catch{}
            //设置输出代理，在主线程里刷新
            self.output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            self.session.sessionPreset = AVCaptureSession.Preset.inputPriority
            //将输入输出流对象添加到链接对象
            if input != nil{
                if self.session.canAddInput(self.input!){
                    session.addInput(input!)
                }
            }
            if session.canAddOutput(output){
                session.addOutput(output)
            }
            
            //设置扫码支持的编码格式【默认二维码】
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            //设置扫描聚焦区域
            output.rectOfInterest = scanRect
            
            preview = AVCaptureVideoPreviewLayer(session: session)
            preview?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            preview?.frame = UIScreen.main.bounds
            self.view.layer.insertSublayer(preview!, at: 0)
        }
    }
   
    
    fileprivate func drawTitle(){
        self.view.addSubview(self.tipTitle)
        tipTitle.layer.zPosition = 1
        self.view.bringSubview(toFront: tipTitle)
    }
    //绘制扫描区域
    fileprivate func drawScanView(){
        scanRectView = KiQRCodeView(frame: self.view.frame)
        scanRectView.codeType = self.scanType!
        self.view.addSubview(scanRectView)
    }
    
    fileprivate func initScanType(){
        if self.scanType == .All {
            scanRect = CGRectFromString(scanRectWithScale(scale: 1)[0] as! String)
            output.rectOfInterest = scanRect
            drawBottomItems()
        }else if scanType == .QRCode{ //二维码
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            self.title = "二维码"
            scanRect = CGRectFromString(scanRectWithScale(scale: 1)[0] as! String)
            output.rectOfInterest = scanRect
            tipTitle.text = "将取景框对准二维码,即可自动扫描"
            let h = CGSizeFromString((scanRectWithScale(scale: 1)[1] as! String)).height / 2
            tipTitle.center = CGPoint(x: self.view.center.x, y: self.view.center.y + h + 25)
        }else if scanType == .BarCode{ //条形码
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.ean13,AVMetadataObject.ObjectType.ean8,AVMetadataObject.ObjectType.code128]
            self.title = "条形码"
            scanRect = CGRectFromString(scanRectWithScale(scale: 3)[0] as! String)
            output.rectOfInterest = scanRect
            scanRectView.codeType = .BarCode
            tipTitle.text = "将取景框对准条码,即可自动扫描"
            let h = CGSizeFromString((scanRectWithScale(scale: 3)[1] as! String)).height / 2
            tipTitle.center = CGPoint(x: self.view.center.x, y: self.view.center.y + h + 25)
        }
    }
    
    fileprivate func scanRectWithScale(scale:CGFloat) -> Array<Any>{
        let windowSize = UIScreen.main.bounds.size
        let left:CGFloat = 60 / scale
        let scanSize = CGSize(width: self.view.frame.size.width - left * 2, height: (self.view.frame.size.width - left * 2) / scale)
        var scanRect = CGRect(x: (windowSize.width-scanSize.width)/2, y: (windowSize.height-scanSize.height)/2, width: scanSize.width, height: scanSize.height)
        scanRect = CGRect(x: scanRect.origin.y/windowSize.height, y: scanRect.origin.x/windowSize.width, width: scanRect.size.height/windowSize.height, height: scanRect.size.width/windowSize.width)
        return [NSStringFromCGRect(scanRect),NSStringFromCGSize(scanSize)]
    }
    
    fileprivate func drawBottomItems(){
        self.view.addSubview(self.toolsView)
        self.toolsView.addSubview(self.scanTypeQrBtn)
        self.toolsView.addSubview(self.scanTypeBarBtn)
    }

}
extension KiQRCodeViewController {
    //MARK: - 获取相机相册权限, 读取相册中图片, 获得扫描结果
    // 相册是否可用
    fileprivate func isAvailablePhoto() -> Bool {
        let authorStatus = PHPhotoLibrary.authorizationStatus()
        if authorStatus == .denied {
            return false
        }
        return true
    }
    //相机是否可用
    fileprivate func isAvailableCamera() -> Bool{
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if authorizationStatus == .restricted || authorizationStatus == .denied{
                return false
            }else{
                self.view.isUserInteractionEnabled = true
                return true
            }
        }else{
            //相机硬件不可用【一般是模拟器】
            return false
        }
    }
    // 获取相册图片
    fileprivate func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    //MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        KiQRCodeViewController.recognizeQrCodeImage(image: image, finish: {[weak self] (result) in
            self?.renderUrlStr(url: result)
        })
        
    }
    
    fileprivate func showSheet(vc:UIViewController,title:String,message:String) {
        let action = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionCancle = UIAlertAction(title: "否", style: .cancel, handler: {[weak self] (action) in
            self?.navigationController?.popViewController(animated: true)
        })
        let actionPhone = UIAlertAction(title:"是", style: .default, handler: {[weak self] (action) in
            self?.openPhoto()
        })
        action.addAction(actionCancle)
        action.addAction(actionPhone)
        vc.present(action, animated: true, completion: nil)
    }
}

extension KiQRCodeViewController{
    //MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        if metadataObjects.count == 0 {
            renderUrlStr(url: "图片中未识别到二维码")
            return
        }
        if metadataObjects.count > 0 {
            session.stopRunning()
            let metadataObject = metadataObjects.first as! AVMetadataMachineReadableCodeObject
            renderUrlStr(url: String(format: "%@", metadataObject.stringValue ?? ""))
        }
    }
    //输出扫描字符串
    fileprivate func renderUrlStr(url:String) {
        self.scanFinish(url,nil)
        self.navigationController?.popViewController(animated: true)
    }
}
