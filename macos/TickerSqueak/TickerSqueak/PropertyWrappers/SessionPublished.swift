import SwiftUI
import Combine

/// A property wrapper that connects a property in an ObservableObject to the SessionStore.
/// It reads its initial value from the SessionStore and saves any changes back to it.
/// It also acts like @Published, automatically triggering UI updates when its value changes.

import SwiftUI
import Combine

@propertyWrapper
public struct SessionPublished<Value: Codable> {
    private let key: String
    private var value: Value

    public init(wrappedValue defaultValue: Value, _ key: String) {
        self.key = key
        if let storedValue = SessionStore.shared.retrieve(codable: Value.self, forKey: key) {
            self.value = storedValue
        } else {
            self.value = defaultValue
        }
    }

    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }
    
    @MainActor
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            return instance[keyPath: storageKeyPath].value
        }
        set {
            (instance.objectWillChange as? ObservableObjectPublisher)?.send()
            instance[keyPath: storageKeyPath].value = newValue
            
            let key = instance[keyPath: storageKeyPath].key
            // Use the new, reliable 'codable' store method.
            SessionStore.shared.store(codable: newValue, forKey: key)
        }
    }
}
