//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

//
// ImageUtils
//

public extension CommonNetworking {
    enum ImageUtils {
        @PWThreadSafe static var _imagesCache = NSCache<NSString, UIImage>()
        public static var cachedImagesPrefix: String { "cached_image" }

        public enum StoragePolicy: Int {
            case none // Don't use storage
            case fileManager // Use cache, stored and persistent after app is closed (slow access)
            case memory // Use cache, persistent only while app is open (fast access)
        }

        public static func cleanCache() {
            _imagesCache.removeAllObjects()
            Common.ImagesFileManager.deleteAll(namePart: Self.cachedImagesPrefix)
        }

        public static func imageFrom(
            urlString: String,
            caching: StoragePolicy,
            downsample: CGSize?
        ) async throws -> UIImage? {
            let result: UIImage? = try await withCheckedThrowingContinuation { continuation in
                imageFrom(urlString: urlString, caching: caching, downsample: downsample) { image, _ in
                    continuation.resume(with: .success(image))
                }
            }
            return result
        }

        public static func imageFrom(
            urlString: String,
            caching: StoragePolicy,
            downsample: CGSize?,
            completion: @escaping ((UIImage?, String) -> Void)
        ) {
            guard let url = URL(string: urlString) else {
                DispatchQueue.executeInMainTread { completion(nil, "") }
                return
            }
            imageFrom(url: url, caching: caching, downsample: downsample) { image, url in
                completion(image, url)
            }
        }

        public static func imageFrom(
            urlString: String?,
            downsample: CGSize?,
            caching: StoragePolicy
        ) async throws -> UIImage? {
            guard let urlString else {
                return nil
            }
            let result: UIImage? = try await withCheckedThrowingContinuation { continuation in
                imageFrom(urlString: urlString, caching: caching, downsample: downsample) { image, _ in
                    continuation.resume(with: .success(image))
                }
            }
            return result
        }

        @discardableResult
        public static func imageFrom(
            url: URL?,
            caching: StoragePolicy,
            downsample: CGSize?,
            timeout: Double = 30,
            completion: @escaping ((UIImage?, String) -> Void)
        ) -> URLSessionDataTask? {
            guard let url = url else {
                DispatchQueue.executeInMainTread { completion(nil, url?.absoluteString ?? "") }
                return nil
            }
            let lock = Common.UnfairLockManagerWithKey()
            let lockEnabled = Bool.false
            let cachedImageName = "\(Self.cachedImagesPrefix)" + "_" + url.absoluteString.sha1 + ".png"
            func returnImage(_ image: UIImage?) {
                if let image {
                    switch caching {
                    case .none: ()
                    case .fileManager:
                        _ = Common.ImagesFileManager.saveImageWith(name: cachedImageName, image: image)
                    case .memory:
                        _imagesCache.setObject(image, forKey: cachedImageName as NSString)
                    }
                }
                autoreleasepool {
                    if let downsample,
                       downsample != .zero,
                       let image,
                       let imageDownSample = image.resizeToFitMaxSize(maxWidth: downsample.width, maxHeight: downsample.height) {
                        DispatchQueue.executeInMainTread { completion(imageDownSample, url.absoluteString) }
                    } else {
                        DispatchQueue.executeInMainTread { completion(image, url.absoluteString) }
                    }
                    if lockEnabled {
                        lock.unlock(key: cachedImageName)
                    }
                }
            }

            if lockEnabled {
                lock.lock(key: cachedImageName)
            }
            switch caching {
            case .none: ()
            case .fileManager:
                if let cachedImage = Common.ImagesFileManager.imageWith(name: cachedImageName).image {
                    returnImage(cachedImage)
                }
            case .memory:
                if let cachedImage = _imagesCache.object(forKey: cachedImageName as NSString) {
                    returnImage(cachedImage)
                }
            }
            guard Common_Utils.existsInternetConnection() else {
                returnImage(nil)
                return nil
            }

            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = timeout // Timeout for individual request (in seconds)
            config.timeoutIntervalForResource = timeout * 2 // Timeout for the entire resource load (in seconds)
            let session = URLSession(configuration: config)
            let task = session.dataTask(with: url) { data, _, error in
                let image = imageFromData(data: data)
                if let error = error as NSError? {
                    if error.domain == NSURLErrorDomain, error.code == NSURLErrorCannotFindHost {
                        Common_Logs.error("Fail do download image. Cannot find host. URL may be invalid: \(url)")
                    } else if error.localizedDescription != "cancelled" {
                        // Task canceled. Don't print error
                        Common_Logs.error("Fail do download image. Error: \(error.localizedDescription))")
                    }
                    returnImage(nil)
                } else if image == nil {
                    Common_Logs.error("Fail do download image. Image is nil: \(String(describing: url))")
                    returnImage(nil)
                } else {
                    returnImage(image)
                }
            }
            task.resume()
            return task
        }

        private static func imageFromData(data: Data?) -> UIImage? {
            guard let data = data else { return nil }
            var image = UIImage(data: data)
            if image == nil {
                // Failed? Maybe there is some encoding at start...
                if let dataAsText = String(data: data, encoding: .utf8)?
                    .dropFirstIf("data:image/webp;base64,")
                    .dropFirstIf("data:image/jpg;base64,"),
                    let newData = Data(base64Encoded: dataAsText), let newImage = UIImage(data: newData) {
                    // Recovered!
                    image = newImage
                }
            }
            return image
        }
    }
}
