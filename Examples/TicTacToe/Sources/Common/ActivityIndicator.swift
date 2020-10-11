import Foundation

public struct AlertState<Action>: Equatable {
    public static func == (lhs: AlertState<Action>, rhs: AlertState<Action>) -> Bool {
        return lhs.id == rhs.id
    }
    
  public let id = UUID()
  public var message: String?
  public var primaryButton: Button?
  public var secondaryButton: Button?
  public var title: String

  public init(
    title: String,
    message: String? = nil,
    dismissButton: Button? = nil
  ) {
    self.title = title
    self.message = message
    self.primaryButton = dismissButton
  }

  public init(
    title: String,
    message: String? = nil,
    primaryButton: Button,
    secondaryButton: Button
  ) {
    self.title = title
    self.message = message
    self.primaryButton = primaryButton
    self.secondaryButton = secondaryButton
  }

  public struct Button {
    public var action: Action?
    public var type: `Type`

    public static func cancel(
      _ label: String,
      send action: Action? = nil
    ) -> Self {
      Self(action: action, type: .cancel(label: label))
    }

    public static func cancel(
      send action: Action? = nil
    ) -> Self {
      Self(action: action, type: .cancel(label: nil))
    }

    public static func `default`(
      _ label: String,
      send action: Action? = nil
    ) -> Self {
      Self(action: action, type: .default(label: label))
    }

    public static func destructive(
      _ label: String,
      send action: Action? = nil
    ) -> Self {
      Self(action: action, type: .destructive(label: label))
    }

    public enum `Type` {
      case cancel(label: String?)
      case `default`(label: String)
      case destructive(label: String)
    }
  }
}
