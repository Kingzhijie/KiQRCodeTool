//
//  ViewController.swift
//  KiQRCodeTool
//
//  Created by mbApple on 2017/12/14.
//  Copyright © 2017年 panda誌. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var contentlabel = UILabel()
    var QRImage = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = .white
        
        let btn = UIButton(type: .custom)
        btn.frame = CGRect(x: 20, y: 100, width: 100, height: 60)
        btn.backgroundColor = .red
        btn.setTitle("扫一扫", for: .normal)
        self.view.addSubview(btn)
        btn.addTarget(self, action: #selector(btnAction), for: .touchUpInside)
        
        contentlabel = UILabel(frame: CGRect(x: 0, y: 200, width: 375, height: 60))
        contentlabel.numberOfLines = 0
        self.view.addSubview(contentlabel)
        
        
        let btn1 = UIButton(type: .custom)
        btn1.frame = CGRect(x: 20, y: 300, width: 100, height: 60)
        btn1.backgroundColor = .red
        btn1.setTitle("二维码生成", for: .normal)
        self.view.addSubview(btn1)
        btn1.addTarget(self, action: #selector(QrAction), for: .touchUpInside)
        
        QRImage = UIImageView(frame: CGRect(x: 20, y: 370, width: 250, height: 250))
        QRImage.contentMode = .scaleAspectFit
        self.view.addSubview(QRImage)
        
    }
    
    @objc func btnAction()  {
        
        let QrCodeVc = KiQRCodeViewController(QrType: .All, finish: {[weak self] (result, error) in
            if error == nil{
                print("扫描结果: \(result)")
                self?.contentlabel.text = "扫描结果: \(result)"
            }
        })
        self.navigationController?.pushViewController(QrCodeVc, animated: true)
        
    }
    
    @objc func QrAction()  {
        // 生成 二维码
        let image = KiQRCodeViewController.createQRImageWithString(content: "http://www.baidu.com", size: CGSize(width: 250, height: 250), qrColor: .red, bkColor: .white)
        QRImage.image = image
        
//        //生成条形码
//        let image = KiQRCodeViewController.createBarCodeImageWithString(content: "454515111212", size: CGSize(width: 300, height: 60), qrColor: .red, bkColor: .white)
//        QRImage.image = image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

