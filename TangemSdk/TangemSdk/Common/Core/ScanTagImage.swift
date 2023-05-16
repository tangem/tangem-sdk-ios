//
//  ScanTagImage.swift
//  TangemSdk
//
//  Created by Andrey Chukavin on 16.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
public enum ScanTagImage {
    /// Generic card provided by the SDK
    case genericCard
    
    /// A custom tag made out of an UIImage instance.
    /// The image can be shifted vertically from the standard position by specifying `verticalOffset`.
    /// Note that the width of the image will be limited to a certain size, while the height will be determined by the aspect ratio of the image.
    /// The value of the width can be found in ReadView.swift and is 210 points at the time of the writing.
    case image(uiImage: UIImage, verticalOffset: Double)
}
