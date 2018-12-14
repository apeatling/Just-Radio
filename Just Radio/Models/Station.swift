//
//  Station.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-04.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import UIKit

public struct Station: Codable, Equatable {
    var name: String
    var url: String
    var image: String
    var description: String
    
    var city: String
    var region: String
    var country: String
    
    var tags: [String]
    
    var isFav: Bool
    
    init(name: String, url: String, image: String, description: String, city: String, region: String, country: String, tags: [String] = [], isFav: Bool = false) {
        self.name = name
        self.url = url
        self.image = image
        self.description = description
        
        self.city = city
        self.region = region
        self.country = country
        
        self.tags = tags
        
        self.isFav = isFav
    }
    
    func getImage(completion: @escaping (_ image: UIImage?)->()) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first, let fileSlug = self.url.convertedToSlug() else {
            return
        }
        
        let fileURL = documentsURL.appendingPathComponent("\(fileSlug).png")
        let filePath = fileURL.path
        
        if FileManager.default.fileExists(atPath: filePath) {
            DispatchQueue.main.async {
                completion(UIImage(contentsOfFile: filePath))
            }
            return
        }
        
        if let url = URL(string: (image as NSString) as String) {
            let session = URLSession.shared
            
            let downloadTask = session.downloadTask(with: url, completionHandler: { tempLocalUrl, response, error in
                if let tempLocalUrl = tempLocalUrl, error == nil {
                    do {
                        try FileManager.default.copyItem(at: tempLocalUrl, to: fileURL)
                        
                        DispatchQueue.main.async {
                            completion(UIImage(contentsOfFile: fileURL.path))
                        }
                    } catch (let writeError) {
                        print("Error creating a file \(fileURL) : \(writeError)")
                    }
                }
            })
            
            downloadTask.resume()
        }
    }
}
