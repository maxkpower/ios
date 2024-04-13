import SwiftUI

// MARK: - ManualEntryProcessor

/// A processor that can process `ManualEntryAction`s.
///
/// This class is responsible for handling actions and effects related to manually entry of authenticator keys.
///
final class ManualEntryProcessor: StateProcessor<ManualEntryState, ManualEntryAction, ManualEntryEffect> {
    // MARK: Types

    /// A typealias for the services required by this processor.
    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` responsible for navigation-related actions.
    private let coordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>

    /// The services used by this processor, including camera authorization and error reporting.
    private let services: Services

    // MARK: Intialization

    /// Creates a new `ManualEntryProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` responsible for managing navigation based on actions received.
    ///   - services: The services used by this processor, including access to the camera and error reporting.
    ///   - state: The initial state of this processor, representing the UI's state.
    ///
    init(
        coordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        services: Services,
        state: ManualEntryState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    override func perform(_ effect: ManualEntryEffect) async {
        switch effect {
        case .scanCodePressed:
            await coordinator.handleEvent(.showScanCode, context: nil)
        }
    }

    override func receive(_ action: ManualEntryAction) {
        switch action {
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        case let .addPressed(code: authKey, name: name):
            addItem(key: authKey, name: name)
        case let .authenticatorKeyChanged(newKey):
            state.authenticatorKey = newKey
        case let .nameChanged(newName):
            state.name = newName
        }
    }

    /// Adds the item
    ///
    private func addItem(key: String, name: String) {
        do {
            try EmptyInputValidator(fieldName: Localizations.service)
                .validate(input: state.name)
            try EmptyInputValidator(fieldName: Localizations.authenticatorKey)
                .validate(input: state.authenticatorKey)
            coordinator.navigate(to: .addManual(key: key, name: name))
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
            return
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }
}
