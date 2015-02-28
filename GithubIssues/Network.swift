//
//  Network.swift
//  UIShared
//
//  Created by Florian on 14/10/14.
//  Copyright (c) 2014 unsignedinteger.com. All rights reserved.
//

import Foundation

public typealias NetworkTaskCompletionHandler = NSData -> ()
public typealias NetworkTaskProgressHandler = Double -> ()
public typealias NetworkTaskFailureHandler = (statusCode: Int, error: NSError?, data: NSData?) -> ()


public class NetworkSession: NSObject, NSURLSessionDataDelegate {
    
    var session: NSURLSession!
    var tasks: [NetworkTask] = []
    var credential: NSURLCredential?
    
    public override init() {
        super.init()
        session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: self, delegateQueue: nil)
    }
    
    deinit {
        session.invalidateAndCancel()
    }
    
    public func getURL(url: NSURL, failure: NetworkTaskFailureHandler, progress: NetworkTaskProgressHandler, validStatusCode: (Int -> Bool), completion: NetworkTaskCompletionHandler) {
        let request = NSURLRequest(URL: url)
        makeRequest(request, failure: failure,  progress: progress, validStatusCode: validStatusCode, completion: completion)
    }
    
    public func makeRequest(request: NSURLRequest, failure: NetworkTaskFailureHandler, progress: NetworkTaskProgressHandler, validStatusCode: (Int -> Bool), completion: NetworkTaskCompletionHandler) {
        mainThread {
            var t = self.networkTaskForRequest(request)
            if (t == nil) {
                let newTask = NetworkTask(session: self.session, request: request, failure: failure, progress: progress, completion: completion, validStatusCode: validStatusCode)
                self.tasks += [newTask]
            } else {
                t?.addHandlers(failure: failure, progress: progress, completion: completion)
            }
        }
    }
    
    public func cancelAllTasks() {
        session.getTasksWithCompletionHandler { dataTasks, _, _ in
            // we purposefully cast to an nsarray and then loop over it to avoid a weird swift 1.2 bad access crash
            let dataTasks1: NSArray = dataTasks
            for task in dataTasks1 {
                (task as! NSURLSessionTask).cancel()
            }
        }
    }
    
    func networkTaskForRequest(request: NSURLRequest) -> NetworkTask? {
        return tasks.filter { $0.request == request }.first
    }
    
    func removeNetworkTask(task: NetworkTask) {
        tasks = tasks.filter { $0 != task }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        // TODO: if countOfBytesExpectedToReceive is less than zero, make sure we call progress with nil (e.g. unknown)
        let progress = Double(dataTask.countOfBytesReceived) / Double(dataTask.countOfBytesExpectedToReceive)
        let task = networkTaskForRequest(dataTask.originalRequest)
        task?.callProgressHandlers(progress)
        task?.data.appendData(data)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let t = networkTaskForRequest(task.originalRequest) {
            removeNetworkTask(t)
            var statusCode = 0
            if let response = task.response as? NSHTTPURLResponse {
                statusCode = response.statusCode
            }
            if (!t.validStatusCode(statusCode) || error != nil) {
                t.callFailureHandlers(statusCode, error: error)
            } else {
                t.callCompletionHandlers()
            }
        }
    }
    
//    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
//        if challenge.previousFailureCount == 0, let c = self.credential {
//            completionHandler(.UseCredential, c)
//        } else {
//            completionHandler(.CancelAuthenticationChallenge, nil)
//        }
//    }
    
}

public func mainThread(f: () -> ()) -> () {
    dispatch_async(dispatch_get_main_queue(), f)
}


struct NetworkTask : Equatable {
    var validStatusCode : Int -> Bool = { $0 >= 200 && $0 < 300 }
    
    let request: NSURLRequest
    var url: NSURL { return request.URL! }
    var completionHandlers: [NetworkTaskCompletionHandler] = []
    var progressHandlers: [NetworkTaskProgressHandler] = []
    var failureHandlers: [NetworkTaskFailureHandler] = []
    let data = NSMutableData()
    
    init(session: NSURLSession, request: NSURLRequest, failure: NetworkTaskFailureHandler, progress: NetworkTaskProgressHandler, completion: NetworkTaskCompletionHandler, validStatusCode: Int -> Bool) {
        self.request = request
        addHandlers(failure: failure, progress: progress, completion: completion)
        let task = session.dataTaskWithRequest(request)
        task.resume()
        self.validStatusCode = validStatusCode
    }
    
    func callCompletionHandlers() {
        mainThread {
            for c in self.completionHandlers {
                c(self.data)
            }
        }
    }
    
    func callProgressHandlers(progress: Double) {
        mainThread { for p in self.progressHandlers { p(progress) } }
    }
    
    func callFailureHandlers(statusCode: Int, error: NSError?) {
        mainThread { for f in self.failureHandlers { f(statusCode: statusCode, error: error, data: self.data) } }
    }
    
    mutating func addHandlers(#failure: NetworkTaskFailureHandler, progress: NetworkTaskProgressHandler, completion: NetworkTaskCompletionHandler) {
        failureHandlers += [failure]
        progressHandlers += [progress]
        completionHandlers += [completion]
    }
    
}

func ==(lhs: NetworkTask, rhs: NetworkTask) -> Bool {
    return lhs.url == rhs.url
}

