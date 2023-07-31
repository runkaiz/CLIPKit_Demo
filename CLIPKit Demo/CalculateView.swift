//
//  CalculateView.swift
//  CLIPKit Demo
//
//  Created by Runkai Zhang on 7/28/23.
//

import SwiftUI
import CoreML
import CLIPKit

struct CalculateView: View {
    
    @State var kit: CLIPKit
    @State var imageEmbeds: [ImageEmbed]
    @State var textEmbeds: [TextEmbed]
    
    @State var selectedImageEmbedded: ImageEmbed
    @State var selectedTextEmbedded: TextEmbed
    
    @State var result = ""
    
    var body: some View {
        Form  {
            Section {
                Text(result)
            }
            .onAppear {
                calc()
            }
        }
    }
    
    private func calc() {
        result = "Calculating"
        
        var texts: [[Float]] = []
        for textEmbed in textEmbeds {
            texts.append(textEmbed.scalars)
        }
        
        kit.performNearestNeighbor(subject: imageEmbeds.first!.scalars, targets: texts)
    }
}
