//
//  ContentView.swift
//  CLIPKit Demo
//
//  Created by Runkai Zhang on 7/26/23.
//

import SwiftUI
import CLIPKit
import PhotosUI
import CoreML

struct ImageEmbed {
    var embeds: MLShapedArray<Float32>
    var image: UIImage
    
    var scalars: [Float] {
        embeds.scalars
    }
}

extension ImageEmbed: Hashable {
    static func == (lhs: ImageEmbed, rhs: ImageEmbed) -> Bool {
        return lhs.embeds == rhs.embeds && lhs.image == rhs.image
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(image)
    }
}

struct TextEmbed {
    var embeds: MLShapedArray<Float32>
    var text: String
    
    var scalars: [Float] {
        embeds.scalars
    }
}

extension TextEmbed: Hashable {
    static func == (lhs: TextEmbed, rhs: TextEmbed) -> Bool {
        return lhs.embeds == rhs.embeds && lhs.text == rhs.text
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
    }
}

struct ContentView: View {
    let kit = CLIPKit()
    
    @State private var imageModelLoaded = false
    @State private var textModelLoaded = false
    @State private var isLoadingImageModel = false
    @State private var isLoadingTextModel = false
    
    @State private var isPhotoPickerOn = false
    
    @State private var selectedEncoder = "Image Encoder"
    private let encoders = ["Image Encoder", "Text Encoder"]
    
    @State private var isEncodingImage = false
    @State private var isEncodingText = false
    
    @State private var displayedImage: UIImage?
    
    @State private var image: PhotosPickerItem?
    @State private var text = ""
    
    @State private var imageEmbeds: [ImageEmbed] = []
    @State private var textEmbeds: [TextEmbed] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Setup") {
                    Button(
                        action: {
                            isLoadingImageModel = true
                            Task(priority: .userInitiated) {
                                let loadImageEncoder = await kit.loadImageEncoder(path: "\(Bundle.main.bundlePath)/ImageEncoder_float32.mlmodelc")
                                imageModelLoaded = loadImageEncoder
                                isLoadingImageModel = false
                            }
                        },
                        label: {
                            Text("Load Image Encoder")
                                .frame(maxWidth: .infinity, alignment: .leading) //frame to infinity inside label will apply the button click area to the whole stack
                        }).disabled(isLoadingImageModel || imageModelLoaded)
                    
                    if isLoadingImageModel {
                        loadingIndicator()
                    } else if imageModelLoaded {
                        Text("Image Encoder successfully loaded")
                    }
                    
                    Button(
                        action: {
                            isLoadingTextModel = true
                            Task(priority: .userInitiated) {
                                let loadTextEncoder = await kit.loadTextEncoder(path: "\(Bundle.main.bundlePath)/TextEncoder_float32.mlmodelc")
                                textModelLoaded = loadTextEncoder
                                isLoadingTextModel = false
                            }
                        },
                        label: {
                            Text("Load Text Encoder")
                                .frame(maxWidth: .infinity, alignment: .leading) //frame to infinity inside label will apply the button click area to the whole stack
                        }).disabled(isLoadingTextModel || textModelLoaded)
                    
                    if isLoadingTextModel {
                        loadingIndicator()
                    } else if textModelLoaded {
                        Text("Text Encoder successfully loaded")
                    }
                }.buttonStyle(.borderless)
                
                Section {
                    Picker("Encoder", selection: $selectedEncoder) {
                        ForEach(encoders, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if selectedEncoder == "Image Encoder" {
                    if imageModelLoaded {
                        Section("Image Encoder") {
                            if displayedImage == nil {
                                PhotosPicker("Select image", selection: $image, matching: .images)
                            } else {
                                Button {
                                    isPhotoPickerOn.toggle()
                                } label: {
                                    Image(uiImage: displayedImage!)
                                        .resizable()
                                        .scaledToFit()
                                }
                                .photosPicker(isPresented: $isPhotoPickerOn, selection: $image, matching: .images)
                            }
                            
                            HStack {
                                Button(
                                    action: {
                                        isEncodingImage = true
                                        Task(priority: .userInitiated) {
                                            do {
                                                if let data = try? await image?.loadTransferable(type: Data.self) {
                                                    if let uiImage = UIImage(data: data) {
                                                        let desiredSize = CGSize(width: 224, height: 224)
                                                        let resized = try uiImage.resizeImageTo(size: desiredSize)
                                                        let embedded = try await kit.imageEncoder?.encode(image: (resized?.cgImage!)!, desiredSize: desiredSize)
                                                        let object = ImageEmbed(embeds: embedded!, image: uiImage)
                                                        
                                                        imageEmbeds.append(object)
                                                    }
                                                }
                                                
                                                isEncodingImage = false
                                            } catch {
                                                print(error)
                                            }
                                        }
                                    },
                                    label: {
                                        Text("Encode Image")
                                            .frame(maxWidth: .infinity, alignment: .leading) //frame to infinity inside label will apply the button click area to the whole stack
                                    }).disabled(image == nil || isEncodingImage)
                            }
                        }
                        .onChange(of: image) {
                            Task {
                                if let data = try? await image?.loadTransferable(type: Data.self) {
                                    if let uiImage = UIImage(data: data) {
                                        displayedImage = uiImage
                                        return
                                    }
                                }
                                
                                print("Failed")
                            }
                        }
                    } else {
                        Text("Image Encoder Model not loaded!")
                    }
                }
                
                if selectedEncoder == "Text Encoder" {
                    if textModelLoaded {
                        Section("Text Encoder") {
                            TextField("Enter some words", text: $text, prompt: Text("Enter some words"))
                            HStack {
                                Button(
                                    action: {
                                        isEncodingText = true
                                        Task(priority: .userInitiated) {
                                            do {
                                                let embedded = try kit.textEncoder?.encode(text)
                                                let object = TextEmbed(embeds: embedded!, text: text)
                                                print(embedded!)
                                                
                                                textEmbeds.append(object)
                                            } catch {
                                                print(error)
                                            }
                                            
                                            isEncodingText = false
                                        }
                                    },
                                    label: {
                                        Text("Encode Text")
                                            .frame(maxWidth: .infinity, alignment: .leading) //frame to infinity inside label will apply the button click area to the whole stack
                                    }).disabled(text.isEmpty || isEncodingText)
                            }
                        }
                    } else {
                        Text("Text Encoder Model not loaded!")
                    }
                }
                
                if !imageEmbeds.isEmpty && textEmbeds.count > 1 {
                    NavigationLink("Calculate Distances") {
                        CalculateView(kit: kit, imageEmbeds: imageEmbeds, textEmbeds: textEmbeds, selectedImageEmbedded: imageEmbeds.first!, selectedTextEmbedded: textEmbeds.first!)
                    }
                }
            }
        }
    }
    
    private func loadingIndicator() -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .frame(width: 25, height: 25)
    }
}

extension UIImage {
    
    func resizeImageTo(size: CGSize) throws -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
     func convertToBuffer() -> CVPixelBuffer? {
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(self.size.width),
            Int(self.size.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer)
        
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: pixelData,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    static func image(with size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size)
            .image { $0.fill(CGRect(origin: .zero, size: size)) }
    }
}

#Preview {
    ContentView()
}
