import UIKit

struct DataManager {
    static func request(url: URL, params: [String:Any]?, completion: @escaping (_ data: [[String: Any]]?, _ error: Error?) -> Void) {
        let session = URLSession.shared
        var request = URLRequest(url: url)
            request.httpMethod = "GET"

        if params != nil {
            request.httpMethod = "POST"
           
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: params!, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
            } catch let error {
                completion(nil, error)
            }
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
        }

        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil, let data = data else {
                return completion(nil, error)
            }

            var jsonResult: [[String:Any]] = []
            
            do {
                //create json object from data
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? NSArray {
                    for obj in jsonArray {
                        if let obj = obj as? [String:Any] {
                            jsonResult.append(obj)
                        }
                    }

                    completion(jsonResult, nil)
                } else {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                        completion([json], nil)
                    }
                }
            } catch let error {
                completion(nil, error)
            }
        })

        task.resume()
    }
    
    
    
    //*****************************************************************
    // Helper struct to get either local or remote JSON
    //*****************************************************************
    
    static func getStationDataWithSuccess(success: @escaping ((_ metaData: Data?) -> Void)) {

        DispatchQueue.global(qos: .userInitiated).async {
            getDataFromFileWithSuccess() { data in
                success(data)
            }
        }
    }
    
    //*****************************************************************
    // Load local JSON Data
    //*****************************************************************
    
    static func getDataFromFileWithSuccess(success: (_ data: Data?) -> Void) {
        guard let filePathURL = Bundle.main.url(forResource: "stations", withExtension: "json") else {
            if kDebugLog { print("The local JSON file could not be found") }
            success(nil)
            return
        }
        
        do {
            let data = try Data(contentsOf: filePathURL, options: .uncached)
            success(data)
        } catch {
            fatalError()
        }
    }
    
    //*****************************************************************
    // REUSABLE DATA/API CALL METHOD
    //*****************************************************************
    
    static func loadDataFromURL(url: URL, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.allowsCellularAccess = true
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.timeoutIntervalForResource = 30
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        let session = URLSession(configuration: sessionConfig)
        
        // Use URLSession to get data from an NSURL
        let loadDataTask = session.dataTask(with: url) { data, response, error in
            
            guard error == nil else {
                completion(nil, error!)
                if kDebugLog { print("API ERROR: \(error!)") }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                completion(nil, nil)
                if kDebugLog { print("API: HTTP status code has unexpected value") }
                return
            }
            
            guard let data = data else {
                completion(nil, nil)
                if kDebugLog { print("API: No data received") }
                return
            }
            
            // Success, return data
            completion(data, nil)
        }
        
        loadDataTask.resume()
    }
}
