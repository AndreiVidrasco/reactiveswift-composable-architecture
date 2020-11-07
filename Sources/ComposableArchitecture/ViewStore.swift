import ReactiveSwift

#if canImport(Combine)
  import Combine
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

/// A `ViewStore` is an object that can observe state changes and send actions. They are most
/// commonly used in views, such as SwiftUI views, UIView or UIViewController, but they can be
/// used anywhere it makes sense to observe state and send actions.
///
/// In SwiftUI applications, a `ViewStore` is accessed most commonly using the `WithViewStore` view.
/// It can be initialized with a store and a closure that is handed a view store and must return a
/// view to be rendered:
///
///     var body: some View {
///       WithViewStore(self.store) { viewStore in
///         VStack {
///           Text("Current count: \(viewStore.count)")
///           Button("Increment") { viewStore.send(.incrementButtonTapped) }
///         }
///       }
///     }
///
/// In UIKit applications a `ViewStore` can be created from a `Store` and then subscribed to for
/// state updates:
///
///     let store: Store<State, Action>
///     let viewStore: ViewStore<State, Action>
///
///     init(store: Store<State, Action>) {
///       self.store = store
///       self.viewStore = ViewStore(store)
///     }
///
///     func viewDidLoad() {
///       super.viewDidLoad()
///
///       self.viewStore.produced.count
///         .startWithValues { [weak self] in self?.countLabel.text = $0 }
///     }
///
///     @objc func incrementButtonTapped() {
///       self.viewStore.send(.incrementButtonTapped)
///     }
///
public final class ViewStore<State, Action> {
  /// A producer of state.
  public let produced: Produced<State>

  @available(
    *, deprecated,
    message:
      """
    Consider using `.produced` instead, this property exists for backwards compatibility and will be removed in the next major release.
    """
  )
  public var producer: StoreProducer<State> { return produced }

  @available(
    *, deprecated,
    message:
      """
    Consider using `.produced` instead, this property exists for backwards compatibility and will be removed in the next major release.
    """
  )
  public var publisher: StoreProducer<State> { return produced }

  /// Initializes a view store from a store.
  ///
  /// - Parameters:
  ///   - store: A store.
  ///   - isDuplicate: A function to determine when two `State` values are equal. When values are
  ///     equal, repeat view computations are removed.
  public init(
    _ store: Store<State, Action>,
    removeDuplicates isDuplicate: @escaping (State, State) -> Bool
  ) {
    let producer = store.mState.producer.skipRepeats(isDuplicate)
    self.produced = Produced(by: producer)
    self.state = store.state
    self._send = store.send
    producer.startWithValues { [weak self] in
      self?.state = $0
    }
  }

  /// The current state.
  public private(set) var state: State {
    willSet {
      #if canImport(Combine)
        if #available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *) {
          self.objectWillChange.send()
        }
      #endif
    }
  }

  #if canImport(Combine)
    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
    public lazy var objectWillChange = ObservableObjectPublisher()
  #endif

  let _send: (Action) -> Void

  /// Returns the resulting value of a given key path.
  public func map<LocalState>(dynamicMember keyPath: KeyPath<State, LocalState>) -> LocalState {
    return self.state[keyPath: keyPath]
  }

  /// Sends an action to the store.
  ///
  /// `ViewStore` is not thread safe and you should only send actions to it from the main thread.
  /// If you are wanting to send actions on background threads due to the fact that the reducer
  /// is performing computationally expensive work, then a better way to handle this is to wrap
  /// that work in an `Effect` that is performed on a background thread so that the result can
  /// be fed back into the store.
  ///
  /// - Parameter action: An action.
  public func send(_ action: Action) {
    self._send(action)
  }
}

extension ViewStore where State: Equatable {
  public convenience init(_ store: Store<State, Action>) {
    self.init(store, removeDuplicates: ==)
  }
}

#if canImport(Combine)
  extension ViewStore: ObservableObject {
  }
#endif
