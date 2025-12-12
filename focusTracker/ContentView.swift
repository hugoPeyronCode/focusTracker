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

@Model
final class Activity {
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
  var date: Date
  
  init(activityName: String, activityEmoji: String, collectedCount: Int) {
    self.id = UUID()
    self.activityName = activityName
    self.activityEmoji = activityEmoji
    self.collectedCount = collectedCount
    self.date = Date()
  }
}

struct FocusTheme {
  static let beige = Color(light: Color(hex: "F5F0E8"), dark: Color(hex: "1C1917"))
  static let warmBrown = Color(light: Color(hex: "A18072"), dark: Color(hex: "D4A574"))
  static let accent = Color(light: Color(hex: "C4A484"), dark: Color(hex: "D4A574"))
  static let cardBackground = Color(light: Color(hex: "FFFFFF").opacity(0.7), dark: Color(hex: "292524").opacity(0.7))
  static let subtle = Color(light: Color(hex: "D4C4B5"), dark: Color(hex: "44403C"))
  static let coinFill = Color(light: Color(hex: "FAF7F2"), dark: Color(hex: "292524"))
  static let coinStroke = Color(light: Color(hex: "A18072"), dark: Color(hex: "D4A574"))
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
  private var groundY: CGFloat = 0
  private var screenWidth: CGFloat = 0
  private var screenHeight: CGFloat = 0
  
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
  
  func configure(screenWidth: CGFloat, groundY: CGFloat) {
    self.screenWidth = screenWidth
    self.screenHeight = groundY + 100
    self.groundY = groundY
  }
  
  func spawn(emoji: String) {
    let newEmoji = PhysicsEmoji(
      emoji: emoji,
      x: screenWidth / 2 + CGFloat.random(in: -30...30),
      y: -50,
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
    motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
      guard let motion = motion, let self = self else { return }
      self.gravityX = CGFloat(motion.gravity.x)
      self.gravityY = CGFloat(-motion.gravity.y)
    }
  }
  
  @objc private func update(link: CADisplayLink) {
    let dt = min(CGFloat(link.targetTimestamp - link.timestamp), 0.032)
    guard dt > 0 else { return }
    
    let gx = gravityX * baseGravity
    let gy = gravityY * baseGravity
    
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
      
      if emojis[i].x - emojiRadius < 0 {
        emojis[i].x = emojiRadius
        emojis[i].vx = abs(emojis[i].vx) * restitution
        emojis[i].rotationVelocity *= -0.5
      }
      if emojis[i].x + emojiRadius > screenWidth {
        emojis[i].x = screenWidth - emojiRadius
        emojis[i].vx = -abs(emojis[i].vx) * restitution
        emojis[i].rotationVelocity *= -0.5
      }
      if emojis[i].y - emojiRadius < 0 {
        emojis[i].y = emojiRadius
        emojis[i].vy = abs(emojis[i].vy) * restitution
      }
      if emojis[i].y + emojiRadius > groundY {
        emojis[i].y = groundY - emojiRadius
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
      let onGround = emojis[i].y + emojiRadius >= groundY - 1
      
      if speed < restVelocityThreshold && onGround && abs(gravityX) < 0.1 {
        emojis[i].restFrames += 1
        if emojis[i].restFrames >= restFramesRequired {
          emojis[i].isResting = true
          emojis[i].vx = 0
          emojis[i].vy = 0
          emojis[i].rotationVelocity = 0
          emojis[i].y = groundY - emojiRadius
        }
      } else {
        emojis[i].restFrames = max(0, emojis[i].restFrames - 2)
      }
    }
  }
}

@Observable
final class FocusViewModel {
  var selectedActivity: Activity?
  var isRunning = false
  var elapsed: Double = 0
  var totalCollected: Int = 0
  var todayFocusSeconds: Int = 0
  var showActivityPicker = false
  var showResetAlert = false
  var isCreatingActivity = false
  var newActivityName = ""
  var newActivityEmoji = "🎯"
  var isCollecting = false
  var lastRemainingSeconds: Int = 30
  var cycleCompleted = false
  
  let physics = PhysicsEngine()
  let cycleDuration: Double = 30
  private var timer: Timer?
  private var tickCounter: Int = 0
  
  var progress: Double { elapsed / cycleDuration }
  var remainingSeconds: Int { Int(ceil(cycleDuration - elapsed)) }
  var pendingCount: Int { physics.emojis.count }
  var canCollect: Bool { pendingCount > 0 }
  
  func toggle() {
    isRunning ? pause() : start()
  }
  
  func start() {
    isRunning = true
    physics.start()
    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.tick()
    }
  }
  
  func pause() {
    isRunning = false
    timer?.invalidate()
    timer = nil
  }
  
  func reset() {
    pause()
    elapsed = 0
    tickCounter = 0
    physics.stop()
  }
  
  func collect(modelContext: ModelContext) {
    guard canCollect, let activity = selectedActivity else { return }
    isCollecting = true
    let count = physics.clear()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
        self?.totalCollected += count
      }
      self?.isCollecting = false
    }
    
    let session = FocusSession(activityName: activity.name, activityEmoji: activity.emoji, collectedCount: count)
    modelContext.insert(session)
  }
  
  private func tick() {
    elapsed += 0.1
    tickCounter += 1
    
    if tickCounter >= 10 {
      tickCounter = 0
      todayFocusSeconds += 1
    }
    
    let newRemaining = remainingSeconds
    if newRemaining != lastRemainingSeconds {
      lastRemainingSeconds = newRemaining
    }
    
    if elapsed >= cycleDuration {
      elapsed = 0
      cycleCompleted = true
      if let emoji = selectedActivity?.emoji {
        physics.spawn(emoji: emoji)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.cycleCompleted = false
      }
    }
  }
  
  func selectActivity(_ activity: Activity) {
    selectedActivity = activity
    isCreatingActivity = false
    showActivityPicker = false
  }
  
  func startCreatingActivity() {
    isCreatingActivity = true
    newActivityName = ""
    newActivityEmoji = "🎯"
  }
  
  func cancelCreatingActivity() {
    isCreatingActivity = false
    newActivityName = ""
    newActivityEmoji = "🎯"
  }
  
  func addActivity(modelContext: ModelContext) {
    guard !newActivityName.isEmpty else { return }
    let activity = Activity(name: newActivityName, emoji: newActivityEmoji, isCustom: true)
    modelContext.insert(activity)
    selectedActivity = activity
    isCreatingActivity = false
    showActivityPicker = false
    newActivityName = ""
    newActivityEmoji = "🎯"
  }
  
  func deleteActivity(_ activity: Activity, modelContext: ModelContext) {
    if selectedActivity?.id == activity.id { selectedActivity = nil }
    modelContext.delete(activity)
  }
  
  func loadTotalCollected(sessions: [FocusSession]) {
    totalCollected = sessions.reduce(0) { $0 + $1.collectedCount }
  }
  
  func initializeDefaultActivities(existing: [Activity], modelContext: ModelContext) {
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
      modelContext.insert(Activity(name: name, emoji: emoji, isCustom: false))
    }
    try? modelContext.save()
  }
}

struct UIKitTextField: UIViewRepresentable {
  @Binding var text: String
  var placeholder: String
  
  func makeUIView(context: Context) -> UITextField {
    let textField = UITextField()
    textField.placeholder = placeholder
    textField.font = .systemFont(ofSize: 17)
    textField.borderStyle = .none
    textField.autocorrectionType = .no
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
  }
}

struct CircularProgressView: View {
  let progress: Double
  let lineWidth: CGFloat
  
  var body: some View {
    ZStack {
      Circle().stroke(FocusTheme.subtle, lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(FocusTheme.warmBrown, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(.linear(duration: 0.1), value: progress)
    }
  }
}

struct StatCard: View {
  let value: Int
  let label: String
  var isClickable: Bool = false
  var action: (() -> Void)? = nil
  
  var body: some View {
    Group {
      if isClickable, let action = action {
        Button(action: action) { cardContent }
          .buttonStyle(.plain)
      } else {
        cardContent
      }
    }
  }
  
  private var cardContent: some View {
    VStack(spacing: 4) {
      Text("\(value)")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
        .contentTransition(.numericText())
        .animation(.spring(response: 0.3), value: value)
      Text(label)
        .font(.caption)
        .textCase(.uppercase)
        .tracking(1)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(isClickable && value > 0 ? FocusTheme.accent.opacity(0.2) : FocusTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(isClickable && value > 0 ? FocusTheme.warmBrown : Color.clear, lineWidth: 1.5)
    )
  }
}

struct ActivityButton: View {
  let emoji: String
  let name: String
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Text(emoji).font(.largeTitle)
        Text(name).font(.caption).foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(isSelected ? FocusTheme.accent.opacity(0.3) : FocusTheme.cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? FocusTheme.warmBrown : Color.clear, lineWidth: 2))
    }
    .buttonStyle(.plain)
  }
}

struct EmojiPickerView: View {
  @Binding var selected: String
  let emojis = ["🎯", "🧘", "💼", "💻", "💪", "⚽", "📚", "✍️", "🎵", "🎨",
                "🏃", "🚴", "🏊", "🧗", "🎮", "🎬", "📷", "🔬", "🧪", "🌱",
                "☕", "🍳", "🧹", "💤", "🙏", "💡", "🎓", "📝", "🗣️", "🤝",
                "🧠", "❤️", "⭐", "🔥", "💎", "🏆"]
  let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
  
  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(emojis, id: \.self) { emoji in
        Button { selected = emoji } label: {
          Text(emoji)
            .font(.title2)
            .frame(width: 44, height: 44)
            .background(selected == emoji ? FocusTheme.accent.opacity(0.3) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
      }
    }
  }
}

struct PhysicsEmojisView: View {
  let emojis: [PhysicsEmoji]
  let coinSize: CGFloat = 48
  
  @Environment(\.colorScheme) var colorScheme
  
  var coinFill: Color {
    colorScheme == .dark ? Color(hex: "292524") : Color(hex: "FAF7F2")
  }
  
  var coinStroke: Color {
    colorScheme == .dark ? Color(hex: "D4A574") : Color(hex: "A18072")
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

struct FocusTrackerView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var activities: [Activity]
  @Query private var sessions: [FocusSession]
  @State private var viewModel = FocusViewModel()
  
  var body: some View {
    GeometryReader { geo in
      ZStack {
        background
        physicsLayer(in: geo)
        mainContent
      }
      .onAppear { onAppear(screenSize: geo.size) }
    }
    .sheet(isPresented: $viewModel.showActivityPicker) { activityPickerSheet }
    .alert("Reset Session?", isPresented: $viewModel.showResetAlert) { resetAlertButtons }
    .sensoryFeedback(.selection, trigger: viewModel.remainingSeconds)
    .sensoryFeedback(.success, trigger: viewModel.cycleCompleted)
    .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.totalCollected)
  }
  
  private var background: some View {
    FocusTheme.beige.ignoresSafeArea()
  }
  
  private var mainContent: some View {
    VStack(spacing: 0) {
      topBar
      activitySelector
      Spacer()
      timerSection
      Spacer()
      statsRow
      controlButtons
    }
    .padding()
  }
  
  private var topBar: some View {
    HStack {
      HStack(spacing: 4) {
        Image(systemName: "clock")
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(formattedTodayTime)
          .font(.subheadline)
          .fontWeight(.medium)
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .contentTransition(.numericText())
          .animation(.spring(response: 0.3), value: viewModel.todayFocusSeconds)
      }
      
      Spacer()
      
      collectButton
    }
    .padding(.bottom, 8)
  }
  
  private var collectButton: some View {
    Button {
      if viewModel.canCollect {
        viewModel.collect(modelContext: modelContext)
      }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: "sparkles")
          .foregroundStyle(FocusTheme.warmBrown)
        Text("\(viewModel.totalCollected)")
          .fontWeight(.semibold)
          .contentTransition(.numericText())
          .animation(.spring(response: 0.3), value: viewModel.totalCollected)
        if viewModel.pendingCount > 0 {
          Text("+\(viewModel.pendingCount)")
            .font(.caption)
            .foregroundStyle(FocusTheme.warmBrown)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3), value: viewModel.pendingCount)
        }
      }
      .font(.subheadline)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(viewModel.canCollect ? FocusTheme.accent.opacity(0.3) : FocusTheme.cardBackground)
      .clipShape(Capsule())
      .overlay(Capsule().stroke(viewModel.canCollect ? FocusTheme.warmBrown : Color.clear, lineWidth: 1.5))
    }
    .buttonStyle(.plain)
    .animation(.spring(response: 0.3), value: viewModel.canCollect)
  }
  
  private var activitySelector: some View {
    Button { viewModel.showActivityPicker = true } label: {
      HStack(spacing: 12) {
        Text(viewModel.selectedActivity?.emoji ?? "🎯").font(.title)
        Text(viewModel.selectedActivity?.name ?? "Select").font(.headline).foregroundStyle(.primary)
        Image(systemName: "chevron.down").font(.caption).foregroundStyle(.secondary)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .background(FocusTheme.cardBackground)
      .clipShape(Capsule())
    }
    .buttonStyle(.plain)
    .padding(.top, 8)
  }
  
  private var timerSection: some View {
    ZStack {
      CircularProgressView(progress: viewModel.progress, lineWidth: 6)
        .frame(width: 240, height: 240)
      VStack(spacing: 8) {
        Text(viewModel.selectedActivity?.emoji ?? "🎯")
          .font(.system(size: 52))
          .opacity(viewModel.isRunning ? 1 : 0.6)
        Text("\(viewModel.remainingSeconds)")
          .font(.system(size: 64, weight: .ultraLight, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(.primary)
          .contentTransition(.numericText())
          .animation(.spring(response: 0.3), value: viewModel.remainingSeconds)
        Text("seconds")
          .font(.caption)
          .textCase(.uppercase)
          .tracking(2)
          .foregroundStyle(.secondary)
      }
    }
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
          .foregroundStyle(.primary)
          .frame(width: 50, height: 50)
          .background(FocusTheme.cardBackground)
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      
      Button { viewModel.toggle() } label: {
        Text(viewModel.isRunning ? "Pause" : "Start")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 18)
          .background(FocusTheme.warmBrown)
          .clipShape(Capsule())
      }
      .buttonStyle(.plain)
      .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isRunning)
    }
    .padding(.bottom, 16)
  }
  
  private func physicsLayer(in geo: GeometryProxy) -> some View {
    PhysicsEmojisView(emojis: viewModel.physics.emojis)
      .allowsHitTesting(false)
      .onChange(of: geo.size) { _, newSize in
        viewModel.physics.configure(screenWidth: newSize.width, groundY: newSize.height - 20)
      }
  }
  
  private var activityPickerSheet: some View {
    NavigationStack {
      Group {
        if viewModel.isCreatingActivity {
          createActivityContent
        } else {
          activityListContent
        }
      }
      .background(FocusTheme.beige)
      .navigationTitle(viewModel.isCreatingActivity ? "New Activity" : "Activities")
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
  
  private var createActivityContent: some View {
    VStack(spacing: 24) {
      Text(viewModel.newActivityEmoji)
        .font(.system(size: 72))
        .padding(.top, 20)
      
      EmojiPickerView(selected: $viewModel.newActivityEmoji)
        .padding(.horizontal)
      
      UIKitTextField(text: $viewModel.newActivityName, placeholder: "Activity name")
        .padding()
        .background(FocusTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
      
      Button {
        viewModel.addActivity(modelContext: modelContext)
      } label: {
        Text("Create Activity")
          .font(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(viewModel.newActivityName.isEmpty ? FocusTheme.subtle : FocusTheme.warmBrown)
          .clipShape(Capsule())
      }
      .disabled(viewModel.newActivityName.isEmpty)
      .padding(.horizontal)
      
      Spacer()
    }
  }
  
  @ToolbarContentBuilder
  private var pickerToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button(viewModel.isCreatingActivity ? "Back" : "Close") {
        if viewModel.isCreatingActivity {
          viewModel.cancelCreatingActivity()
        } else {
          viewModel.showActivityPicker = false
        }
      }
    }
    ToolbarItem(placement: .topBarTrailing) {
      if !viewModel.isCreatingActivity {
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
  
  private var formattedTodayTime: String {
    let h = viewModel.todayFocusSeconds / 3600
    let m = (viewModel.todayFocusSeconds % 3600) / 60
    let s = viewModel.todayFocusSeconds % 60
    if h > 0 {
      return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
  }
  
  private func onAppear(screenSize: CGSize) {
    viewModel.physics.configure(screenWidth: screenSize.width, groundY: screenSize.height - 20)
    viewModel.initializeDefaultActivities(existing: activities, modelContext: modelContext)
    viewModel.loadTotalCollected(sessions: sessions)
    if viewModel.selectedActivity == nil, let first = activities.first {
      viewModel.selectedActivity = first
    }
  }
}
