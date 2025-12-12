//
//  FocusTrackerWidgetLiveActivity.swift
//  FocusTrackerWidget
//
//  Created by Hugo Peyron on 12/12/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Attributes (must match main app)

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

// MARK: - Live Activity Widget

struct FocusTrackerWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FocusActivityAttributes.self) { context in
      // Lock Screen / Banner UI
      LockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded UI
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 4) {
            Text(context.state.activityEmoji)
              .font(.title2)
            Text(context.state.activityName)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        
        DynamicIslandExpandedRegion(.trailing) {
          HStack(spacing: 4) {
            Image(systemName: "flame.fill")
              .foregroundStyle(.orange)
              .font(.caption)
            Text("\(context.state.currentStreakLevel)")
              .font(.caption.bold())
          }
        }
        
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 4) {
            Text("\(context.state.remainingSeconds)")
              .font(.system(size: 36, weight: .ultraLight, design: .rounded))
              .monospacedDigit()
            
            ProgressView(value: context.state.elapsed / context.state.cycleDuration)
              .tint(.orange)
          }
        }
        
        DynamicIslandExpandedRegion(.bottom) {
          HStack {
            Label(formatTime(context.state.todayFocusSeconds), systemImage: "clock")
              .font(.caption2)
              .foregroundStyle(.secondary)
            Spacer()
            Text(context.state.isRunning ? "Focusing..." : "Paused")
              .font(.caption2)
              .foregroundStyle(context.state.isRunning ? .green : .orange)
          }
        }
      } compactLeading: {
        HStack(spacing: 2) {
          Text(context.state.activityEmoji)
            .font(.caption)
        }
      } compactTrailing: {
        Text("\(context.state.remainingSeconds)s")
          .font(.caption.monospacedDigit())
          .foregroundStyle(context.state.isRunning ? .primary : .secondary)
      } minimal: {
        Text(context.state.activityEmoji)
          .font(.caption)
      }
    }
  }
  
  private func formatTime(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 {
      return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
  }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
  let context: ActivityViewContext<FocusActivityAttributes>
  
  var body: some View {
    HStack(spacing: 16) {
      // Left: Emoji and Activity
      VStack(alignment: .leading, spacing: 4) {
        Text(context.state.activityEmoji)
          .font(.largeTitle)
        Text(context.state.activityName)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      // Center: Timer
      VStack(spacing: 4) {
        Text("\(context.state.remainingSeconds)")
          .font(.system(size: 44, weight: .ultraLight, design: .rounded))
          .monospacedDigit()
        
        Text("seconds")
          .font(.caption2)
          .textCase(.uppercase)
          .foregroundStyle(.secondary)
        
        // Progress bar
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            Capsule()
              .fill(Color.gray.opacity(0.3))
              .frame(height: 4)
            
            Capsule()
              .fill(Color.orange)
              .frame(width: geo.size.width * (context.state.elapsed / context.state.cycleDuration), height: 4)
          }
        }
        .frame(width: 80, height: 4)
      }
      
      Spacer()
      
      // Right: Stats
      VStack(alignment: .trailing, spacing: 4) {
        HStack(spacing: 4) {
          Image(systemName: "flame.fill")
            .foregroundStyle(.orange)
            .font(.caption)
          Text("\(context.state.currentStreakLevel)")
            .font(.caption.bold())
        }
        
        Text(formatTime(context.state.todayFocusSeconds))
          .font(.caption2)
          .foregroundStyle(.secondary)
        
        Circle()
          .fill(context.state.isRunning ? Color.green : Color.orange)
          .frame(width: 8, height: 8)
      }
    }
    .padding()
  }
  
  private func formatTime(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 {
      return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
  }
}
