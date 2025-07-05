import Foundation

// Shared memory store for session data
class SessionStore {
   static let shared = SessionStore()
   private var storage: [String: Any] = [:]
   private let queue = DispatchQueue(label: "session.store", attributes: .concurrent)
   
   // Encoders and decoders for Codable support
   private let encoder = JSONEncoder()
   private let decoder = JSONDecoder()
   
   private init() {}
   
   /// Stores any `Codable` value by first encoding it to `Data`.
   func store<T: Codable>(codable value: T, forKey key: String) {
       queue.async(flags: .barrier) {
           do {
               let data = try self.encoder.encode(value)
               self.storage[key] = data
           } catch {
               print("Error encoding value for session store: \(error.localizedDescription)")
           }
       }
   }
   
   /// Retrieves any `Codable` value by decoding it from stored `Data`.
   func retrieve<T: Codable>(codable type: T.Type, forKey key: String) -> T? {
       queue.sync {
           guard let data = self.storage[key] as? Data else {
               return nil
           }
           do {
               let value = try self.decoder.decode(T.self, from: data)
               return value
           } catch {
               print("Error decoding value from session store: \(error.localizedDescription)")
               return nil
           }
       }
   }
}
