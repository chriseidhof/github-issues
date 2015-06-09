//
//  APIClient.swift
//  UIShared
//
//  Created by Chris Eidhof on 05/11/14.
//  Copyright (c) 2014 Chris Eidhof. All rights reserved.
//

import Foundation

public enum Method: String { // Bluntly stolen from Alamofire
    case OPTIONS = "OPTIONS"
    case GET = "GET"
    case HEAD = "HEAD"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
}

public typealias JSONDictionary = [String:AnyObject]

public let statusCodeIs2xx = { $0 >= 200 && $0 < 300}

public struct Resource<A> : CustomStringConvertible {
    let path: String
    let method : Method
    let requestBody: NSData?
    let headers : [String:String]
    let parse: NSData -> A?
    let validStatusCode : Int -> Bool
    
    public var description : String {
        return path
    }
    
    public init(path: String, method: Method, requestBody: NSData?, headers: [String:String], parse: NSData -> A?) {
        self.path = path
        self.method = method
        self.requestBody = requestBody
        self.headers = headers
        self.parse = parse
        self.validStatusCode = statusCodeIs2xx
    }

    public init(path: String, method: Method, requestBody: NSData?, headers: [String:String], validStatusCode: Int -> Bool, parse: NSData -> A?) {
        self.path = path
        self.method = method
        self.requestBody = requestBody
        self.headers = headers
        self.parse = parse
        self.validStatusCode = validStatusCode
    }

}

public enum Reason {
    case CouldNotParseJSON
    case NoData
    case NoSuccessStatusCode(statusCode: Int)
    case DidNotValidate(errors: [String])
    case Other(NSError)
    case Unauthorized
}

let apiClientNetworkSession = NetworkSession()

public func apiRequest<A>(modifyRequest: NSMutableURLRequest -> (), baseURL: NSURL, resource: Resource<A>, failure: (Reason, NSData?) -> (), progress: Double -> (), completion: A -> ()) {
    let url = baseURL.URLByAppendingPathComponent(resource.path)
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = resource.method.rawValue
    request.HTTPBody = resource.requestBody
    modifyRequest(request)
    for (key,value) in resource.headers {
        request.setValue(value, forHTTPHeaderField: key)
    }
    let failureHandler: NetworkTaskFailureHandler = { code, error, data in
        if error == nil {
            switch code {
            case 401: failure(Reason.Unauthorized, data)
            default: failure(Reason.NoSuccessStatusCode(statusCode: code), data)
            }
        } else {
            failure(Reason.Other(error!), data)
        }
    }
    apiClientNetworkSession.makeRequest(request, failure: failureHandler, progress: progress, validStatusCode: resource.validStatusCode) { data in
        if let result = resource.parse(data) {
            completion(result)
        } else {
            failure(Reason.CouldNotParseJSON, data)
        }
    }
}

func decodeJSON(data: NSData) -> AnyObject? {
    do {
        return try NSJSONSerialization.JSONObjectWithData(data, options:
            NSJSONReadingOptions())
    } catch _ {
        return nil
    }
}

func encodeJSON(input: JSONDictionary) -> NSData? {
    do {
        return try NSJSONSerialization.dataWithJSONObject(input, options: NSJSONWritingOptions())
    } catch _ {
        return nil
    }
}

public func jsonResource<A>(path: String, _ method: Method, _ requestParameters: JSONDictionary, _ parse: AnyObject -> A?) -> Resource<A> {
    return jsonResource(path, method, requestParameters, statusCodeIs2xx, parse)
}

func flatten<A>(x: A??) -> A? {
    return x?.flatMap { $0 }
}

func tryOrNil<A>(f:  () throws -> A) -> A? {
    do {
        return try f()
    } catch {
        return nil
    }
}

public func jsonResource<A>(path: String, _ method: Method, _ requestParameters: JSONDictionary, _ validStatusCode: Int -> Bool, _ parse: AnyObject -> A?) -> Resource<A> {

    let f  = { flatten(decodeJSON($0).map(parse)) }

    let jsonBody: NSData? = tryOrNil { try NSJSONSerialization.dataWithJSONObject(requestParameters, options: NSJSONWritingOptions()) }
    let headers = ["Content-Type": "application/json",
                   "Accept": "application/json"
                  ]
    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, validStatusCode: validStatusCode, parse: f)
}