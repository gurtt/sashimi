//
//  KeychainHelper.swift
//  Sashimi
//
//  Created by Riley Sommerville on 19/10/2022.
//

import Foundation

open class KeychainHelper {
    enum KeychainError: Error {
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }

    /**
    Stores the string in the keychain under the given key.
    
    - parameter key: The key under which the data is stored in the keychain.
    - parameter value: String to be written to the keychain.
    
    - throws: KeychainError if the item isn't added successfully.
    */
    open func set(_ value: String, forKey key: String) throws {
        let valueData = value.data(using: String.Encoding.utf8)!
        
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: key,
                                    kSecValueData as String: valueData]
      
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }
    
    /**
    Retrieves the text value from the keychain under the given key.
    
    - parameter key: The key under which the data is stored in the keychain.
     
    - returns: The text value from the keychain. Returns nil if unable to read the item.
    - throws: KeychainError if the item isn't retrieved successfully.
    */
    open func get(_ key: String) throws -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: key,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnData as String: true]
        
        var data: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &data)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        
        guard let stringData = String(data: data as! Data, encoding: .utf8) else { throw KeychainError.unexpectedPasswordData }
        return stringData
        
    }
    
    /**
    Deletes the keychain entry under the given key.
    
    - parameter key: The key under which the data is stored in the keychain.
     
    - throws: KeychainError if the item isn't retrieved successfully.
    */
    open func delete(_ key: String) throws {
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: key]
        
        
        let status = SecItemDelete(query as CFDictionary)
        guard status != errSecItemNotFound else { print(#"Tried to delete key "\#(key)" that didn't exist:"#); return }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }

}
