import Foundation

class RadioTimeHelper {
    static func getStreamURL(fromURL url:URL?) -> URL? {
        // We only need streamhelper for radiotime URLs
        if String(describing: url).range(of: "radiotime.com") == nil {
            return url
        }
        
        guard let url = url else { return nil }
        guard let urlData = RadioTimeHelper.getURLData(fromURL: url) else { return nil }
        
        var urlArray = [URL]()
        if let stringData = String(data: urlData, encoding: String.Encoding.utf8) {
            stringData.enumerateLines { (line, _) -> () in
                if let urlLine = URL(string: line) {
                    urlArray.append(urlLine)
                }
            }
        }
        
        guard let foundURL = urlArray.first else {
            return nil
        }
        
        if RadioTimeHelper.isPLS(url: foundURL) {
            return RadioTimeHelper.getStreamURLFromPLS(fromURL: foundURL)
        } else {
            return foundURL
        }
    }
    
    static func getURLData(fromURL url: URL) -> Data? {
        var result:Data? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            result = data
            semaphore.signal()
            }.resume()
        
        semaphore.wait()
        
        return result
    }
    
    static func getStreamURLFromPLS(fromURL url: URL) -> URL? {
        guard let urlData = RadioTimeHelper.getURLData(fromURL: url) else { return nil }
        var streamURL = URL(string: "")
        
        if let stringData = String(data: urlData, encoding: String.Encoding.utf8) {
            stringData.enumerateLines { (line, _) -> () in
                if line.range(of: "File1=") != nil {
                    if let foundURL = URL(string: line.replacingOccurrences(of: "File1=", with: "")) {
                        streamURL = foundURL
                    }
                }
            }
        }
        
        return streamURL
    }
    
    static func isPLS(url: URL) -> Bool {
        if String(describing: url).range(of: ".pls") != nil {
            return true
        }
        
        return false
    }
}
