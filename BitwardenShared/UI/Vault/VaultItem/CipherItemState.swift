import BitwardenSdk
import Foundation

// MARK: - CipherItemState

/// An object that defines the current state of any view interacting with a cipher item.
///
struct CipherItemState: Equatable {
    // MARK: Types

    /// An enum defining if the state is a new or existing cipher.
    enum Configuration: Equatable {
        /// A case for new ciphers.
        case add

        /// A case to view or edit an existing cipher.
        case existing(cipherView: CipherView)

        /// The existing `CipherView` if the configuration is `existing`.
        var existingCipherView: CipherView? {
            guard case let .existing(cipherView) = self else { return nil }
            return cipherView
        }

        /// Whether the configuration is for adding a new cipher.
        var isAdding: Bool {
            guard case .add = self else { return false }
            return true
        }
    }

    // MARK: Properties

    /// A flag indicating if this account has premium features.
    var accountHasPremium: Bool

    /// The card item state.
    var cardItemState: CardItemState

    /// The list of collection IDs that the cipher is included in.
    var collectionIds: [String]

    /// The full list of collections for the user, across all organizations.
    var collections: [CollectionView]

    /// The Add or Existing Configuration.
    let configuration: Configuration

    /// The custom fields state.
    var customFieldsState: AddEditCustomFieldsState

    /// The identifier of the folder for this item.
    var folderId: String?

    /// The list of all folders that the item could be added to.
    var folders: [DefaultableType<FolderView>]

    /// The state for guided tour view.
    var guidedTourViewState = GuidedTourViewState(
        guidedTourStepStates: [
            .loginStep1,
            .loginStep2,
            .loginStep3,
        ]
    )

    /// The state for a identity type item.
    var identityState: IdentityItemState

    /// Whether the additional options section is expanded.
    var isAdditionalOptionsExpanded = false

    /// A flag indicating if this item is favorited.
    var isFavoriteOn: Bool

    /// If account is eligible for  Learn New Login Action Card.
    var isLearnNewLoginActionCardEligible: Bool = false

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool

    /// Whether the policy is enforced to disable personal vault ownership.
    var isPersonalOwnershipDisabled: Bool

    /// The state for a login type item.
    var loginState: LoginItemState

    /// The name of this item.
    var name: String

    /// The notes for this item.
    var notes: String

    /// The organization ID of the cipher, if the cipher is owned by an organization.
    var organizationId: String?

    /// The list of ownership options that can be selected for the cipher.
    var ownershipOptions: [CipherOwner]

    /// A flag indicating if cipher permissions should be used.
    var restrictCipherItemDeletionFlag: Bool = false

    /// If master password reprompt toggle should be shown
    var showMasterPasswordReprompt: Bool

    /// The SSH key item state.
    var sshKeyState: SSHKeyItemState

    /// A toast for the AddEditItemView
    var toast: Toast?

    /// What cipher type this item is.
    var type: CipherType

    /// When this item was last updated.
    var updatedDate: Date

    // MARK: DerivedProperties

    /// The edit state of the item.
    var addEditState: AddEditItemState {
        self
    }

    /// Whether or not this item can be assigned to collections.
    var canAssignToCollection: Bool {
        guard !collectionIds.isEmpty else { return true }

        return collections.contains { collection in
            guard let id = collection.id else { return false }
            guard collection.manage || (!collection.readOnly && !collection.hidePasswords) else { return false }

            return collectionIds.contains(id)
        }
    }

    /// Whether or not this item can be deleted by the user.
    var canBeDeleted: Bool {
        // backwards compatibility for old server versions
        guard restrictCipherItemDeletionFlagEnabled, let cipherPermissions = cipher.permissions else {
            guard !collectionIds.isEmpty else { return true }
            return collections.contains { collection in
                guard let id = collection.id else { return false }
                return collection.manage && collectionIds.contains(id)
            }
        }

        // New permission model from PM-18091
        return cipherPermissions.delete
    }

    /// Whether or not this item can be restored by the user.
    var canBeRestored: Bool {
        // backwards compatibility for old server versions
        guard restrictCipherItemDeletionFlagEnabled, let cipherPermissions = cipher.permissions else {
            return isSoftDeleted
        }

        // New permission model from PM-18091
        return cipherPermissions.restore && isSoftDeleted
    }

    /// The list of collections that can be selected from for the current owner.
    /// These are collections that the user can add items to, so they are non-read-only collections.
    var collectionsForOwner: [CollectionView] {
        guard let owner, !owner.isPersonal else { return [] }
        return collections.filter { $0.organizationId == owner.organizationId && !$0.readOnly }
    }

    /// The folder this item should be added to.
    var folder: DefaultableType<FolderView> {
        get {
            guard let folderId,
                  let folder = folders.first(where: { $0.customValue?.id == folderId })?.customValue else {
                return .default
            }
            return .custom(folder)
        } set {
            folderId = newValue.customValue?.id
        }
    }

    /// Whether the cipher is read-only.
    var isReadOnly: Bool {
        cipher.edit == false
    }

    /// The owner of the cipher.
    var owner: CipherOwner? {
        get {
            guard let organizationId else { return ownershipOptions.first(where: \.isPersonal) }
            return ownershipOptions.first(where: { $0.organizationId == organizationId })
        }
        set {
            organizationId = newValue?.organizationId
            collectionIds = []
        }
    }

    var restrictCipherItemDeletionFlagEnabled: Bool {
        get { restrictCipherItemDeletionFlag }
        set { restrictCipherItemDeletionFlag = newValue }
    }

    /// The flag indicating if we should show the learn new login action card.
    var shouldShowLearnNewLoginActionCard: Bool {
        isLearnNewLoginActionCardEligible && configuration == .add && type == .login
    }

    /// The view state of the item.
    var viewState: ViewVaultItemState? {
        guard case .existing = configuration else {
            return nil
        }

        return self
    }

    // MARK: Initialization

    private init(
        accountHasPremium: Bool,
        cardState: CardItemState,
        collectionIds: [String],
        configuration: Configuration,
        customFields: [CustomFieldState],
        folderId: String?,
        identityState: IdentityItemState,
        isFavoriteOn: Bool,
        isMasterPasswordRePromptOn: Bool,
        isPersonalOwnershipDisabled: Bool,
        loginState: LoginItemState,
        name: String,
        notes: String,
        organizationId: String?,
        sshKeyState: SSHKeyItemState,
        type: CipherType,
        updatedDate: Date
    ) {
        self.accountHasPremium = accountHasPremium
        cardItemState = cardState
        self.collectionIds = collectionIds
        collections = []
        customFieldsState = AddEditCustomFieldsState(cipherType: type, customFields: customFields)
        self.folderId = folderId
        self.identityState = identityState
        self.isFavoriteOn = isFavoriteOn
        self.isMasterPasswordRePromptOn = isMasterPasswordRePromptOn
        self.isPersonalOwnershipDisabled = isPersonalOwnershipDisabled
        folders = []
        self.loginState = loginState
        self.name = name
        self.notes = notes
        self.organizationId = organizationId
        ownershipOptions = []
        showMasterPasswordReprompt = true
        self.sshKeyState = sshKeyState
        self.type = type
        self.updatedDate = updatedDate
        self.configuration = configuration
    }

    init(
        addItem type: CipherType = .login,
        collectionIds: [String] = [],
        customFields: [CustomFieldState] = [],
        folderId: String? = nil,
        hasPremium: Bool,
        name: String? = nil,
        organizationId: String? = nil,
        password: String? = nil,
        totpKeyString: String? = nil,
        uri: String? = nil,
        username: String? = nil
    ) {
        self.init(
            accountHasPremium: hasPremium,
            cardState: .init(),
            collectionIds: collectionIds,
            configuration: .add,
            customFields: customFields,
            folderId: folderId,
            identityState: .init(),
            isFavoriteOn: false,
            isMasterPasswordRePromptOn: false,
            isPersonalOwnershipDisabled: false,
            loginState: .init(
                isTOTPAvailable: hasPremium,
                password: password ?? "",
                totpState: .init(totpKeyString),
                uris: [UriState(uri: uri ?? "")],
                username: username ?? ""
            ),
            name: name ?? uri.flatMap(URL.init)?.host ?? "",
            notes: "",
            organizationId: organizationId,
            sshKeyState: .init(),
            type: type,
            updatedDate: .now
        )
    }

    init(cloneItem cipherView: CipherView, hasPremium: Bool) {
        self.init(
            accountHasPremium: hasPremium,
            cardState: cipherView.cardItemState(),
            collectionIds: cipherView.collectionIds,
            configuration: .add,
            customFields: cipherView.customFields,
            folderId: cipherView.folderId,
            identityState: cipherView.identityItemState(),
            isFavoriteOn: cipherView.favorite,
            isMasterPasswordRePromptOn: cipherView.reprompt == .password,
            isPersonalOwnershipDisabled: false,
            loginState: cipherView.loginItemState(excludeFido2Credentials: true, showTOTP: hasPremium),
            name: "\(cipherView.name) - \(Localizations.clone)",
            notes: cipherView.notes ?? "",
            organizationId: cipherView.organizationId,
            sshKeyState: cipherView.sshKeyItemState(),
            type: .init(type: cipherView.type),
            updatedDate: cipherView.revisionDate
        )
    }

    init?(
        existing cipherView: CipherView,
        hasMasterPassword: Bool = true,
        hasPremium: Bool
    ) {
        guard cipherView.id != nil else { return nil }
        self.init(
            accountHasPremium: hasPremium,
            cardState: cipherView.cardItemState(),
            collectionIds: cipherView.collectionIds,
            configuration: .existing(cipherView: cipherView),
            customFields: cipherView.customFields,
            folderId: cipherView.folderId,
            identityState: cipherView.identityItemState(),
            isFavoriteOn: cipherView.favorite,
            isMasterPasswordRePromptOn: cipherView.reprompt == .password,
            isPersonalOwnershipDisabled: false,
            loginState: cipherView.loginItemState(
                isTOTPCodeVisible: !(hasMasterPassword && cipherView.reprompt == .password),
                showTOTP: hasPremium || cipherView.organizationUseTotp
            ),
            name: cipherView.name,
            notes: cipherView.notes ?? "",
            organizationId: cipherView.organizationId,
            sshKeyState: cipherView.sshKeyItemState(),
            type: .init(type: cipherView.type),
            updatedDate: cipherView.revisionDate
        )
    }

    // MARK: Methods

    /// Toggles the password visibility for the specified custom field.
    ///
    /// - Parameter customFieldState: The custom field to update.
    ///
    mutating func togglePasswordVisibility(for customFieldState: CustomFieldState) {
        if let index = customFieldsState.customFields.firstIndex(of: customFieldState) {
            customFieldsState.customFields[index].isPasswordVisible.toggle()
        }
    }

    /// Toggles whether the cipher is included in the specified collection.
    ///
    /// - Parameters:
    ///   - newValue: Whether the cipher is included in the collection.
    ///   - collectionId: The identifier of the collection.
    ///
    mutating func toggleCollection(newValue: Bool, collectionId: String) {
        if newValue {
            collectionIds.append(collectionId)
        } else {
            collectionIds = collectionIds.filter { $0 != collectionId }
        }
    }
}

extension CipherItemState: AddEditItemState {
    var navigationTitle: String {
        switch configuration {
        case .add:
            switch type {
            case .card: Localizations.newCard
            case .identity: Localizations.newIdentity
            case .login: Localizations.newLogin
            case .secureNote: Localizations.newNote
            case .sshKey: Localizations.newSSHKey
            }
        case .existing:
            switch type {
            case .card: Localizations.editCard
            case .identity: Localizations.editIdentity
            case .login: Localizations.editLogin
            case .secureNote: Localizations.editNote
            case .sshKey: Localizations.editSSHKey
            }
        }
    }
}

extension CipherItemState: ViewVaultItemState {
    var attachments: [AttachmentView]? {
        cipher.attachments
    }

    var isSoftDeleted: Bool {
        cipher.deletedDate != nil
    }

    var cardItemViewState: any ViewCardItemState {
        cardItemState
    }

    var cipher: BitwardenSdk.CipherView {
        switch configuration {
        case let .existing(cipherView: view):
            return view
        case .add:
            return newCipherView()
        }
    }
}

extension CipherItemState {
    /// Returns a `CipherView` based on the properties of the `CipherItemState`.
    func newCipherView(creationDate: Date = .now) -> CipherView {
        CipherView(
            id: nil,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: nil,
            name: name,
            notes: notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(type),
            login: type == .login ? loginState.loginView : nil,
            identity: type == .identity ? identityState.identityView : nil,
            card: type == .card ? cardItemState.cardView : nil,
            secureNote: type == .secureNote ? .init(type: .generic) : nil,
            sshKey: type == .sshKey ? sshKeyState.sshKeyView : nil,
            favorite: isFavoriteOn,
            reprompt: isMasterPasswordRePromptOn ? .password : .none,
            organizationUseTotp: false,
            edit: true,
            permissions: nil,
            viewPassword: true,
            localData: nil,
            attachments: nil,
            fields: customFieldsState.customFields.isEmpty ? nil : customFieldsState.customFields.map { customField in
                FieldView(
                    name: customField.name,
                    value: customField.value,
                    type: .init(fieldType: customField.type),
                    linkedId: customField.linkedIdType?.rawValue
                )
            },
            passwordHistory: nil,
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: creationDate
        )
    }
} // swiftlint:disable:this file_length
