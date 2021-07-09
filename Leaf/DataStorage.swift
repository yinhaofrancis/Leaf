//
//  ImageLoader.swift
//  Leaf
//
//  Created by hao yin on 2021/7/7.
//

import UIKit
import CommonCrypto
public class DataStorage{
    public var rw:UnsafeMutablePointer<pthread_rwlock_t> = .allocate(capacity: 1)
    public func append(name:String,data:Data){
        try? self.write {
            let handle = try FileHandle(forUpdating: try verifyFile(name: name))
            if #available(iOS 13.4, *) {
                try handle.seekToEnd()
            } else {
                handle.seekToEndOfFile()
            }
            handle.write(data)
        }
    }
    public func save(name:String,data:Data){
        try? self.write {
            let handle = try FileHandle(forUpdating: try verifyFile(name: name))
            if #available(iOS 13.0, *) {
                try handle.seek(toOffset: 0)
                try handle.truncate(atOffset: 0)
                handle.write(data)
                try handle.close()
            } else {
                handle.seek(toFileOffset: 0)
                handle.truncateFile(atOffset: 0)
                handle.write(data)
                handle.closeFile()
            }
        }
    }
    func verifyFile(name:String) throws ->URL {
        let d = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("ImageCache")
        
        var a:ObjCBool = false
        if(FileManager.default.fileExists(atPath: d.path, isDirectory: &a)){
            if(!a.boolValue){
                try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true, attributes: nil)
            }
        }else {
            try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true, attributes: nil)
        }
        
        let f = d.appendingPathComponent(name).appendingPathExtension("jpg")
        if(!FileManager.default.fileExists(atPath: f.path)){
            FileManager.default.createFile(atPath: f.path, contents: nil, attributes: nil)
        }
        return f
    }
    public func read(name:String) throws ->Data{
        return try self.read {
            try self.readData(url: try self.verifyFile(name: name))
        }
        
    }
    func writeData(url:URL,data:Data) throws {
        let f = try FileHandle(forUpdating: url)
        f.write(data)
        if #available(iOS 13.0, *) {
            try f.close()
        } else {
            f.closeFile()
        }
    }
    func readData(url:URL) throws ->Data{
        let f = try FileHandle(forReadingFrom: url)
        var data:Data = Data()
        if #available(iOS 13.4, *) {
            data = try f.readToEnd() ?? Data()
        } else {
            data = f.readDataToEndOfFile()
        }
        if #available(iOS 13.0, *) {
            try f.close()
        } else {
            f.closeFile()
        }
        return data
    }
    func write(_ call:() throws ->Void)rethrows{
        defer {
            pthread_rwlock_unlock(self.rw)
        }
        pthread_rwlock_wrlock(self.rw)
        try call()
    }
    func read(_ call:()throws ->Data)rethrows->Data{
        defer {
            pthread_rwlock_unlock(self.rw)
        }
        pthread_rwlock_rdlock(self.rw)
        return try call()
    }
    public subscript(name:String)->Data?{
        do{
            return try self.read(name: name)
        }catch{
            print(error)
            return nil
        }
    }
    public typealias CC = (_ data: UnsafeRawPointer, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>
    public static func md5(str:String) throws ->String{
        guard let data = str.data(using: .utf8) else {throw NSError(domain: "str fail", code: 0, userInfo: nil)}
        let call:CC = {
            CC_MD5($0, $1, $2)
        }
        return Hash(data: data, digest: Int(CC_MD5_DIGEST_LENGTH), cFunc: call).base64EncodedString()
    }
    public static func Hash(data:Data,digest:Int,cFunc:CC)->Data{
        let p:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer.allocate(capacity: data.count)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(digest))
        data.copyBytes(to: p, count: data.count)
        _ = cFunc(p, CC_LONG(data.count), result)
        let rdata = Data(bytes: result, count: digest)
        p.deallocate()
        result.deallocate()
        return rdata
    }
    public init() {
        pthread_rwlock_init(self.rw, nil)
    }
}

public protocol TaskHandle{
    
    func handleResponse(response:HTTPURLResponse)->Bool
    
    func handleData(data:Data)
    
    func handleComplete(error: Error?)
    
    init(url:URL,session:DownloadSession<Self>) throws
    
}

final public class DownloadTask:TaskHandle{

    public required init(url:URL, session: DownloadSession<DownloadTask>) throws {
        self.url = url
        self.size = 0
        self.name = try DataStorage.md5(str: url.absoluteString)
        self.session = session
    }
    
    public func handleResponse(response: HTTPURLResponse) -> Bool {
        guard let length = response.allHeaderFields["Content-Size"] as? String else { return false }
        guard let lengthNum = Int(length) else { return false }
        if(lengthNum == 0){
            return false
        }
        let ok = response.statusCode == 200 || response.statusCode == 206
        if(ok){
            self.response = response
        }
        return ok
    }
    
    public func handleData(data: Data) {
        self.storage.append(name: self.name, data: data)
    }
    
    public func handleComplete(error: Error?) {
        if(error != nil){
            
        }
    }
    
    private var storage:DataStorage = DataStorage()
    
    var size:UInt64
    
    var url:URL
    
    var response:URLResponse?
    
    weak var session:DownloadSession<DownloadTask>?
    
    public private(set) var name:String
 

    public func download(){
        
    }
    
}

public class DownloadSession<T:TaskHandle>:NSObject,URLSessionDataDelegate{
    
    var session:URLSession?
    public init(configuration:URLSessionConfiguration){
        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
    }
    
    var tasks:[Int:T] = [:]
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        tasks[task.taskIdentifier]?.handleComplete(error: error)
    }
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        tasks[dataTask.taskIdentifier]?.handleData(data: data)
    }
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let http = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        guard let result = tasks[dataTask.taskIdentifier]?.handleResponse(response: http) else {
            completionHandler(.cancel)
            return
        }
        completionHandler(result ? .allow : .cancel)
    }
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        tasks.forEach { i in
            i.value.handleComplete(error: error)
        }
        tasks.removeAll()
    }
    public func cancel(){
        
    }
    public func request(url:URL) throws{
        
    }
}
