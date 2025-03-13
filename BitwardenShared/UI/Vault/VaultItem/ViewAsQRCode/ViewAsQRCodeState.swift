import BitwardenSdk

/// An object that defines the current state of a `ViewAsQRCodeView`.
///
struct ViewAsQRCodeState: Equatable {
    var availableCodeTypes: [QRCodeType] = QRCodeType.allCases

    let cipher: CipherView

    var selectedFields: [CipherFieldType]

    var string: String {
        switch qrCodeType {
        case .url:
            return valueForField(cipher: cipher, field: selectedFields[0]) ?? ""
        case .wifi:
            let ssid = valueForField(cipher: cipher, field: selectedFields[0]) ?? "Error"
            let password = valueForField(cipher: cipher, field: selectedFields[1]) ?? "Error"
            return "WIFI:T:WPA;S:\(ssid);P:\(password);;"
        }
    }

    var qrCodeType: QRCodeType = .wifi

    var expectedFields: [ExpectableField] {
        qrCodeType.expectedFields
    }

    func valueForField(cipher: CipherView, field: CipherFieldType) -> String? {
        switch field {
        case .none:
            return nil
        case .username:
            return cipher.login?.username
        case .password:
            return cipher.login?.password
        case .notes:
            return cipher.notes
        case let .uri(index: uriIndex):
            return cipher.login?.uris?[uriIndex].uri
        case let .custom(name: name):
            return cipher.customFields.first(where: {$0.name == name})?.value
        }
    }

    func fieldsForField(field: ExpectableField) -> [CipherFieldType] {
        var fieldBuffer = [CipherFieldType]()
        if field.isOptional {
            fieldBuffer.append(.none)
        }
        if cipher.login?.username?.isEmpty == false {
            fieldBuffer.append(.username)
        }
        if cipher.login?.password?.isEmpty == false {
            fieldBuffer.append(.password)
        }
        if cipher.notes?.isEmpty == false {
            fieldBuffer.append(.notes)
        }
        if let urls = cipher.login?.uris {
            for index in 0..<urls.count {
                fieldBuffer.append(.uri(index: index))
            }
        }
        for customField in cipher.customFields {
            fieldBuffer.append(.custom(name: customField.name ?? "Custom Field"))
        }
        return fieldBuffer
    }

    func initialSelectedFieldForField(_ field: ExpectableField, available: [CipherFieldType]) -> CipherFieldType {
        for potentialField in field.fieldPriority {
            if available.contains(potentialField) {
                return potentialField
            }
        }
        if available.contains(.none) { return .none }
        return available.first ?? .username
    }

    mutating func setUpInitialSelected() {
        var buffer = [CipherFieldType]()
        for field in qrCodeType.expectedFields {
            let available = fieldsForField(field: field)
            buffer.append(initialSelectedFieldForField(field, available: available))
        }
        selectedFields = buffer
    }
}

struct ExpectableField: Equatable, Hashable, Sendable {
    let name: String
    var fieldTitle: String { Localizations.fieldFor(name) }

    let isOptional: Bool
    let fieldPriority: [CipherFieldType]
}

enum QRCodeType: CaseIterable, Equatable, Menuable, Sendable {
    case url
    case wifi

    static var allCases: [QRCodeType] = [
        .wifi,
        .url,
    ]

    var localizedName: String {
        switch self {
        case .wifi: Localizations.wifi
        case .url: Localizations.url
        }
    }

    var expectedFields: [ExpectableField] {
        switch self {
        case .wifi:
            [
                ExpectableField(
                    name: Localizations.ssid,
                    isOptional: false,
                    fieldPriority: [
                        .username,
                        .custom(name: "SSID"),
                    ]
                ),
                ExpectableField(
                    name: Localizations.password,
                    isOptional: true,
                    fieldPriority: [.password]
                ),
            ]
        case .url:
            [
                ExpectableField(
                    name: Localizations.url,
                    isOptional: false,
                    fieldPriority: [.uri(index: 0)]
                ),
            ]
        }
    }
}

enum CipherFieldType: Equatable, Menuable, Sendable {
    case none
    case username
    case password
    case notes
    case uri(index: Int)
    case custom(name: String)

    var localizedName: String {
        switch self {
        case .none:
            "--\(Localizations.select)--"
        case .username:
            Localizations.username
        case .password:
            Localizations.password
        case .notes:
            Localizations.notes
        case let .uri(index):
            Localizations.url
        case let .custom(name):
            "Custom field: \(name)"
        }
    }
}
