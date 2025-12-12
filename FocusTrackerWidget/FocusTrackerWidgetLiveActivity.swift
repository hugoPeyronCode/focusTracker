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
    var cycleEndTime: Date
    var sessionStartTime: Date // When this focus session started
  }
  
  var startTime: Date
}

// MARK: - Live Activity Widget

struct FocusTrackerWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FocusActivityAttributes.self) { context in
      LockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 4) {
            // Activity
            HStack(spacing: 6) {
              Text(context.state.activityEmoji)
                .font(.title2)
              Text(context.state.activityName)
                .font(.headline)
            }
            
            // Time counting up
            if context.state.isRunning {
              Text(context.state.sessionStartTime, style: .timer)
                .font(.system(size: 32, weight: .light, design: .monospaced))
                .monospacedDigit()
            } else {
              Text(formatTime(context.state.todayFocusSeconds))
                .font(.system(size: 32, weight: .light, design: .monospaced))
                .foregroundStyle(.secondary)
            }
          }
        }
      } compactLeading: {
        Text(context.state.activityEmoji)
          .font(.body)
      } compactTrailing: {
        if context.state.isRunning {
          Text(context.state.sessionStartTime, style: .timer)
            .font(.system(.caption, design: .monospaced))
            .monospacedDigit()
            .frame(minWidth: 44)
        } else {
          Text(formatTime(context.state.todayFocusSeconds))
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
        }
      } minimal: {
        Text(context.state.activityEmoji)
          .font(.caption)
      }
    }
    .supplementalActivityFamilies([.small, .medium])
  }
  
  private func formatTime(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 {
      return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%d:%02d", m, s)
  }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
  let context: ActivityViewContext<FocusActivityAttributes>
  
  @Environment(\.isLuminanceReduced) var isLuminanceReduced
  @Environment(\.activityFamily) var activityFamily
  
  var body: some View {
    switch activityFamily {
    case .small:
      standBySmallView
    case .medium:
      standByMediumView
    @unknown default:
      lockScreenDefaultView
    }
  }
  
  // MARK: - Lock Screen Default (Minimal)
  
  private var lockScreenDefaultView: some View {
    HStack {
      // Left: Activity
      HStack(spacing: 8) {
        Text(context.state.activityEmoji)
          .font(.system(size: 28))
        Text(context.state.activityName)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      // Right: Time (counting up from session start)
      if context.state.isRunning {
        Text(context.state.sessionStartTime, style: .timer)
          .font(.system(size: 34, weight: .light, design: .monospaced))
          .monospacedDigit()
          .foregroundStyle(.primary)
      } else {
        Text(formatTime(context.state.todayFocusSeconds))
          .font(.system(size: 34, weight: .light, design: .monospaced))
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
  }
  
  // MARK: - StandBy Small
  
  private var standBySmallView: some View {
    VStack(spacing: 8) {
      Text(context.state.activityEmoji)
        .font(.system(size: 36))
      
      if context.state.isRunning {
        Text(context.state.sessionStartTime, style: .timer)
          .font(.system(size: 28, weight: .light, design: .monospaced))
          .monospacedDigit()
      } else {
        Text(formatTime(context.state.todayFocusSeconds))
          .font(.system(size: 28, weight: .light, design: .monospaced))
          .foregroundStyle(.secondary)
      }
      
      Text(context.state.activityName)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .padding(16)
  }
  
  // MARK: - StandBy Medium
  
  private var standByMediumView: some View {
    HStack(spacing: 24) {
      Text(context.state.activityEmoji)
        .font(.system(size: 64))
      
      VStack(alignment: .leading, spacing: 4) {
        if context.state.isRunning {
          Text(context.state.sessionStartTime, style: .timer)
            .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
            .monospacedDigit()
        } else {
          Text(formatTime(context.state.todayFocusSeconds))
            .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
            .foregroundStyle(.secondary)
        }
        
        Text(context.state.activityName)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.secondary)
      }
    }
    .padding(32)
  }
  
  private func formatTime(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 {
      return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%d:%02d", m, s)
  }
}
