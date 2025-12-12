//
//  ContentView.swift
//  focusTracker
//
//  Created by Hugo Peyron on 12/12/2025.
//

import SwiftUI
import SwiftData
import UIKit
import CoreMotion
import ActivityKit

// MARK: - Live Activity

struct FocusActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var remainingSeconds: Int
    var elapsed: Double
    var cycleDuration: Double
    var activityEmoji: String
    var activityName: String
    var todayFocusSeconds: Int
    var currentStreakLevel: Int
    var isRunning: Bool
  }
  
  var startTime: Date
}

// MARK: - Settings

enum AppColorScheme: String, CaseIterable {
  case system = "System"
  case light = "Light"
  case dark = "Dark"
}

enum AccentColor: String, CaseIterable {
  case brown = "Brown"
  case blue = "Blue"
  case purple = "Purple"
  case green = "Green"
  case orange = "Orange"
  case pink = "Pink"
  case red = "Red"
  
  var light: Color {
    switch self {
    case .brown: return Color(hex: "A18072")
    case .blue: return Color(hex: "5B7DB1")
    case .purple: return Color(hex: "8B7CB3")
    case .green: return Color(hex: "6B9B7A")
    case .orange: return Color(hex: "C4844A")
    case .pink: return Color(hex: "B5708A")
    case .red: return Color(hex: "B86B6B")
    }
  }
  
  var dark: Color {
    switch self {
    case .brown: return Color(hex: "D4A574")
    case .blue: return Color(hex: "7BA3D4")
    case .purple: return Color(hex: "B5A4D4")
    case .green: return Color(hex: "8BC4A0")
    case .orange: return Color(hex: "E4A46A")
    case .pink: return Color(hex: "D490AA")
    case .red: return Color(hex: "D88B8B")
    }
  }
}

enum AppFont: String, CaseIterable {
  case rounded = "Rounded"
  case mono = "Mono"
  case serif = "Serif"
  case sansSerif = "Sans Serif"
  
  var design: Font.Design {
    switch self {
    case .rounded: return .rounded
    case .mono: return .monospaced
    case .serif: return .serif
    case .sansSerif: return .default
    }
  }
}

@Observable
final class AppSettings {
  static let shared = AppSettings()
  
  var hapticsEnabled: Bool {
    didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") }
  }
  var timerHapticsEnabled: Bool {
    didSet { UserDefaults.standard.set(timerHapticsEnabled, forKey: "timerHapticsEnabled") }
  }
  var fallingAnimationEnabled: Bool {
    didSet { UserDefaults.standard.set(fallingAnimationEnabled, forKey: "fallingAnimationEnabled") }
  }
  var colorScheme: AppColorScheme {
    didSet { UserDefaults.standard.set(colorScheme.rawValue, forKey: "colorScheme") }
  }
  var accentColor: AccentColor {
    didSet { UserDefaults.standard.set(accentColor.rawValue, forKey: "accentColor") }
  }
  var circleThickness: Double {
    didSet { UserDefaults.standard.set(circleThickness, forKey: "circleThickness") }
  }
  var appFont: AppFont {
    didSet { UserDefaults.standard.set(appFont.rawValue, forKey: "appFont") }
  }
  
  private init() {
    self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    self.timerHapticsEnabled = UserDefaults.standard.object(forKey: "timerHapticsEnabled") as? Bool ?? true
    self.fallingAnimationEnabled = UserDefaults.standard.object(forKey: "fallingAnimationEnabled") as? Bool ?? true
    self.colorScheme = AppColorScheme(rawValue: UserDefaults.standard.string(forKey: "colorScheme") ?? "") ?? .system
    self.accentColor = AccentColor(rawValue: UserDefaults.standard.string(forKey: "accentColor") ?? "") ?? .brown
    self.circleThickness = UserDefaults.standard.object(forKey: "circleThickness") as? Double ?? 6.0
    self.appFont = AppFont(rawValue: UserDefaults.standard.string(forKey: "appFont") ?? "") ?? .rounded
  }
  
  var accent: Color {
    Color(light: accentColor.light, dark: accentColor.dark)
  }
  
  var accentSubtle: Color {
    Color(light: accentColor.light.opacity(0.3), dark: accentColor.dark.opacity(0.3))
  }
  
  var preferredColorScheme: ColorScheme? {
    switch colorScheme {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }
}

// MARK: - Models

@Model
final class FocusActivityModel {
  var id: UUID
  var name: String
  var emoji: String
  var isCustom: Bool
  var createdAt: Date
  
  init(name: String, emoji: String, isCustom: Bool = false) {
    self.id = UUID()
    self.name = name
    self.emoji = emoji
    self.isCustom = isCustom
    self.createdAt = Date()
  }
}

@Model
final class FocusSession {
  var id: UUID
  var activityName: String
  var activityEmoji: String
  var collectedCount: Int
  var durationSeconds: Int
  var date: Date
  
  init(activityName: String, activityEmoji: String, collectedCount: Int, durationSeconds: Int = 30) {
    self.id = UUID()
    self.activityName = activityName
    self.activityEmoji = activityEmoji
    self.collectedCount = collectedCount
    self.durationSeconds = durationSeconds
    self.date = Date()
  }
}

// MARK: - Theme

struct FocusTheme {
  static let beige = Color(light: Color(hex: "F5F0E8"), dark: Color(hex: "1C1917"))
  static let cardBackground = Color(light: Color(hex: "FFFFFF").opacity(0.7), dark: Color(hex: "292524").opacity(0.7))
  static let subtle = Color(light: Color(hex: "D4C4B5"), dark: Color(hex: "44403C"))
  static let coinFill = Color(light: Color(hex: "FAF7F2"), dark: Color(hex: "292524"))
}

extension Color {
  init(light: Color, dark: Color) {
    self.init(uiColor: UIColor { traits in
      traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
    })
  }
  
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    default: (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
  }
}

// MARK: - Physics

struct PhysicsEmoji: Identifiable {
  let id = UUID()
  let emoji: String
  var x: CGFloat
  var y: CGFloat
  var vx: CGFloat
  var vy: CGFloat
  var rotation: Double
  var rotationVelocity: Double
  var mass: CGFloat = 1.0
  var isResting: Bool = false
  var restFrames: Int = 0
}

@Observable
final class PhysicsEngine {
  var emojis: [PhysicsEmoji] = []
  private var displayLink: CADisplayLink?
  private var bounds: CGRect = .zero
  
  private let baseGravity: CGFloat = 1200
  private let restitution: CGFloat = 0.65
  private let friction: CGFloat = 0.4
  private let airDamping: CGFloat = 0.995
  private let emojiRadius: CGFloat = 24
  private let restVelocityThreshold: CGFloat = 15
  private let restFramesRequired: Int = 30
  
  var gravityX: CGFloat = 0
  var gravityY: CGFloat = 1
  
  private let motionManager = CMMotionManager()
  
  func configure(bounds: CGRect) {
    self.bounds = bounds
  }
  
  func spawn(emoji: String) {
    let newEmoji = PhysicsEmoji(
      emoji: emoji,
      x: bounds.width / 2 + CGFloat.random(in: -30...30),
      y: bounds.minY - 50,
      vx: CGFloat.random(in: -50...50),
      vy: CGFloat.random(in: 0...100),
      rotation: 0,
      rotationVelocity: Double.random(in: -120...120),
      mass: 1.0
    )
    emojis.append(newEmoji)
  }
  
  func start() {
    guard displayLink == nil else { return }
    displayLink = CADisplayLink(target: self, selector: #selector(update))
    displayLink?.add(to: .main, forMode: .common)
    startMotionUpdates()
  }
  
  func stop() {
    displayLink?.invalidate()
    displayLink = nil
    motionManager.stopDeviceMotionUpdates()
  }
  
  func clear() -> Int {
    let count = emojis.count
    emojis.removeAll()
    return count
  }
  
  private func startMotionUpdates() {
    guard motionManager.isDeviceMotionAvailable else { return }
    motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
    motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
      guard let motion = motion, let self = self else { return }
      
      let orientation = UIDevice.current.orientation
      var gx = CGFloat(motion.gravity.x)
      var gy = CGFloat(-motion.gravity.y)
      
      switch orientation {
      case .landscapeLeft:
        gx = CGFloat(-motion.gravity.y)
        gy = CGFloat(-motion.gravity.x)
      case .landscapeRight:
        gx = CGFloat(motion.gravity.y)
        gy = CGFloat(motion.gravity.x)
      case .portraitUpsideDown:
        gx = CGFloat(-motion.gravity.x)
        gy = CGFloat(motion.gravity.y)
      default:
        break
      }
      
      self.gravityX = gx
      self.gravityY = gy
    }
  }
  
  @objc private func update(link: CADisplayLink) {
    let dt = min(CGFloat(link.targetTimestamp - link.timestamp), 0.032)
    guard dt > 0, bounds.width > 0 else { return }
    
    let gx = gravityX * baseGravity
    let gy = gravityY * baseGravity
    
    let minX = bounds.minX + emojiRadius
    let maxX = bounds.maxX - emojiRadius
    let minY = bounds.minY + emojiRadius
    let maxY = bounds.maxY - emojiRadius
    
    for i in emojis.indices {
      if emojis[i].isResting {
        let totalForce = sqrt(gx * gx + gy * gy)
        let tiltThreshold: CGFloat = 200
        if totalForce > tiltThreshold || abs(gravityX) > 0.15 {
          emojis[i].isResting = false
          emojis[i].restFrames = 0
          emojis[i].vx += gx * dt * 2
          emojis[i].vy += gy * dt * 2
        }
        continue
      }
      
      emojis[i].vx += gx * dt
      emojis[i].vy += gy * dt
      
      emojis[i].vx *= airDamping
      emojis[i].vy *= airDamping
      
      emojis[i].x += emojis[i].vx * dt
      emojis[i].y += emojis[i].vy * dt
      emojis[i].rotation += emojis[i].rotationVelocity * Double(dt)
      emojis[i].rotationVelocity *= 0.98
      
      if emojis[i].x < minX {
        emojis[i].x = minX
        emojis[i].vx = abs(emojis[i].vx) * restitution
        emojis[i].rotationVelocity *= -0.5
      }
      if emojis[i].x > maxX {
        emojis[i].x = maxX
        emojis[i].vx = -abs(emojis[i].vx) * restitution
        emojis[i].rotationVelocity *= -0.5
      }
      if emojis[i].y < minY {
        emojis[i].y = minY
        emojis[i].vy = abs(emojis[i].vy) * restitution
      }
      if emojis[i].y > maxY {
        emojis[i].y = maxY
        if emojis[i].vy > 0 {
          emojis[i].vy = -emojis[i].vy * restitution
          emojis[i].vx *= (1 - friction)
          emojis[i].rotationVelocity *= 0.7
        }
      }
    }
    
    for i in emojis.indices {
      guard !emojis[i].isResting else { continue }
      for j in (i + 1)..<emojis.count {
        guard !emojis[j].isResting || !emojis[i].isResting else { continue }
        
        let dx = emojis[j].x - emojis[i].x
        let dy = emojis[j].y - emojis[i].y
        let dist = sqrt(dx * dx + dy * dy)
        let minDist = emojiRadius * 2
        
        if dist < minDist && dist > 0.001 {
          let nx = dx / dist
          let ny = dy / dist
          let overlap = minDist - dist
          
          let separationX = nx * overlap * 0.5
          let separationY = ny * overlap * 0.5
          
          if !emojis[i].isResting {
            emojis[i].x -= separationX
            emojis[i].y -= separationY
          }
          if !emojis[j].isResting {
            emojis[j].x += separationX
            emojis[j].y += separationY
          }
          
          let dvx = emojis[i].vx - emojis[j].vx
          let dvy = emojis[i].vy - emojis[j].vy
          let dvn = dvx * nx + dvy * ny
          
          if dvn > 0 {
            let impulse = dvn * (1 + restitution) * 0.5
            
            if !emojis[i].isResting {
              emojis[i].vx -= impulse * nx
              emojis[i].vy -= impulse * ny
              emojis[i].restFrames = 0
            }
            if !emojis[j].isResting {
              emojis[j].vx += impulse * nx
              emojis[j].vy += impulse * ny
              emojis[j].restFrames = 0
            }
            
            let tangentImpulse = (dvx * (-ny) + dvy * nx) * 0.1
            emojis[i].rotationVelocity += Double(tangentImpulse * 2)
            emojis[j].rotationVelocity -= Double(tangentImpulse * 2)
          }
        }
      }
    }
    
    for i in emojis.indices {
      guard !emojis[i].isResting else { continue }
      
      let speed = sqrt(emojis[i].vx * emojis[i].vx + emojis[i].vy * emojis[i].vy)
      let nearEdge = emojis[i].y >= maxY - 1 || emojis[i].x <= minX + 1 || emojis[i].x >= maxX - 1
      
      if speed < restVelocityThreshold && nearEdge && abs(gravityX) < 0.1 && abs(gravityY - 1) < 0.1 {
        emojis[i].restFrames += 1
        if emojis[i].restFrames >= restFramesRequired {
          emojis[i].isResting = true
          emojis[i].vx = 0
          emojis[i].vy = 0
          emojis[i].rotationVelocity = 0
        }
      } else {
        emojis[i].restFrames = max(0, emojis[i].restFrames - 2)
      }
    }
  }
}

// MARK: - View Model

@Observable
final class FocusViewModel {
  var selectedActivity: FocusActivityModel?
  var isRunning = false
  var elapsed: Double = 0
  var totalCollected: Int = 0
  var todayFocusSeconds: Int = 0
  var showActivityPicker = false
  var showSettings = false
  var showStats = false
  var showResetAlert = false
  var isCreatingActivity = false
  var isEditingActivity = false
  var editingActivity: FocusActivityModel?
  var newActivityName = ""
  var newActivityEmoji = "🎯"
  var isCollecting = false
  var lastRemainingSeconds: Int = 30
  var cycleCompleted = false
  var pendingCoinsNoAnimation: Int = 0
  
  let physics = PhysicsEngine()
  let cycleDuration: Double = 30
  let streakThreshold: Int = 600
  private var timer: Timer?
  private var tickCounter: Int = 0
  private var currentLiveActivity: ActivityKit.Activity<FocusActivityAttributes>?
  
  var progress: Double { elapsed / cycleDuration }
  var remainingSeconds: Int { Int(ceil(cycleDuration - elapsed)) }
  var pendingCount: Int {
    AppSettings.shared.fallingAnimationEnabled ? physics.emojis.count : pendingCoinsNoAnimation
  }
  var canCollect: Bool { pendingCount > 0 }
  
  var streakProgress: Double {
    min(Double(todayFocusSeconds) / Double(streakThreshold), 1.0)
  }
  
  var currentStreakLevel: Int {
    todayFocusSeconds / streakThreshold
  }
  
  var secondsToNextStreak: Int {
    let remaining = streakThreshold - (todayFocusSeconds % streakThreshold)
    return todayFocusSeconds >= streakThreshold && todayFocusSeconds % streakThreshold == 0 ? 0 : remaining
  }
  
  func toggle() {
    isRunning ? pause() : start()
  }
  
  func start() {
    isRunning = true
    physics.start()
    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.tick()
    }
    startLiveActivity()
  }
  
  func pause() {
    isRunning = false
    timer?.invalidate()
    timer = nil
    updateLiveActivity()
  }
  
  func reset() {
    pause()
    elapsed = 0
    tickCounter = 0
    physics.stop()
    endLiveActivity()
  }
  
  // MARK: - Live Activity
  
  private func startLiveActivity() {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    
    let attributes = FocusActivityAttributes(startTime: Date())
    let state = FocusActivityAttributes.ContentState(
      remainingSeconds: remainingSeconds,
      elapsed: elapsed,
      cycleDuration: cycleDuration,
      activityEmoji: selectedActivity?.emoji ?? "🎯",
      activityName: selectedActivity?.name ?? "Focus",
      todayFocusSeconds: todayFocusSeconds,
      currentStreakLevel: currentStreakLevel,
      isRunning: isRunning
    )
    
    do {
      let activity = try ActivityKit.Activity.request(
        attributes: attributes,
        content: ActivityContent(state: state, staleDate: nil),
        pushType: nil
      )
      currentLiveActivity = activity
    } catch {
      print("Failed to start Live Activity: \(error)")
    }
  }
  
  private func updateLiveActivity() {
    guard let activity = currentLiveActivity else { return }
    
    let state = FocusActivityAttributes.ContentState(
      remainingSeconds: remainingSeconds,
      elapsed: elapsed,
      cycleDuration: cycleDuration,
      activityEmoji: selectedActivity?.emoji ?? "🎯",
      activityName: selectedActivity?.name ?? "Focus",
      todayFocusSeconds: todayFocusSeconds,
      currentStreakLevel: currentStreakLevel,
      isRunning: isRunning
    )
    
    Task {
      await activity.update(ActivityContent(state: state, staleDate: nil))
    }
  }
  
  private func endLiveActivity() {
    guard let activity = currentLiveActivity else { return }
    
    let state = FocusActivityAttributes.ContentState(
      remainingSeconds: remainingSeconds,
      elapsed: elapsed,
      cycleDuration: cycleDuration,
      activityEmoji: selectedActivity?.emoji ?? "🎯",
      activityName: selectedActivity?.name ?? "Focus",
      todayFocusSeconds: todayFocusSeconds,
      currentStreakLevel: currentStreakLevel,
      isRunning: false
    )
    
    Task {
      await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
    }
    currentLiveActivity = nil
  }
  
  func collect(modelContext: ModelContext) {
    guard canCollect, let activity = selectedActivity else { return }
    isCollecting = true
    
    let count: Int
    if AppSettings.shared.fallingAnimationEnabled {
      count = physics.clear()
    } else {
      count = pendingCoinsNoAnimation
      pendingCoinsNoAnimation = 0
    }
    
    let duration = count * Int(cycleDuration)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
        self?.totalCollected += count
      }
      self?.isCollecting = false
    }
    
    let session = FocusSession(activityName: activity.name, activityEmoji: activity.emoji, collectedCount: count, durationSeconds: duration)
    modelContext.insert(session)
  }
  
  private func tick() {
    elapsed += 0.1
    tickCounter += 1
    
    if tickCounter >= 10 {
      tickCounter = 0
      todayFocusSeconds += 1
      updateLiveActivity()
    }
    
    let newRemaining = remainingSeconds
    if newRemaining != lastRemainingSeconds {
      lastRemainingSeconds = newRemaining
    }
    
    if elapsed >= cycleDuration {
      elapsed = 0
      cycleCompleted = true
      if AppSettings.shared.fallingAnimationEnabled {
        if let emoji = selectedActivity?.emoji {
          physics.spawn(emoji: emoji)
        }
      } else {
        pendingCoinsNoAnimation += 1
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.cycleCompleted = false
      }
    }
  }
  
  func selectActivity(_ activity: FocusActivityModel) {
    selectedActivity = activity
    isCreatingActivity = false
    isEditingActivity = false
    editingActivity = nil
    showActivityPicker = false
  }
  
  func startCreatingActivity() {
    isCreatingActivity = true
    isEditingActivity = false
    editingActivity = nil
    newActivityName = ""
    newActivityEmoji = "🎯"
  }
  
  func startEditingActivity(_ activity: FocusActivityModel) {
    isEditingActivity = true
    isCreatingActivity = false
    editingActivity = activity
    newActivityName = activity.name
    newActivityEmoji = activity.emoji
  }
  
  func cancelCreatingActivity() {
    isCreatingActivity = false
    isEditingActivity = false
    editingActivity = nil
    newActivityName = ""
    newActivityEmoji = "🎯"
  }
  
  func addActivity(modelContext: ModelContext) {
    guard !newActivityName.isEmpty else { return }
    let activity = FocusActivityModel(name: newActivityName, emoji: newActivityEmoji, isCustom: true)
    modelContext.insert(activity)
    selectedActivity = activity
    isCreatingActivity = false
    isEditingActivity = false
    editingActivity = nil
    showActivityPicker = false
    newActivityName = ""
    newActivityEmoji = "🎯"
  }
  
  func saveEditedActivity() {
    guard !newActivityName.isEmpty, let activity = editingActivity else { return }
    activity.name = newActivityName
    activity.emoji = newActivityEmoji
    isEditingActivity = false
    isCreatingActivity = false
    editingActivity = nil
    showActivityPicker = false
    newActivityName = ""
    newActivityEmoji = "🎯"
  }
  
  func deleteActivity(_ activity: FocusActivityModel, modelContext: ModelContext) {
    if selectedActivity?.id == activity.id { selectedActivity = nil }
    modelContext.delete(activity)
  }
  
  func loadTotalCollected(sessions: [FocusSession]) {
    totalCollected = sessions.reduce(0) { $0 + $1.collectedCount }
    
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    todayFocusSeconds = sessions
      .filter { calendar.isDate($0.date, inSameDayAs: today) }
      .reduce(0) { $0 + $1.durationSeconds }
  }
  
  func initializeDefaultActivities(existing: [FocusActivityModel], modelContext: ModelContext) {
    guard existing.isEmpty else {
      selectedActivity = existing.first
      return
    }
    let defaults = [
      ("Focus", "🎯"), ("Work", "💼"), ("Code", "💻"), ("Read", "📚"),
      ("Write", "✍️"), ("Think", "🧠"), ("Meditate", "🧘"), ("Move", "🏃"),
      ("Create", "🎨"), ("Play", "🎮"), ("Social", "💬"), ("Rest", "😴")
    ]
    for (name, emoji) in defaults {
      modelContext.insert(FocusActivityModel(name: name, emoji: emoji, isCustom: false))
    }
    try? modelContext.save()
  }
}

// MARK: - UI Components

struct UIKitTextField: UIViewRepresentable {
  @Binding var text: String
  var placeholder: String
  var onSubmit: (() -> Void)?
  
  func makeUIView(context: Context) -> UITextField {
    let textField = UITextField()
    textField.placeholder = placeholder
    textField.font = .systemFont(ofSize: 17)
    textField.borderStyle = .none
    textField.autocorrectionType = .no
    textField.returnKeyType = .done
    textField.delegate = context.coordinator
    textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
    return textField
  }
  
  func updateUIView(_ uiView: UITextField, context: Context) {
    if uiView.text != text { uiView.text = text }
  }
  
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  
  class Coordinator: NSObject, UITextFieldDelegate {
    var parent: UIKitTextField
    init(_ parent: UIKitTextField) { self.parent = parent }
    @objc func textChanged(_ textField: UITextField) { parent.text = textField.text ?? "" }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      textField.resignFirstResponder()
      parent.onSubmit?()
      return true
    }
  }
}

struct CircularProgressView: View {
  let progress: Double
  let lineWidth: CGFloat
  let isActive: Bool
  var settings = AppSettings.shared
  
  var body: some View {
    ZStack {
      Circle()
        .stroke(FocusTheme.subtle.opacity(isActive ? 0.3 : 1), lineWidth: lineWidth)
      
      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          settings.accent,
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(.linear(duration: 0.1), value: progress)
      
      if isActive {
        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            settings.accent.opacity(0.4),
            style: StrokeStyle(lineWidth: lineWidth + 8, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
          .blur(radius: 8)
          .animation(.linear(duration: 0.1), value: progress)
      }
    }
  }
}

struct StreakProgressBar: View {
  let currentStreak: Int
  let progress: Double
  let secondsRemaining: Int
  var settings = AppSettings.shared
  
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "flame.fill")
        .foregroundStyle(progress >= 1 ? settings.accent : .secondary)
        .font(.system(size: 14))
      
      Text("\(currentStreak)")
        .font(.system(size: 14, weight: .bold, design: settings.appFont.design))
        .foregroundStyle(progress >= 1 ? settings.accent : .primary)
        .contentTransition(.numericText())
        .animation(.spring(response: 0.3), value: currentStreak)
      
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(FocusTheme.subtle.opacity(0.3))
          
          Capsule()
            .fill(settings.accent)
            .frame(width: geo.size.width * progress)
            .animation(.spring(response: 0.3), value: progress)
        }
      }
      .frame(width: 60, height: 6)
      
      Text("\(currentStreak + 1)")
        .font(.system(size: 14, weight: .medium, design: settings.appFont.design))
        .foregroundStyle(.secondary)
      
      if secondsRemaining > 0 && progress < 1 {
        Text(formatTimeShort(secondsRemaining))
          .font(.system(size: 11, design: settings.appFont.design))
          .foregroundStyle(.tertiary)
          .monospacedDigit()
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(FocusTheme.cardBackground)
    .clipShape(Capsule())
  }
  
  private func formatTimeShort(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%d:%02d", m, s)
  }
}

struct StatCard: View {
  let value: Int
  let label: String
  var isClickable: Bool = false
  var action: (() -> Void)? = nil
  @State private var tapped = false
  var settings = AppSettings.shared
  
  var body: some View {
    Group {
      if isClickable, let action = action {
        Button {
          tapped.toggle()
          action()
        } label: { cardContent }
          .buttonStyle(.plain)
          .sensoryFeedback(.impact(weight: .light), trigger: tapped, condition: { _, _ in settings.hapticsEnabled })
      } else {
        cardContent
      }
    }
  }
  
  private var cardContent: some View {
    VStack(spacing: 4) {
      Text("\(value)")
        .font(.system(size: 22, weight: .semibold, design: settings.appFont.design))
        .foregroundStyle(.primary)
        .contentTransition(.numericText())
        .animation(.spring(response: 0.3), value: value)
      Text(label)
        .font(.system(size: 10, design: settings.appFont.design))
        .textCase(.uppercase)
        .tracking(1)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(isClickable && value > 0 ? settings.accentSubtle : FocusTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(isClickable && value > 0 ? settings.accent : Color.clear, lineWidth: 1.5)
    )
  }
}

struct ActivityButton: View {
  let emoji: String
  let name: String
  let isSelected: Bool
  let action: () -> Void
  @State private var tapped = false
  var settings = AppSettings.shared
  
  var body: some View {
    Button {
      tapped.toggle()
      action()
    } label: {
      VStack(spacing: 8) {
        Text(emoji).font(.largeTitle)
        Text(name)
          .font(.system(size: 12, design: settings.appFont.design))
          .foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(isSelected ? settings.accentSubtle : FocusTheme.cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? settings.accent : Color.clear, lineWidth: 2))
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.impact(weight: .light), trigger: tapped, condition: { _, _ in settings.hapticsEnabled })
  }
}

struct EmojiPickerView: View {
  @Binding var selected: String
  @State private var tapped = false
  var settings = AppSettings.shared
  let emojis = ["🎯", "🧘", "💼", "💻", "💪", "⚽", "📚", "✍️", "🎵", "🎨",
                "🏃", "🚴", "🏊", "🧗", "🎮", "🎬", "📷", "🔬", "🧪", "🌱",
                "☕", "🍳", "🧹", "💤", "🙏", "💡", "🎓", "📝", "🗣️", "🤝",
                "🧠", "❤️", "⭐", "🔥", "💎", "🏆"]
  let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
  
  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(emojis, id: \.self) { emoji in
        Button {
          tapped.toggle()
          selected = emoji
        } label: {
          Text(emoji)
            .font(.title2)
            .frame(width: 44, height: 44)
            .background(selected == emoji ? settings.accentSubtle : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
      }
    }
    .sensoryFeedback(.impact(weight: .light), trigger: tapped, condition: { _, _ in settings.hapticsEnabled })
  }
}

struct PhysicsEmojisView: View {
  let emojis: [PhysicsEmoji]
  let coinSize: CGFloat = 48
  var settings = AppSettings.shared
  
  @Environment(\.colorScheme) var colorScheme
  
  var coinFill: Color {
    colorScheme == .dark ? Color(hex: "292524") : Color(hex: "FAF7F2")
  }
  
  var coinStroke: Color {
    settings.accent
  }
  
  var body: some View {
    Canvas { context, size in
      for emoji in emojis {
        context.drawLayer { ctx in
          ctx.translateBy(x: emoji.x, y: emoji.y)
          
          let coinRect = CGRect(x: -coinSize/2, y: -coinSize/2, width: coinSize, height: coinSize)
          
          ctx.fill(
            Circle().path(in: coinRect),
            with: .color(coinFill)
          )
          
          ctx.stroke(
            Circle().path(in: coinRect),
            with: .color(coinStroke),
            lineWidth: 2
          )
          
          ctx.draw(
            Text(emoji.emoji).font(.system(size: coinSize * 0.5)),
            at: .zero
          )
        }
      }
    }
  }
}

// MARK: - Settings View

struct SettingsView: View {
  @Bindable var settings = AppSettings.shared
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    NavigationStack {
      Form {
        Section("Haptics") {
          Toggle("Button Haptics", isOn: $settings.hapticsEnabled)
          Toggle("Timer Haptics", isOn: $settings.timerHapticsEnabled)
        }
        
        Section("Animations") {
          Toggle("Falling Coins Animation", isOn: $settings.fallingAnimationEnabled)
        }
        
        Section("Appearance") {
          Picker("Theme", selection: $settings.colorScheme) {
            ForEach(AppColorScheme.allCases, id: \.self) { scheme in
              Text(scheme.rawValue).tag(scheme)
            }
          }
          
          Picker("Accent Color", selection: $settings.accentColor) {
            ForEach(AccentColor.allCases, id: \.self) { color in
              HStack {
                Circle()
                  .fill(color.light)
                  .frame(width: 20, height: 20)
                Text(color.rawValue)
              }
              .tag(color)
            }
          }
        }
        
        Section("Timer") {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Circle Thickness")
              Spacer()
              Text("\(Int(settings.circleThickness))")
                .foregroundStyle(.secondary)
            }
            Slider(value: $settings.circleThickness, in: 2...16, step: 1)
              .tint(settings.accent)
          }
          
          HStack {
            Text("Preview")
            Spacer()
            CircularProgressView(progress: 0.7, lineWidth: settings.circleThickness, isActive: false)
              .frame(width: 50, height: 50)
          }
        }
        
        Section("Typography") {
          Picker("Font Style", selection: $settings.appFont) {
            ForEach(AppFont.allCases, id: \.self) { font in
              Text(font.rawValue)
                .font(.system(size: 16, design: font.design))
                .tag(font)
            }
          }
          
          HStack {
            Text("Preview")
            Spacer()
            Text("30")
              .font(.system(size: 32, weight: .ultraLight, design: settings.appFont.design))
              .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

// MARK: - Stats View

struct DayStats: Identifiable {
  let id = UUID()
  let date: Date
  let totalSeconds: Int
  let sessions: [FocusSession]
  let activityBreakdown: [(emoji: String, name: String, seconds: Int)]
  let totalCoins: Int
  
  var hasStreak: Bool { totalSeconds >= 600 }
  
  var formattedTime: String {
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    if hours > 0 {
      return String(format: "%dh %dm %ds", hours, minutes, seconds)
    } else if minutes > 0 {
      return String(format: "%dm %ds", minutes, seconds)
    }
    return String(format: "%ds", seconds)
  }
}

struct CoinData: Identifiable {
  let id = UUID()
  let emoji: String
  let activityName: String
  let date: Date
}

struct StatsView: View {
  let sessions: [FocusSession]
  @Environment(\.dismiss) var dismiss
  @State private var selectedDate: Date = Date()
  @State private var showStreakInfo = false
  @State private var showBestStreakInfo = false
  @State private var showCoinsView = false
  var settings = AppSettings.shared
  
  private let calendar = Calendar.current
  private let streakThreshold = 600
  
  var dayStats: [Date: DayStats] {
    var stats: [Date: DayStats] = [:]
    let grouped = Dictionary(grouping: sessions) { session in
      calendar.startOfDay(for: session.date)
    }
    
    for (date, daySessions) in grouped {
      let totalSeconds = daySessions.reduce(0) { $0 + $1.durationSeconds }
      let totalCoins = daySessions.reduce(0) { $0 + $1.collectedCount }
      
      var activityTotals: [String: (emoji: String, seconds: Int)] = [:]
      for session in daySessions {
        let existing = activityTotals[session.activityName] ?? (session.activityEmoji, 0)
        activityTotals[session.activityName] = (session.activityEmoji, existing.seconds + session.durationSeconds)
      }
      
      let breakdown = activityTotals.map { (emoji: $0.value.emoji, name: $0.key, seconds: $0.value.seconds) }
        .sorted { $0.seconds > $1.seconds }
      
      stats[date] = DayStats(date: date, totalSeconds: totalSeconds, sessions: daySessions, activityBreakdown: breakdown, totalCoins: totalCoins)
    }
    
    return stats
  }
  
  var currentStreak: Int {
    var streak = 0
    var checkDate = calendar.startOfDay(for: Date())
    
    if let todayStats = dayStats[checkDate], todayStats.hasStreak {
      streak = 1
      checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
    } else {
      checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
    }
    
    while let stats = dayStats[checkDate], stats.hasStreak {
      streak += 1
      checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
    }
    
    return streak
  }
  
  var longestStreak: Int {
    let sortedDates = dayStats.keys.sorted()
    var longest = 0
    var current = 0
    var previousDate: Date?
    
    for date in sortedDates {
      guard let stats = dayStats[date], stats.hasStreak else {
        current = 0
        previousDate = date
        continue
      }
      
      if let prev = previousDate,
         let daysDiff = calendar.dateComponents([.day], from: prev, to: date).day,
         daysDiff == 1 {
        current += 1
      } else {
        current = 1
      }
      
      longest = max(longest, current)
      previousDate = date
    }
    
    return longest
  }
  
  var totalFocusTime: Int {
    sessions.reduce(0) { $0 + $1.durationSeconds }
  }
  
  var totalCoins: Int {
    sessions.reduce(0) { $0 + $1.collectedCount }
  }
  
  var allCoins: [CoinData] {
    var coins: [CoinData] = []
    for session in sessions {
      for _ in 0..<session.collectedCount {
        coins.append(CoinData(emoji: session.activityEmoji, activityName: session.activityName, date: session.date))
      }
    }
    return coins.reversed()
  }
  
  var last30Days: [Date] {
    (0..<30).compactMap { offset in
      calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date()))
    }
  }
  
  var selectedDayStats: DayStats? {
    dayStats[calendar.startOfDay(for: selectedDate)]
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          streakHeader
          totalStatsRow
          calendarStrip
          selectedDayDetail
        }
        .padding()
      }
      .background(FocusTheme.beige)
      .navigationTitle("Statistics")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
      .sheet(isPresented: $showStreakInfo) { streakInfoSheet }
      .sheet(isPresented: $showBestStreakInfo) { bestStreakInfoSheet }
      .sheet(isPresented: $showCoinsView) { CoinsCollectionView(coins: allCoins) }
    }
  }
  
  private var streakHeader: some View {
    HStack(spacing: 16) {
      Button { showStreakInfo = true } label: {
        streakCard(value: currentStreak, label: "Current Streak", icon: "flame.fill")
      }
      .buttonStyle(.plain)
      
      Button { showBestStreakInfo = true } label: {
        streakCard(value: longestStreak, label: "Best Streak", icon: "trophy.fill")
      }
      .buttonStyle(.plain)
    }
  }
  
  private func streakCard(value: Int, label: String, icon: String) -> some View {
    VStack(spacing: 8) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .foregroundStyle(settings.accent)
        Text("\(value)")
          .font(.system(size: 28, weight: .bold, design: settings.appFont.design))
          .contentTransition(.numericText())
      }
      Text(label)
        .font(.system(size: 11, design: settings.appFont.design))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(0.5)
      
      Image(systemName: "info.circle")
        .font(.system(size: 10))
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(FocusTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
  
  private var totalStatsRow: some View {
    HStack(spacing: 12) {
      VStack(spacing: 4) {
        Text(formatTotalTime(totalFocusTime))
          .font(.system(size: 18, weight: .semibold, design: settings.appFont.design))
        Text("Total Time")
          .font(.system(size: 10, design: settings.appFont.design))
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(FocusTheme.cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      
      Button { showCoinsView = true } label: {
        VStack(spacing: 4) {
          HStack(spacing: 4) {
            Image(systemName: "circle.fill")
              .font(.system(size: 10))
              .foregroundStyle(settings.accent)
            Text("\(totalCoins)")
              .font(.system(size: 18, weight: .semibold, design: settings.appFont.design))
          }
          Text("Coins")
            .font(.system(size: 10, design: settings.appFont.design))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(settings.accentSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(settings.accent, lineWidth: 1))
      }
      .buttonStyle(.plain)
    }
  }
  
  private func formatTotalTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60
    if hours > 0 {
      return String(format: "%dh %dm %ds", hours, minutes, secs)
    } else if minutes > 0 {
      return String(format: "%dm %ds", minutes, secs)
    }
    return String(format: "%ds", secs)
  }
  
  private var calendarStrip: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Last 30 Days")
        .font(.system(size: 13, weight: .semibold, design: settings.appFont.design))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(0.5)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(last30Days, id: \.self) { date in
            dayCell(for: date)
          }
        }
        .padding(.horizontal, 4)
      }
    }
  }
  
  private func dayCell(for date: Date) -> some View {
    let stats = dayStats[calendar.startOfDay(for: date)]
    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
    let isToday = calendar.isDateInToday(date)
    let hasStreak = stats?.hasStreak ?? false
    
    return Button {
      withAnimation(.spring(response: 0.3)) {
        selectedDate = date
      }
    } label: {
      VStack(spacing: 6) {
        Text(dayOfWeek(date))
          .font(.system(size: 10, design: settings.appFont.design))
          .foregroundStyle(.secondary)
        
        ZStack {
          Circle()
            .fill(isSelected ? settings.accent : (hasStreak ? settings.accentSubtle : FocusTheme.cardBackground))
            .frame(width: 40, height: 40)
          
          Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: settings.appFont.design))
            .foregroundStyle(isSelected ? .white : .primary)
        }
        
        if hasStreak {
          Image(systemName: "flame.fill")
            .font(.system(size: 10))
            .foregroundStyle(settings.accent)
        } else {
          Color.clear.frame(height: 10)
        }
        
        if let stats = stats {
          Text(stats.formattedTime)
            .font(.system(size: 9, design: settings.appFont.design))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        } else {
          Text("0s")
            .font(.system(size: 9, design: settings.appFont.design))
            .foregroundStyle(.tertiary)
        }
      }
      .frame(width: 55)
      .padding(.vertical, 8)
      .background(isToday && !isSelected ? settings.accentSubtle.opacity(0.3) : Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
  }
  
  private func dayOfWeek(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter.string(from: date).uppercased()
  }
  
  private var selectedDayDetail: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(formattedSelectedDate)
          .font(.system(size: 17, weight: .semibold, design: settings.appFont.design))
        
        Spacer()
        
        if let stats = selectedDayStats {
          HStack(spacing: 4) {
            if stats.hasStreak {
              Image(systemName: "flame.fill")
                .foregroundStyle(settings.accent)
            }
            Text(stats.formattedTime)
              .font(.system(size: 15, weight: .medium, design: settings.appFont.design))
              .foregroundStyle(settings.accent)
          }
        }
      }
      
      if let stats = selectedDayStats {
        HStack(spacing: 4) {
          Image(systemName: "circle.fill")
            .font(.system(size: 8))
            .foregroundStyle(settings.accent)
          Text("\(stats.totalCoins) coins collected")
            .font(.system(size: 13, design: settings.appFont.design))
            .foregroundStyle(.secondary)
        }
      }
      
      if let stats = selectedDayStats, !stats.activityBreakdown.isEmpty {
        VStack(spacing: 12) {
          ForEach(stats.activityBreakdown, id: \.name) { activity in
            activityRow(emoji: activity.emoji, name: activity.name, seconds: activity.seconds, total: stats.totalSeconds)
          }
        }
      } else {
        VStack(spacing: 12) {
          Image(systemName: "moon.zzz")
            .font(.system(size: 32))
            .foregroundStyle(.tertiary)
          Text("No focus sessions")
            .font(.system(size: 14, design: settings.appFont.design))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
      }
    }
    .padding(16)
    .background(FocusTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
  
  private func activityRow(emoji: String, name: String, seconds: Int, total: Int) -> some View {
    let percentage = total > 0 ? Double(seconds) / Double(total) : 0
    let minutes = seconds / 60
    let secs = seconds % 60
    
    return VStack(spacing: 8) {
      HStack {
        Text(emoji)
          .font(.title3)
        Text(name)
          .font(.system(size: 14, weight: .medium, design: settings.appFont.design))
        Spacer()
        Text(minutes > 0 ? "\(minutes)m \(secs)s" : "\(secs)s")
          .font(.system(size: 14, design: settings.appFont.design))
          .foregroundStyle(.secondary)
      }
      
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(FocusTheme.subtle.opacity(0.3))
            .frame(height: 6)
          
          RoundedRectangle(cornerRadius: 4)
            .fill(settings.accent)
            .frame(width: geo.size.width * percentage, height: 6)
        }
      }
      .frame(height: 6)
    }
  }
  
  private var formattedSelectedDate: String {
    let formatter = DateFormatter()
    if calendar.isDateInToday(selectedDate) {
      return "Today"
    } else if calendar.isDateInYesterday(selectedDate) {
      return "Yesterday"
    } else {
      formatter.dateFormat = "EEEE, MMM d"
      return formatter.string(from: selectedDate)
    }
  }
  
  private var streakInfoSheet: some View {
    VStack(spacing: 20) {
      Image(systemName: "flame.fill")
        .font(.system(size: 48))
        .foregroundStyle(settings.accent)
      
      Text("Current Streak")
        .font(.system(size: 22, weight: .bold, design: settings.appFont.design))
      
      Text("Your current streak counts consecutive days where you've focused for at least 10 minutes (600 seconds).")
        .font(.system(size: 15, design: settings.appFont.design))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      
      VStack(alignment: .leading, spacing: 12) {
        infoRow(icon: "checkmark.circle.fill", text: "Focus for 10+ minutes to count a day")
        infoRow(icon: "arrow.right.circle.fill", text: "Days must be consecutive")
        infoRow(icon: "xmark.circle.fill", text: "Missing a day resets the streak")
      }
      .padding()
      .background(FocusTheme.cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      
      Spacer()
    }
    .padding(24)
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }
  
  private var bestStreakInfoSheet: some View {
    VStack(spacing: 20) {
      Image(systemName: "trophy.fill")
        .font(.system(size: 48))
        .foregroundStyle(settings.accent)
      
      Text("Best Streak")
        .font(.system(size: 22, weight: .bold, design: settings.appFont.design))
      
      Text("Your best streak is the longest consecutive run of days where you focused for at least 10 minutes each day.")
        .font(.system(size: 15, design: settings.appFont.design))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      
      VStack(alignment: .leading, spacing: 12) {
        infoRow(icon: "star.fill", text: "Your personal record")
        infoRow(icon: "chart.line.uptrend.xyaxis", text: "Keep going to beat it!")
        infoRow(icon: "calendar", text: "Based on your history")
      }
      .padding()
      .background(FocusTheme.cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      
      Spacer()
    }
    .padding(24)
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }
  
  private func infoRow(icon: String, text: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .foregroundStyle(settings.accent)
        .frame(width: 24)
      Text(text)
        .font(.system(size: 14, design: settings.appFont.design))
      Spacer()
    }
  }
}

// MARK: - Coins Collection View

struct CoinsCollectionView: View {
  let coins: [CoinData]
  @Environment(\.dismiss) var dismiss
  var settings = AppSettings.shared
  
  let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
  
  var coinsByActivity: [(emoji: String, name: String, count: Int)] {
    var totals: [String: (emoji: String, count: Int)] = [:]
    for coin in coins {
      let existing = totals[coin.activityName] ?? (coin.emoji, 0)
      totals[coin.activityName] = (coin.emoji, existing.count + 1)
    }
    return totals.map { (emoji: $0.value.emoji, name: $0.key, count: $0.value.count) }
      .sorted { $0.count > $1.count }
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          totalHeader
          
          if !coinsByActivity.isEmpty {
            breakdownSection
          }
          
          if !coins.isEmpty {
            allCoinsSection
          } else {
            emptyState
          }
        }
        .padding()
      }
      .background(FocusTheme.beige)
      .navigationTitle("Coins Collection")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
  
  private var totalHeader: some View {
    VStack(spacing: 8) {
      Text("\(coins.count)")
        .font(.system(size: 48, weight: .bold, design: settings.appFont.design))
        .foregroundStyle(settings.accent)
      Text("Total Coins Collected")
        .font(.system(size: 14, design: settings.appFont.design))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(1)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
    .background(FocusTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
  
  private var breakdownSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("By Activity")
        .font(.system(size: 13, weight: .semibold, design: settings.appFont.design))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(0.5)
      
      VStack(spacing: 8) {
        ForEach(coinsByActivity, id: \.name) { item in
          HStack {
            Text(item.emoji)
              .font(.title3)
            Text(item.name)
              .font(.system(size: 14, design: settings.appFont.design))
            Spacer()
            Text("\(item.count)")
              .font(.system(size: 14, weight: .semibold, design: settings.appFont.design))
              .foregroundStyle(settings.accent)
          }
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(FocusTheme.cardBackground)
          .clipShape(RoundedRectangle(cornerRadius: 10))
        }
      }
    }
  }
  
  private var allCoinsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("All Coins")
        .font(.system(size: 13, weight: .semibold, design: settings.appFont.design))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(0.5)
      
      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(coins) { coin in
          coinCell(emoji: coin.emoji)
        }
      }
      .padding(12)
      .background(FocusTheme.cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
  }
  
  private func coinCell(emoji: String) -> some View {
    ZStack {
      Circle()
        .fill(FocusTheme.coinFill)
        .frame(width: 44, height: 44)
      Circle()
        .stroke(settings.accent, lineWidth: 2)
        .frame(width: 44, height: 44)
      Text(emoji)
        .font(.system(size: 20))
    }
  }
  
  private var emptyState: some View {
    VStack(spacing: 12) {
      Image(systemName: "circle.dashed")
        .font(.system(size: 48))
        .foregroundStyle(.tertiary)
      Text("No coins yet")
        .font(.system(size: 16, design: settings.appFont.design))
        .foregroundStyle(.secondary)
      Text("Complete focus sessions to collect coins!")
        .font(.system(size: 14, design: settings.appFont.design))
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }
}

// MARK: - Main View

struct FocusTrackerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Query private var activities: [FocusActivityModel]
  @Query private var sessions: [FocusSession]
  @State private var viewModel = FocusViewModel()
  var settings = AppSettings.shared
  
  var isLandscape: Bool {
    horizontalSizeClass == .regular || UIScreen.main.bounds.width > UIScreen.main.bounds.height
  }
  
  var body: some View {
    GeometryReader { geo in
      ZStack {
        background
        physicsLayer(in: geo)
        
        if isLandscape {
          landscapeContent(in: geo)
        } else {
          portraitContent(in: geo)
        }
      }
      .onAppear { onAppear(geo: geo) }
      .onChange(of: geo.size) { _, _ in
        updatePhysicsBounds(geo: geo)
      }
    }
    .sheet(isPresented: $viewModel.showActivityPicker) { activityPickerSheet }
    .sheet(isPresented: $viewModel.showSettings) { SettingsView() }
    .fullScreenCover(isPresented: $viewModel.showStats) { StatsView(sessions: sessions) }
    .alert("Reset Session?", isPresented: $viewModel.showResetAlert) { resetAlertButtons }
    .sensoryFeedback(.selection, trigger: viewModel.remainingSeconds, condition: { _, _ in settings.timerHapticsEnabled })
    .sensoryFeedback(.success, trigger: viewModel.cycleCompleted, condition: { _, _ in settings.timerHapticsEnabled })
    .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.totalCollected, condition: { _, _ in settings.hapticsEnabled })
    .sensoryFeedback(.success, trigger: viewModel.currentStreakLevel, condition: { _, _ in settings.hapticsEnabled })
    .preferredColorScheme(settings.preferredColorScheme)
  }
  
  private var background: some View {
    FocusTheme.beige.ignoresSafeArea()
  }
  
  private func portraitContent(in geo: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      topBar
      
      if !viewModel.isRunning {
        activitySelector
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
      }
      
      Spacer()
      
      timerSection(size: geo.size)
      
      Spacer()
      
      if !viewModel.isRunning {
        statsRow
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
      }
      
      controlButtons
    }
    .padding()
    .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
  }
  
  private func landscapeContent(in geo: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      topBar
        .padding(.horizontal)
        .padding(.top, 8)
      
      HStack(spacing: 16) {
        VStack {
          Spacer()
          
          timerSection(size: geo.size)
          
          Spacer()
          
          if !viewModel.isRunning {
            activitySelector
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
              .padding(.bottom, 8)
          }
        }
        .frame(maxWidth: .infinity)
        
        VStack(spacing: 12) {
          Spacer()
          
          if !viewModel.isRunning {
            compactStatCard(value: viewModel.totalCollected, label: "Collected")
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            compactStatCard(value: viewModel.pendingCount, label: "Pending", isClickable: true) {
              if viewModel.canCollect {
                viewModel.collect(modelContext: modelContext)
              }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            Spacer()
          }
          
          landscapeControlButtons
        }
        .frame(width: 70)
        .padding(.trailing, 8)
      }
    }
    .padding(.horizontal, 8)
    .padding(.bottom, 8)
    .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
  }
  
  private func compactStatCard(value: Int, label: String, isClickable: Bool = false, action: (() -> Void)? = nil) -> some View {
    let content = VStack(spacing: 2) {
      Text("\(value)")
        .font(.system(size: 18, weight: .semibold, design: settings.appFont.design))
        .foregroundStyle(.primary)
        .contentTransition(.numericText())
        .animation(.spring(response: 0.3), value: value)
      Text(label)
        .font(.system(size: 8, design: settings.appFont.design))
        .textCase(.uppercase)
        .tracking(0.5)
        .foregroundStyle(.secondary)
    }
    .frame(width: 60)
    .padding(.vertical, 10)
    .background(isClickable && value > 0 ? settings.accentSubtle : FocusTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(isClickable && value > 0 ? settings.accent : Color.clear, lineWidth: 1.5)
    )
    
    if isClickable, let action = action {
      return AnyView(
        Button(action: action) { content }
          .buttonStyle(.plain)
          .sensoryFeedback(.impact(weight: .light), trigger: value, condition: { _, _ in settings.hapticsEnabled })
      )
    } else {
      return AnyView(content)
    }
  }
  
  private var landscapeControlButtons: some View {
    VStack(spacing: 12) {
      Button { viewModel.showResetAlert = true } label: {
        Image(systemName: "arrow.counterclockwise")
          .font(.body)
          .foregroundStyle(viewModel.isRunning ? .primary : .secondary)
          .frame(width: 44, height: 44)
          .background(viewModel.isRunning ? FocusTheme.cardBackground : FocusTheme.cardBackground.opacity(0.5))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.showResetAlert, condition: { _, _ in settings.hapticsEnabled })
      
      Button { viewModel.toggle() } label: {
        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
          .font(.title3)
          .foregroundStyle(.white)
          .frame(width: 56, height: 56)
          .background(settings.accent)
          .clipShape(Circle())
          .shadow(color: viewModel.isRunning ? settings.accent.opacity(0.4) : .clear, radius: 8, y: 2)
      }
      .buttonStyle(.plain)
      .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isRunning, condition: { _, _ in settings.hapticsEnabled })
    }
    .padding(.bottom, 8)
  }
  
  private var topBar: some View {
    HStack(spacing: 8) {
      StreakProgressBar(
        currentStreak: viewModel.currentStreakLevel,
        progress: viewModel.streakProgress,
        secondsRemaining: viewModel.secondsToNextStreak
      )
      .opacity(viewModel.isRunning ? 0.7 : 1)
      
      Spacer()
      
      Button { viewModel.showSettings = true } label: {
        Image(systemName: "gearshape")
          .font(.body)
          .foregroundStyle(.secondary)
          .frame(width: 36, height: 36)
          .background(FocusTheme.cardBackground)
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .opacity(viewModel.isRunning ? 0.5 : 1)
      .sensoryFeedback(.impact(weight: .light), trigger: viewModel.showSettings, condition: { _, _ in settings.hapticsEnabled })
      
      collectButton
        .opacity(viewModel.isRunning && !viewModel.canCollect ? 0.5 : 1)
    }
    .padding(.bottom, 8)
  }
  
  private var collectButton: some View {
    Button {
      if viewModel.canCollect {
        viewModel.collect(modelContext: modelContext)
      } else {
        viewModel.showStats = true
      }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: viewModel.canCollect ? "sparkles" : "chart.bar.fill")
          .foregroundStyle(settings.accent)
        Text("\(viewModel.totalCollected)")
          .fontWeight(.semibold)
          .contentTransition(.numericText())
          .animation(.spring(response: 0.3), value: viewModel.totalCollected)
        if viewModel.pendingCount > 0 {
          Text("+\(viewModel.pendingCount)")
            .font(.system(size: 12, design: settings.appFont.design))
            .foregroundStyle(settings.accent)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3), value: viewModel.pendingCount)
        }
      }
      .font(.system(size: 14, design: settings.appFont.design))
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(viewModel.canCollect ? settings.accentSubtle : FocusTheme.cardBackground)
      .clipShape(Capsule())
      .overlay(Capsule().stroke(viewModel.canCollect ? settings.accent : Color.clear, lineWidth: 1.5))
    }
    .buttonStyle(.plain)
    .animation(.spring(response: 0.3), value: viewModel.canCollect)
    .sensoryFeedback(.impact(weight: .light), trigger: viewModel.totalCollected, condition: { _, _ in settings.hapticsEnabled })
  }
  
  private var activitySelector: some View {
    Button { viewModel.showActivityPicker = true } label: {
      HStack(spacing: 12) {
        Text(viewModel.selectedActivity?.emoji ?? "🎯").font(.title)
        Text(viewModel.selectedActivity?.name ?? "Select")
          .font(.system(size: 17, weight: .semibold, design: settings.appFont.design))
          .foregroundStyle(.primary)
        Image(systemName: "chevron.down").font(.caption).foregroundStyle(.secondary)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .background(FocusTheme.cardBackground)
      .clipShape(Capsule())
    }
    .buttonStyle(.plain)
    .padding(.top, 8)
    .sensoryFeedback(.impact(weight: .light), trigger: viewModel.showActivityPicker, condition: { _, _ in settings.hapticsEnabled })
  }
  
  private func timerSection(size: CGSize) -> some View {
    let baseThickness = settings.circleThickness
    let activeThickness = baseThickness + 2
    let timerSize: CGFloat = isLandscape ? min(size.height * 0.75, size.width * 0.5, 280) : min(size.width * 0.6, 240)
    
    return ZStack {
      CircularProgressView(
        progress: viewModel.progress,
        lineWidth: viewModel.isRunning ? activeThickness : baseThickness,
        isActive: viewModel.isRunning
      )
      .frame(width: timerSize, height: timerSize)
      
      VStack(spacing: 8) {
        Text(viewModel.selectedActivity?.emoji ?? "🎯")
          .font(.system(size: timerSize * 0.2))
          .opacity(viewModel.isRunning ? 1 : 0.6)
        
        Text("\(viewModel.remainingSeconds)")
          .font(.system(size: timerSize * 0.25, weight: .ultraLight, design: settings.appFont.design))
          .monospacedDigit()
          .foregroundStyle(.primary)
          .contentTransition(.numericText())
          .animation(.spring(response: 0.3), value: viewModel.remainingSeconds)
        
        Text("seconds")
          .font(.system(size: 10, design: settings.appFont.design))
          .textCase(.uppercase)
          .tracking(2)
          .foregroundStyle(.secondary)
          .opacity(viewModel.isRunning ? 0.6 : 1)
      }
    }
    .scaleEffect(viewModel.isRunning ? 1.05 : 1)
    .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
  }
  
  private var statsRow: some View {
    HStack(spacing: 12) {
      StatCard(value: viewModel.totalCollected, label: "Collected")
      StatCard(
        value: viewModel.pendingCount,
        label: "Pending",
        isClickable: true,
        action: {
          if viewModel.canCollect {
            viewModel.collect(modelContext: modelContext)
          }
        }
      )
    }
    .padding(.bottom, 24)
  }
  
  private var controlButtons: some View {
    HStack(spacing: 16) {
      Button { viewModel.showResetAlert = true } label: {
        Image(systemName: "arrow.counterclockwise")
          .font(.title3)
          .foregroundStyle(viewModel.isRunning ? .primary : .secondary)
          .frame(width: 50, height: 50)
          .background(viewModel.isRunning ? FocusTheme.cardBackground : FocusTheme.cardBackground.opacity(0.5))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.showResetAlert, condition: { _, _ in settings.hapticsEnabled })
      
      Button { viewModel.toggle() } label: {
        Text(viewModel.isRunning ? "Pause" : "Start")
          .font(.system(size: 17, weight: .semibold, design: settings.appFont.design))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 18)
          .background(settings.accent)
          .clipShape(Capsule())
          .shadow(color: viewModel.isRunning ? settings.accent.opacity(0.4) : .clear, radius: 12, y: 4)
      }
      .buttonStyle(.plain)
      .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isRunning, condition: { _, _ in settings.hapticsEnabled })
    }
    .padding(.bottom, 16)
  }
  
  private func physicsLayer(in geo: GeometryProxy) -> some View {
    Group {
      if settings.fallingAnimationEnabled {
        PhysicsEmojisView(emojis: viewModel.physics.emojis)
          .allowsHitTesting(false)
      }
    }
  }
  
  private var activityPickerSheet: some View {
    NavigationStack {
      Group {
        if viewModel.isCreatingActivity || viewModel.isEditingActivity {
          createOrEditActivityContent
        } else {
          activityListContent
        }
      }
      .background(FocusTheme.beige)
      .navigationTitle(viewModel.isEditingActivity ? "Edit Activity" : (viewModel.isCreatingActivity ? "New Activity" : "Activities"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { pickerToolbar }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }
  
  private var activityListContent: some View {
    ScrollView {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ForEach(activities) { activity in
          ActivityButton(
            emoji: activity.emoji,
            name: activity.name,
            isSelected: viewModel.selectedActivity?.id == activity.id,
            action: { viewModel.selectActivity(activity) }
          )
          .contextMenu {
            Button {
              viewModel.startEditingActivity(activity)
            } label: { Label("Edit", systemImage: "pencil") }
            
            if activity.isCustom {
              Button(role: .destructive) {
                viewModel.deleteActivity(activity, modelContext: modelContext)
              } label: { Label("Delete", systemImage: "trash") }
            }
          }
        }
      }
      .padding()
    }
  }
  
  private var createOrEditActivityContent: some View {
    let isEditing = viewModel.isEditingActivity
    
    return VStack(spacing: 24) {
      Text(viewModel.newActivityEmoji)
        .font(.system(size: 72))
        .padding(.top, 20)
      
      EmojiPickerView(selected: $viewModel.newActivityEmoji)
        .padding(.horizontal)
      
      UIKitTextField(
        text: $viewModel.newActivityName,
        placeholder: "Activity name",
        onSubmit: {
          if !viewModel.newActivityName.isEmpty {
            if isEditing {
              viewModel.saveEditedActivity()
            } else {
              viewModel.addActivity(modelContext: modelContext)
            }
          }
        }
      )
      .padding()
      .background(FocusTheme.cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .padding(.horizontal)
      
      Button {
        if isEditing {
          viewModel.saveEditedActivity()
        } else {
          viewModel.addActivity(modelContext: modelContext)
        }
      } label: {
        Text(isEditing ? "Save Changes" : "Create Activity")
          .font(.system(size: 17, weight: .semibold, design: settings.appFont.design))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(viewModel.newActivityName.isEmpty ? FocusTheme.subtle : settings.accent)
          .clipShape(Capsule())
      }
      .disabled(viewModel.newActivityName.isEmpty)
      .padding(.horizontal)
      .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.selectedActivity?.id, condition: { _, _ in settings.hapticsEnabled })
      
      Spacer()
    }
  }
  
  @ToolbarContentBuilder
  private var pickerToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button((viewModel.isCreatingActivity || viewModel.isEditingActivity) ? "Back" : "Close") {
        if viewModel.isCreatingActivity || viewModel.isEditingActivity {
          viewModel.cancelCreatingActivity()
        } else {
          viewModel.showActivityPicker = false
        }
      }
    }
    ToolbarItem(placement: .topBarTrailing) {
      if !viewModel.isCreatingActivity && !viewModel.isEditingActivity {
        Button { viewModel.startCreatingActivity() } label: {
          Image(systemName: "plus")
        }
      }
    }
  }
  
  @ViewBuilder
  private var resetAlertButtons: some View {
    Button("Cancel", role: .cancel) { }
    Button("Reset", role: .destructive) { viewModel.reset() }
  }
  
  private func onAppear(geo: GeometryProxy) {
    updatePhysicsBounds(geo: geo)
    viewModel.initializeDefaultActivities(existing: activities, modelContext: modelContext)
    viewModel.loadTotalCollected(sessions: sessions)
    if viewModel.selectedActivity == nil, let first = activities.first {
      viewModel.selectedActivity = first
    }
  }
  
  private func updatePhysicsBounds(geo: GeometryProxy) {
    let inset: CGFloat = 20
    let bounds = CGRect(
      x: inset,
      y: inset,
      width: geo.size.width - inset * 2,
      height: geo.size.height - inset * 2
    )
    viewModel.physics.configure(bounds: bounds)
  }
}

