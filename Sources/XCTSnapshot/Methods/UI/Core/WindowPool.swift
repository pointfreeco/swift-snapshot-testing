import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
@MainActor
final class WindowPool {

  // MARK: - Internal static properties

  static let shared = WindowPool(SDKApplication.sharedIfAvailable)

  // MARK: - Private properties

  private var keyUnit: PooledWindow?
  private var units: [PooledWindow] = []

  private weak var application: SDKApplication?

  #if !os(macOS)
  private var restoreWindowScene: UIWindowScene? {
    if let windowScene = keyUnit?.window.windowScene {
      return windowScene
    } else {
      return units.lazy
        .compactMap(\.window.windowScene)
        .first
    }
  }
  #endif

  // MARK: - Inits

  init(_ application: SDKApplication?) {
    self.application = application
  }

  // MARK: - Internal methods

  func acquire(
    isKeyWindow: Bool,
    maxConcurrentTests: Int,
    scene role: UISceneSession.Role = .windowApplication
  ) async throws -> SDKWindow {
    if isKeyWindow, let window = try await acquireKey(scene: role) {
      return window
    } else {
      return try await acquireRegular(maxConcurrentTests: maxConcurrentTests)
    }
  }

  func release(_ window: SDKWindow) async {
    if window.isKeyWindow || keyUnit?.window === window {
      return await releaseKey(window)
    } else {
      return await releaseRegular(window)
    }
  }

  // MARK: - Private methods

  #if os(macOS)
  private func acquireKey(
    scene role: UISceneSession.Role
  ) async throws -> SDKWindow? {
    if let keyUnit {
      try await keyUnit.lock()
      return keyUnit.window
    }

    if let keyWindow = application?.mainWindow {
      let unit = PooledWindow(window: keyWindow)
      keyUnit = unit
      try await unit.lock()
      return keyWindow
    }

    let window = SDKWindow()

    if let application {
      attach(window, in: application)
    } else {
      window.setIsVisible(true)
    }

    let unit = PooledWindow(window: window)
    keyUnit = unit
    try await unit.lock()
    return window
  }
  #else
  private func acquireKey(
    scene role: UISceneSession.Role
  ) async throws -> UIWindow? {
    if let keyUnit {
      try await keyUnit.lock()
      return keyUnit.window
    }

    let windowScenes = application?.windowScenes(for: role)

    if let keyWindow = windowScenes?.keyWindows.last {
      let unit = PooledWindow(window: keyWindow)
      keyUnit = unit
      try await unit.lock()
      return keyWindow
    }

    return nil
  }
  #endif

  private func acquireRegular(maxConcurrentTests: Int) async throws -> SDKWindow {
    if units.count >= maxConcurrentTests {
      let units = units[0 ..< maxConcurrentTests]
      let unit = units.sorted(by: { $0.pendingTasks >= $1.pendingTasks }).first!
      try await unit.lock()
      #if os(macOS)
      unit.window.setIsVisible(true)
      #else
      unit.window.isHidden = false
      #endif
      return unit.window
    }

    #if os(macOS)
    let window = SDKWindow()
    #else
    let window: UIWindow

    if let windowScene = application?.windowScenes(for: .windowApplication).first ?? restoreWindowScene {
      window = UIWindow(windowScene: windowScene)
    } else {
      window = UIWindow()
    }
    #endif

    #if os(macOS)
    window.setIsVisible(true)
    #else
    window.isHidden = false
    #endif
    let unit = PooledWindow(window: window)
    units.append(unit)
    try await unit.lock()
    return window
  }

  private func releaseKey(_ window: SDKWindow) async {
    guard let keyUnit, keyUnit.window === window else {
      fatalError("Key Window is not the one we expect")
    }

    await keyUnit.unlock()
  }

  private func releaseRegular(_ window: SDKWindow) async {
    #if os(macOS)
    defer { window.close() }
    #else
    defer { window.isHidden = true }
    #endif

    guard let (index, unit) = units.enumerated().first(where: { $1.window === window }) else {
      return
    }

    let pendingTasks = unit.pendingTasks
    if pendingTasks == .zero {
      units.remove(at: index)
    }

    await unit.unlock()
  }

  private func attach(_ window: SDKWindow, in application: SDKApplication) {
    // TODO: - Improve code
    #if os(macOS)
    window.setIsVisible(true)
    #else
    window.isHidden = false
    #endif
  }
}

extension WindowPool {

  @MainActor
  class PooledWindow {

    private let _lock: AsyncLock
    let window: SDKWindow

    private(set) var pendingTasks: Int = .zero

    init(window: SDKWindow) {
      _lock = .init()
      self.window = window
    }

    func lock() async throws {
      pendingTasks += 1
      try await _lock.lock()
      pendingTasks -= 1
    }

    func unlock() async {
      await _lock.unlock()
    }
  }
}

// MARK: - SnapshotWindowConfiguration

@MainActor
struct SnapshotWindowConfiguration<Input> {
  let window: SDKWindow
  let input: Input
}

extension Snapshot {

  func withWindow<NewInput>(
    drawHierarchyInKeyWindow: Bool,
    application: SDKApplication?,
    operation: @escaping @Sendable (SnapshotWindowConfiguration<NewInput>, Executor) async throws -> Async<NewInput, Output>
  ) -> AsyncSnapshot<NewInput, Output> {
    map { executor in
      Async(NewInput.self) { @MainActor newInput in
        let windowPool = application?.windowPool ?? WindowPool.shared

        let window = try await windowPool.acquire(
          isKeyWindow: drawHierarchyInKeyWindow,
          maxConcurrentTests: SnapshotEnvironment.current.maxConcurrentTests
        )

        let configuration = SnapshotWindowConfiguration(
          window: window,
          input: newInput
        )

        do {
          let executor = try await operation(configuration, executor)
          let output = try await executor(newInput)

          await windowPool.release(window)
          return output
        } catch {
          await windowPool.release(window)
          throw error
        }
      }
    }
  }
}

extension Snapshot {

  func withApplication<NewInput: SDKApplication>(
    scene role: UISceneSession.Role,
    operation: @escaping @Sendable (SnapshotWindowConfiguration<SDKWindow>, Executor) async throws -> Async<NewInput, Output>
  ) -> Snapshot<Async<NewInput, Output>> {
    map { executor in
      Async<NewInput, Output> { @MainActor newInput in
        let windowPool = newInput.windowPool

        let window = try await windowPool.acquire(
          isKeyWindow: true,
          maxConcurrentTests: 1,
          scene: role
        )

        let configuration = SnapshotWindowConfiguration(
          window: window,
          input: window
        )

        do {
          let executor = try await operation(configuration, executor)
          let output = try await executor(newInput)

          await windowPool.release(window)
          return output
        } catch {
          await windowPool.release(window)
          throw error
        }
      }
    }
  }
}

@MainActor
private var kApplicationWindowPool = 0

@MainActor
private extension SDKApplication {

  var windowPool: WindowPool {
    if let windowPool = objc_getAssociatedObject(self, &kApplicationWindowPool) as? WindowPool {
      return windowPool
    }

    let windowPool = WindowPool(self)
    objc_setAssociatedObject(self, &kApplicationWindowPool, windowPool, .OBJC_ASSOCIATION_RETAIN)
    return windowPool
  }
}

// MARK: - SnapshotUIController extensions

extension Async where Output == SnapshotUIController {

  func connectToWindow(_ configuration: SnapshotWindowConfiguration<Input>) -> Async<Input, ViewOperationPayload> {
    map { @MainActor in
      ViewOperationPayload(
        previousRootViewController: configuration.window.switchRoot($0),
        window: configuration.window,
        input: $0
      )
    }
  }
}
#endif

#if os(macOS)
enum UISceneSession {
  enum Role {
    case windowApplication
  }
}
#endif
