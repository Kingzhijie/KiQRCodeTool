# KiQRCodeTool
    ###二维码条形码扫描及生成工具
    ######/// 初始化二维码扫描控制器
    ///
    /// - Parameters:
    ///   - QrType: 扫码类型<支持二维码,条形码>
    ///   - finish: 扫码完成回调
    init(QrType:KiQRCodeType,finish:@escaping (_ result:String,_ error:Error?)->Void)
    ######/// 生成二维码【自定义颜色】
    ///
    /// - Parameters:
    ///   - content: 二维码内容字符串【数字、字符、链接等
    ///   - size: 生成图片的大小
    ///   - qrColor: 二维码颜色
    ///   - bkColor: 背景色
    /// - Returns: 二维码UIImage图片对象
    class func createQRImageWithString(content:String,size:CGSize,qrColor:UIColor,bkColor:UIColor) -> UIImage
    ###### /// 生成条形码【自定义颜色】
    ///
    /// - Parameters:
    ///   - content: 条码内容【一般是数字】
    ///   - size: 生成条码图片的大小
    ///   - qrColor: 码颜色
    ///   - bkColor: 背景颜色
    /// - Returns: UIImage图片对象
    class func createBarCodeImageWithString(content:String,size:CGSize,qrColor:UIColor,bkColor:UIColor) -> UIImage
