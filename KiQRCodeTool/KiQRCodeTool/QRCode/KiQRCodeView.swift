//
//  KiQRCodeView.swift
//  KiQRCodeTool
//
//  Created by mbApple on 2017/12/14.
//  Copyright © 2017年 panda誌. All rights reserved.
//

import UIKit
enum KiQRCodeType { //扫描类型
    case QRCode  //二维码
    case BarCode //条形码
    case All  //都支持
}
class KiQRCodeView: UIView {
    
//MARK: - Public
    public var codeType:KiQRCodeType = .QRCode{   //默认二维码
        didSet{
            if codeType == .BarCode{  //条形码
                heightScale = 3
                lineImageView.alpha = 0
            }else{
                heightScale = 1
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {[weak self] in
                   self?.needStop = false
                   self?.startAnimating()
                }
            }
            self.setNeedsDisplay()
            self.setNeedsLayout()
        }
    }
    override init(frame:CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.lineImageView = UIImageView(image: UIImage.init(named: "scan_blue_line"))
    }
    public func stopAnimating(){
        needStop = true
    }
    
    
//MARK: - Private
    private let LeftDistance:CGFloat = 60  //左边界
    private var heightScale:CGFloat = 1 //默认二维码, 宽高比为1
    private var lineImageView = UIImageView()
    private var needStop = false //默认
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let left = LeftDistance / heightScale
        let sizeRetangle = CGSize(width: self.frame.size.width - left * 2, height: self.frame.size.width - left * 2)
        let YMinRetangle = self.frame.size.height / 2 - sizeRetangle.height / (2 * heightScale)
        lineImageView.frame = CGRect(x: left, y: YMinRetangle + 2, width: sizeRetangle.width - 4, height: 5)
        self.addSubview(lineImageView)
    }
    
    @objc private func startAnimating() {
        if needStop == true {
            return
        }
        
        let left = LeftDistance / heightScale
        let sizeRetangle = CGSize(width: self.frame.size.width - left * 2, height: (self.frame.size.width - left * 2)/heightScale)
        let YMinRetangle = self.frame.size.height / 2 - sizeRetangle.height / 2
        let YMaxRetangle = YMinRetangle + sizeRetangle.height
        let initFrame = CGRect(x: left, y: YMinRetangle + 2, width: sizeRetangle.width - 4, height: 5)
        lineImageView.frame = initFrame
        lineImageView.alpha = 1
        UIView.animate(withDuration: 1.5, animations: {[weak self] in
            self?.lineImageView.frame = CGRect(x: initFrame.origin.x, y: YMaxRetangle - 2, width: initFrame.size.width, height: initFrame.size.height)
        }, completion: {[weak self] (finish) in
            self?.lineImageView.alpha = 0
            self?.lineImageView.frame = initFrame
            self?.perform(#selector(self?.startAnimating), with: nil, afterDelay: 0.3)
        })
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawScanRect()
    }
    
    private func drawScanRect() {
        // 扫描区域Y轴最小坐标
        let left = LeftDistance / heightScale
        let sizeRetangle = CGSize(width: self.frame.size.width - left * 2, height:self.frame.size.width - left * 2)
        let YMinRetangle = self.frame.size.height / 2 - sizeRetangle.height / (2*heightScale)
        let YMaxRetangle = YMinRetangle + sizeRetangle.height / heightScale
        let XRetangleRight = self.frame.size.width - left
        let context = UIGraphicsGetCurrentContext()
        //非扫码区域半透明
        //设置非识别区域颜色
        context?.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        //扫码区域上面填充
        var rect = CGRect(x: 0, y: 0, width: self.frame.size.width, height: YMinRetangle)
        context?.fill(rect)
        //扫码区域左边填充
        rect = CGRect(x: 0, y: YMinRetangle, width: left, height: sizeRetangle.height/heightScale)
        context?.fill(rect)
        
        //扫码区域右边填充
        rect = CGRect(x: XRetangleRight, y: YMinRetangle, width: left, height: sizeRetangle.height/heightScale)
        context?.fill(rect)
    
        //扫码区域下面填充
        rect = CGRect(x: 0, y: YMaxRetangle, width: self.frame.size.width, height: self.frame.size.height - YMaxRetangle)
        context?.fill(rect)

        //执行绘画
        context?.strokePath()
        
        //中间画矩形(正方形)
        context?.setStrokeColor(UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor)
        context?.setLineWidth(1)
        context?.addRect(CGRect(x: left, y: YMinRetangle, width: sizeRetangle.width, height: sizeRetangle.height / heightScale))
        context?.strokePath()
        
        //画矩形框4格外围相框角
        //相框角的宽度和高度
        let wAngle:CGFloat = 15
        let hAngle:CGFloat = 15
         //4个角的 线的宽度
        let linewidthAngle:CGFloat = 4 // 经验参数：6和4
         //画扫码矩形以及周边半透明黑色坐标参数
        let diffAngle = linewidthAngle / 3
        //diffAngle = linewidthAngle / 2; //框外面4个角，与框有缝隙
        //diffAngle = linewidthAngle/2;  //框4个角 在线上加4个角效果
        //diffAngle = 0;//与矩形框重合
        
        context?.setStrokeColor(UIColor.init(red: 0.11, green: 0.659, blue: 0.894, alpha: 1.0).cgColor)
        context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context?.setLineWidth(linewidthAngle)
        
        let leftX = left - diffAngle
        let topY = YMinRetangle - diffAngle
        let rightX = XRetangleRight + diffAngle
        let bottomY = YMaxRetangle + diffAngle
        
        //左上角水平线
        context?.move(to: CGPoint(x: leftX - linewidthAngle/2, y: topY))
        context?.addLine(to: CGPoint(x: leftX + wAngle, y: topY))
        
        //左上角垂直线
        context?.move(to: CGPoint(x: leftX, y: topY-linewidthAngle/2))
        context?.addLine(to: CGPoint(x: leftX, y: topY+hAngle))
        
        //左下角水平线
        context?.move(to: CGPoint(x: leftX - linewidthAngle/2, y: bottomY))
        context?.addLine(to: CGPoint(x: leftX + wAngle, y: bottomY))
        
        //左下角垂直线
        context?.move(to: CGPoint(x: leftX, y: bottomY+linewidthAngle/2))
        context?.addLine(to: CGPoint(x: leftX, y: bottomY - hAngle))
        
        //右上角水平线
        context?.move(to: CGPoint(x: rightX+linewidthAngle/2, y: topY))
        context?.addLine(to: CGPoint(x: rightX - wAngle, y: topY))
        
        //右上角垂直线
        context?.move(to: CGPoint(x: rightX, y: topY-linewidthAngle/2))
        context?.addLine(to: CGPoint(x: rightX, y: topY + hAngle))
        
        //右下角水平线
        context?.move(to: CGPoint(x: rightX+linewidthAngle/2, y: bottomY))
        context?.addLine(to: CGPoint(x: rightX - wAngle, y: bottomY))
        
        //右下角垂直线
        context?.move(to: CGPoint(x: rightX, y: bottomY+linewidthAngle/2))
        context?.addLine(to: CGPoint(x: rightX, y: bottomY - hAngle))
        
        context?.strokePath()
        
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
