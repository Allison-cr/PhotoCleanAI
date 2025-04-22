//
//  EmbeddingExtractor.swift
//  PhotoClean AI
//
//  Created by Alexander Suprun on 19.04.2025.
//

import SwiftUI
import UIKit
import Vision
import CoreML

final class EmbeddingExtractor {
    private let model: VNCoreMLModel

    init?() {
        guard let coreMLModel = try? EmbeddingModel(configuration: MLModelConfiguration()).model,
              let visionModel = try? VNCoreMLModel(for: coreMLModel) else {
            return nil
        }
        self.model = visionModel
    }

    func extractFeatures(from image: UIImage, completion: @escaping ([Double]?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNCoreMLRequest(model: model) { request, _ in
            guard let result = request.results?.first as? VNCoreMLFeatureValueObservation,
                  let multiArray = result.featureValue.multiArrayValue else {
                completion(nil)
                return
            }

            let floatPointer = UnsafeMutablePointer<Float32>(OpaquePointer(multiArray.dataPointer))
            let floatBuffer = UnsafeBufferPointer(start: floatPointer, count: multiArray.count)
            let vector = floatBuffer.map { Double($0) }
            completion(vector)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
}
