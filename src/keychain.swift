import Security
import Foundation
import LocalAuthentication
import SQLite3
func query_access_group(agrp:String,db:OpaquePointer?)->[String]{
    var groups:[String]=[];
    var statement: OpaquePointer?
    if SQLITE_OK == sqlite3_prepare_v2(db, "SELECT DISTINCT agrp FROM \(agrp)", -1, &statement, nil){
        while sqlite3_step(statement) == SQLITE_ROW {
            let agrp = sqlite3_column_text(statement, 0)
            if agrp != nil{
                let str = String(cString: agrp!)
                if groups.contains(str){}else{
                    groups.append(str)
                }
            }
        }
    }
    sqlite3_finalize(statement)
    return groups
}
func getAllAccessGroups()->[String]{
    var groups:[String]=[];
    var db: OpaquePointer?;
    if SQLITE_OK == sqlite3_open_v2("/var/Keychains/keychain-2.db", &db, SQLITE_OPEN_READWRITE, nil){
        groups+=query_access_group(agrp: "genp", db: db)
        // groups+=query_access_group(agrp: "cert", db: db)
        // groups+=query_access_group(agrp: "inet", db: db)
        // groups+=query_access_group(agrp: "keys", db: db)
    }
    sqlite3_close_v2(db)
    return groups
}
func addKeychainItem() -> OSStatus {

    let account: String = "Test Account"
    let service: String = "Test Service"
    let accessibleConstant = kSecAttrAccessibleAlways
    let data: Data = "".data(using: String.Encoding.utf8)!

    var status: OSStatus = -1
    var error: Unmanaged<CFError>?

    if let _ = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlocked, .devicePasscode, &error) {

        let query = [
            kSecClass as String         :   kSecClassGenericPassword as String,
            kSecAttrAccount as String   :   account,
            kSecAttrService as String   :   service,
            kSecAttrAccessible as String:   accessibleConstant,
            // Uncomment the following line to add AccessControl. Make sure
            // "acl" is defined above in the if let scope.
            //kSecAttrAccessControl as String :   acl,
            kSecValueData as String     :   data
            ] as [String : Any]

        status = SecItemAdd(query as CFDictionary, nil)
    } else {
        print("[addItem::SecAccessControl] - \(error?.takeUnretainedValue())")
    }
    return status
}

func dumpKeychainItems() -> [Dictionary<String, String>] {
    var returnedItemsInGenericArray: AnyObject? = nil
    var finalArrayOfKeychainItems = [Dictionary<String, String>]()
    var returnedKeychainItems = [Dictionary<String, String>]()
    var status: OSStatus = -1
    var context = LAContext()
    let AccessGroups = getAllAccessGroups()
    print("Loaded AccessGroups:\(AccessGroups.count)")
    // let secClasses: [NSString] = [kSecClassGenericPassword,kSecClassIdentity]
    for agrp in AccessGroups{
        let query_spec = [
                kSecClass as String                     :   kSecClassGenericPassword,
                kSecAttrAccessGroup as String           :   agrp,
                kSecMatchLimit as String                :   kSecMatchLimitAll,
                kSecReturnAttributes as String          :   kCFBooleanTrue as Any,
                kSecReturnData as String                :   kCFBooleanTrue as Any,
                // kSecReturnRef as String                 :   kCFBooleanTrue as Any,
                // kSecReturnPersistentRef as String       :   kCFBooleanTrue as Any,
                kSecAttrSynchronizable as String        :   kSecAttrSynchronizableAny,
                kSecUseAuthenticationContext as String  :   context
                ] as [String : Any]
        status = SecItemCopyMatching(query_spec as CFDictionary, &returnedItemsInGenericArray)
        if status == errSecSuccess && returnedItemsInGenericArray != nil {
                finalArrayOfKeychainItems =  finalArrayOfKeychainItems + canonicalizeTypesInReturnedDicts(items: returnedItemsInGenericArray as! Array)
                returnedItemsInGenericArray = nil;
        }
    }
    for agrp in AccessGroups{
        let query_spec = [
                kSecClass as String                     :   kSecClassIdentity,
                kSecAttrAccessGroup as String           :   agrp,
                kSecMatchLimit as String                :   kSecMatchLimitAll,
                kSecReturnAttributes as String          :   kCFBooleanTrue as Any,
                kSecReturnData as String                :   kCFBooleanTrue as Any,
                // kSecReturnRef as String                 :   kCFBooleanTrue as Any,
                // kSecReturnPersistentRef as String       :   kCFBooleanTrue as Any,
                kSecAttrSynchronizable as String        :   kSecAttrSynchronizableAny,
                kSecUseAuthenticationContext as String  :   context
                ] as [String : Any] 
        status = SecItemCopyMatching(query_spec as CFDictionary, &returnedItemsInGenericArray)
        if status == errSecSuccess && returnedItemsInGenericArray != nil {
                finalArrayOfKeychainItems =  finalArrayOfKeychainItems + canonicalizeTypesInReturnedIdentity(items: returnedItemsInGenericArray as! Array)
                returnedItemsInGenericArray = nil;
        }
    }
    if AccessGroups.count > 0 && finalArrayOfKeychainItems.count > 0 {
        print("Fetch data from AccessGroups")
        return finalArrayOfKeychainItems
    }
    // let accessiblityConstants: [NSString] = [kSecAttrAccessibleAfterFirstUnlock,
    //                                          kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    //                                          kSecAttrAccessibleAlways,
    //                                          kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
    //                                          kSecAttrAccessibleAlwaysThisDeviceOnly,
    //                                          kSecAttrAccessibleWhenUnlocked,
    //                                          kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
    // print(accessiblityConstants)
    // for eachKSecClass in secClasses {
    //     for eachConstant in accessiblityConstants {
    //         let query = [
    //             kSecClass as String                     :   eachKSecClass,
    //             kSecAttrAccessible as String            :   eachConstant,
    //             kSecMatchLimit as String                :   kSecMatchLimitAll,
    //             kSecReturnAttributes as String          :   kCFBooleanTrue as Any,
    //             kSecReturnData as String                :   kCFBooleanTrue as Any,
    //             kSecReturnRef as String                 :   kCFBooleanTrue as Any,
    //             kSecReturnPersistentRef as String       :   kCFBooleanTrue as Any,
    //             kSecAttrSynchronizable as String        :   kSecAttrSynchronizableAny,
    //             kSecUseAuthenticationContext as String  :   context
    //             ] as [String : Any]

    //         status = SecItemCopyMatching(query as CFDictionary, &returnedItemsInGenericArray)

    //         if status == errSecSuccess && returnedItemsInGenericArray != nil {
    //             finalArrayOfKeychainItems =  finalArrayOfKeychainItems
    //                 + (returnedItemsInGenericArray as! Array)
    //             returnedItemsInGenericArray = nil;
    //         }else {
    //             print("status == errSecSuccess - \(status == errSecSuccess) - \(SecCopyErrorMessageString(status,nil)!) \(eachConstant)")
    //         }
    //     }
    // }
    // print("Fetch data from Accessibles")
    return finalArrayOfKeychainItems
}

func updateKeychainItem(at secClass: String = kSecClassGenericPassword as String,
                account: String,
                service: String,
                data: String,
                agroup: String? = nil) -> OSStatus {

    guard let updatedData = data.data(using: String.Encoding.utf8) else {
        NSLog("UpdateKeychainItem() -> Error while unwrapping user-supplied data.")
        exit(EXIT_FAILURE)
    }

    var query = [
        kSecClass as String         :   secClass,
        kSecAttrAccount as String   :   account,
        kSecAttrService as String   :   service
    ]
    if let unwrappedAGroup = agroup {
        query[kSecAttrAccessGroup as String] = unwrappedAGroup
    }

    let dataToUpdate = [kSecValueData as String : updatedData]
    let status: OSStatus = SecItemUpdate(query as CFDictionary, dataToUpdate as CFDictionary)
    return status
}

func deleteKeychainItem(at secClass: String = kSecClassGenericPassword as String,
                account: String,
                service: String,
                agroup: String? = nil) -> OSStatus {
    var context = LAContext()
    var query = [
        kSecClass as String         :   secClass,
        kSecAttrAccount as String   :   account,
        kSecAttrService as String   :   service,
        // kSecMatchLimit as String                :   kSecMatchLimitAll,
        kSecReturnAttributes as String          :   kCFBooleanTrue as Any,
        kSecReturnData as String                :   kCFBooleanTrue as Any,
        kSecReturnRef as String                 :   kCFBooleanTrue as Any,
        kSecReturnPersistentRef as String       :   kCFBooleanTrue as Any,
        kSecAttrSynchronizable as String        :   kSecAttrSynchronizableAny,
        kSecUseAuthenticationContext as String  :   context
    ]
    if let unwrappedAGroup = agroup {
        query[kSecAttrAccessGroup as String] = unwrappedAGroup
    }
    let status: OSStatus = SecItemDelete(query as CFDictionary)
    return status
}

func deleteKeychainIdentity(at secClass: String = kSecClassIdentity as String,
                label: String,
                agroup: String? = nil) -> OSStatus {
    var context = LAContext()
    var query = [
        kSecClass as String         :   secClass,
        kSecAttrLabel as String   :   label,
        // kSecMatchLimit as String                :   kSecMatchLimitAll,
        kSecReturnAttributes as String          :   kCFBooleanTrue as Any,
        kSecReturnData as String                :   kCFBooleanTrue as Any,
        kSecReturnRef as String                 :   kCFBooleanTrue as Any,
        kSecReturnPersistentRef as String       :   kCFBooleanTrue as Any,
        kSecAttrSynchronizable as String        :   kSecAttrSynchronizableAny,
        kSecUseAuthenticationContext as String  :   context
    ]
    if let unwrappedAGroup = agroup {
        query[kSecAttrAccessGroup as String] = unwrappedAGroup
    }
    let status: OSStatus = SecItemDelete(query as CFDictionary)
    return status
}