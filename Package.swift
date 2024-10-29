// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TesseractOCR",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TesseractOCR",
            targets: ["TesseractOCR", "Tesseract", "Leptonica", "JPEG", "PNG", "TIFF"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "TesseractOCR",
            path: "TesseractOCR/xcframework/TesseractOCR.xcframework"
        ),
        .binaryTarget(
            name: "Tesseract",
            path: "TesseractOCR/xcframework/Tesseract.xcframework"
        ),
        .binaryTarget(
            name: "Leptonica",
            path: "TesseractOCR/xcframework/Leptonica.xcframework"
        ),
        .binaryTarget(
            name: "JPEG",
            path: "TesseractOCR/xcframework/JPEG.xcframework"
        ),
        .binaryTarget(
            name: "PNG",
            path: "TesseractOCR/xcframework/PNG.xcframework"
        ),
        .binaryTarget(
            name: "TIFF",
            path: "TesseractOCR/xcframework/TIFF.xcframework"
        )
    ]
)
