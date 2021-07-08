//
//  Wrap.swift
//  Leaf
//
//  Created by hao yin on 2021/7/6.
//

@dynamicMemberLookup @propertyWrapper
public struct Wrap<T>{
    public var wrappedValue:T{
        get{
            return content
        }
        set{
            self.content = newValue
        }
    }
   
    var content:T
    public subscript<V>(dynamicMember dynamicMember:WritableKeyPath<T,V>)->ValueWrapCall<T,V>{
        return ValueWrapCall(content: self, keyPath: dynamicMember)
    }
    public subscript<V>(dynamicMember dynamicMember:ReferenceWritableKeyPath<T,V>)->RefWrapCall<T,V>{
        return RefWrapCall(content: self,keyPath: dynamicMember)
    }
    public func wrap<V>(key:KeyPath<T,V>)->Wrap<V>{
        let v = self.content[keyPath: key]
        return Wrap<V>(wrappedValue: v)
    }
    public init(wrappedValue:T) {
        self.content = wrappedValue
    }
    public init(_ content:T) {
        self.content = content
    }
    
    @dynamicCallable
    public class ValueWrapCall<T,V>{
        
        var content:Wrap<T>
        var keyPath:WritableKeyPath<T,V>
        public func dynamicallyCall(withKeywordArguments:KeyValuePairs<String,V>)->Wrap<T>{
            guard let v = withKeywordArguments.first?.value else { return content }
            self.content.content[keyPath: keyPath] = v
            return self.content
        }
        public func dynamicallyCall(withArguments:[V])->Wrap<T>{
            guard let v = withArguments.first else { return content }
            self.content.content[keyPath: keyPath] = v
            return content
        }
        init(content:Wrap<T>,keyPath:WritableKeyPath<T,V>){
            self.content = content
            self.keyPath = keyPath
        }
    }
    @dynamicCallable
    public class RefWrapCall<T,V>{
        var content:Wrap<T>
        var keyPath:ReferenceWritableKeyPath<T,V>
        public func dynamicallyCall(withKeywordArguments:KeyValuePairs<String,V>)->Wrap<T>{
            guard let v = withKeywordArguments.first?.value else { return content }
            self.content.content[keyPath: keyPath] = v
            return self.content
        }
        public func dynamicallyCall(withArguments:[V])->Wrap<T>{
            guard let v = withArguments.first else { return content }
            self.content.content[keyPath: keyPath] = v
            return content
        }
        public func dynamicallyCall()->Wrap<V>{
            return Wrap<V>(wrappedValue: self.content.content[keyPath: keyPath])
        }
        init(content:Wrap<T>,keyPath:ReferenceWritableKeyPath<T,V>){
            self.content = content
            self.keyPath = keyPath
        }
    }
}
