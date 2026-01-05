import Flutter
import UIKit
import Photos


@available(iOS 14, *)
public class MultMediaPickerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mult_media_picker", binaryMessenger: registrar.messenger())
    let instance = MultMediaPickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickMedia":
        let args = call.arguments as? [String : Any]
        let mediaType = args?["mediaType"] as? Int
        getMedias(mediaType: mediaType, result: result)
        break
    case "getThumbnail":
        let args = call.arguments as? [String : Any]
        let path = args?["path"] as? String ?? ""
        let mediaType = args?["mediaType"] as? Int ?? 0
        getThumbnail(assetId: path, mediaType: mediaType, result: result)
        break
    case "getFilePath":
        let args = call.arguments as? [String : Any]
        let assetId = args?["assetId"] as? String ?? ""
        let mediaType = args?["mediaType"] as? Int ?? 0
        getFilePath(assetId: assetId, mediaType: mediaType, result: result)
        break
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
    private func getMedias(mediaType: Int?, result: @escaping FlutterResult) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    result([])
                }
                return
            }
            var albums: [[String: Any]] = []
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            smartAlbums.enumerateObjects { collection, _, _ in
                if let albumData = self.fetchAlubmData(collection: collection, mediaType: mediaType, options: options) {
                    albums.append(albumData)
                }
            }
            
            let userAlubms = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            userAlubms.enumerateObjects { Collection, _, _ in
                if let albumData = self.fetchAlubmData(collection: Collection, mediaType: mediaType, options: options) {
                    albums.append(albumData)
                }
            }
            
            DispatchQueue.main.async {
                result(albums)
            }
        }
        
    }
    
    private func fetchAlubmData(collection: PHAssetCollection, mediaType: Int?, options: PHFetchOptions) -> [String: Any]? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = options.sortDescriptors
        
        if let type = mediaType {
            fetchOptions.predicate = NSPredicate(
                format: "mediaType == %d", type == 0 ? PHAssetMediaType.image.rawValue : PHAssetMediaType.video.rawValue)
        }
        
        let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        guard assets.count > 0 else {return nil}
        
        var medias: [[String: Any]] = []
        assets.enumerateObjects { asset, _, _ in
            medias.append([
                "id" : asset.localIdentifier,
                "mediaType" : asset.mediaType == .video ? 1 : 0,
                "dateCreate" : Int(asset.creationDate?.timeIntervalSince1970 ?? 0),
                "width" : asset.pixelWidth,
                "height" : asset.pixelHeight,
                "duration" : Int(asset.duration),
                ]
            )
        }
        return [
            "name" : collection.localizedTitle ?? "Unknown",
            "media" : medias
        ]
        
    }
    
    private func getFilePath(assetId: String, mediaType: Int, result: @escaping FlutterResult) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            result(nil)
            return
        }
        
        let tempDir = NSTemporaryDirectory()
        let fileName = "\(assetId.replacingOccurrences(of: "/", with: "_")).\(mediaType == 1 ? "mp4" : "jpg")"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)
        let fileURL = URL(fileURLWithPath: filePath)
        
        if FileManager.default.fileExists(atPath: filePath) {
            result(filePath)
            return
        }
        
        if mediaType == 1 {
            let opts = PHVideoRequestOptions()
            opts.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: asset, options: opts) { avAsset, _, _ in
                guard let urlAsset = avAsset as? AVURLAsset,
                      let _ = try? FileManager.default.copyItem(at: urlAsset.url, to: fileURL)
                else {
                    DispatchQueue.main.async {
                        result(nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    result(filePath)
                }
            }
            
        } else {
            let opt = PHImageRequestOptions()
            opt.isNetworkAccessAllowed = true
            PHImageManager.default().requestImageData(for: asset, options: opt) { data, _, _, _ in
                guard let data = data, let _ = try? data.write(to: fileURL) else {
                    DispatchQueue.main.async {
                        result(nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    result(filePath)
                }
            }
        }
    }
    
    private func getThumbnail(assetId: String, mediaType: Int, result: @escaping FlutterResult) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            result(nil)
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { image, _ in
            
            if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
                result(FlutterStandardTypedData(bytes: data))
            } else {
                result(nil)
            }
        }
        
    }
}
