//
//  GoalTimerView.swift
//  VIGIL
//

import SwiftData
import SwiftUI

struct GoalTimerView: View {
    let goal: Goal
    let loggedToday: Double

    @Bindable private var timer = GoalTimerManager.shared
    @Environment(\.modelContext) private var modelContext

    @State private var lastErrorLine: String?
    @State private var countScratch: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            if goal.goalType == GoalType.boolean {
                booleanBlock
            } else if goal.goalType == GoalType.count {
                countBlock
            } else if goal.goalType == GoalType.duration {
                durationBlock
                    .task(id: loggedTodayBin) {
                        syncCapHUDFromProgress()
                    }
                    .onChange(of: loggedToday) {
                        syncCapHUDFromProgress()
                    }
                    .onChange(of: timer.elapsedSeconds) {
                        syncCapHUDFromProgress()
                    }
            }

            if let lastErrorLine {
                Text(lastErrorLine.uppercased())
                    .font(Font.vigil.caption)
                    .foregroundStyle(Color.status.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, Spacing.xs.rawValue)
        .onAppear {
            syncCapHUDFromProgress()
            if countScratch <= 0 { countScratch = 1 }
        }
        .opacity(goal.isActive ? 1 : 0.42)
        .allowsHitTesting(goal.isActive)
    }

    private var loggedTodayBin: Double {
        (loggedToday * 120).rounded() / 120
    }

    private var capWarningLocal: Bool {
        guard goal.isCapGoal, goal.goalType == GoalType.duration, goal.targetValue > 0 else { return false }
        let elapsedMin = timer.activeGoalId == goal.id ? Double(timer.elapsedSeconds) / 60 : 0
        let projected = loggedToday + elapsedMin
        return projected >= goal.targetValue * 0.85
    }

    // MARK: — Duration session

    @ViewBuilder
    private var durationBlock: some View {
        if timer.hasForeignActiveTimer(comparedTo: goal.id) {
            Text("Another session is active.")
                .font(Font.vigil.body)
                .foregroundStyle(Color.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } else if timer.activeGoalId == goal.id {
            VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
                Text(formatElapsed(timer.elapsedSeconds))
                    .font(Font.vigil.timerDigits)
                    .foregroundStyle(Color.accent.primary)
                    .fixedSize()
                    .monospacedDigit()
                    .accessibilityLabel(accessibilityElapsedLabel(timer.elapsedSeconds))

                if timer.isPausedSession {
                    Text("PAUSED")
                        .font(Font.vigil.caption)
                        .foregroundStyle(Color.text.muted)
                }

                if capWarningLocal {
                    Text("APPROACHING CAP.")
                        .font(Font.vigil.caption)
                        .foregroundStyle(Color.status.warning)
                }

                HStack(spacing: Spacing.sm.rawValue) {
                    Button(action: togglePause) {
                        Text(timer.isRunning ? "PAUSE" : "RESUME")
                            .font(Font.vigil.headline)
                            .tracking(2)
                            .foregroundStyle(Color.text.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm.rawValue)
                            .background(Color.bg.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(timer.isRunning ? "Pause timer" : "Resume timer")

                    Button(action: completeDurationSession) {
                        Text("STOP")
                            .font(Font.vigil.headline)
                            .tracking(2.8)
                            .foregroundStyle(Color.bg.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm.rawValue)
                            .background(Color.accent.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Stop session and log time")
                }
            }
        } else {
            Button(action: startDuration) {
                Text("START SESSION")
                    .font(Font.vigil.headline)
                    .tracking(3)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm.rawValue)
                    .background(Color.accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start session for \(goal.name)")
            if goal.isCapGoal, capWarningNearStart {
                Text("NEAR TODAY'S CAP; OVERAGE COSTS XP.")
                    .font(Font.vigil.caption)
                    .foregroundStyle(Color.status.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var capWarningNearStart: Bool {
        guard goal.isCapGoal, goal.targetValue > 0 else { return false }
        return loggedToday >= goal.targetValue * 0.85
    }

    private func startDuration() {
        lastErrorLine = nil
        do {
            GoalTimerManager.shared.updateCapHUD(
                loggedToday: loggedToday,
                targetMinutes: goal.targetValue,
                isCapGoal: goal.isCapGoal
            )
            try GoalTimerManager.shared.startTimer(for: goal)
        } catch {
            lastErrorLine = error.localizedDescription
        }
    }

    private func togglePause() {
        lastErrorLine = nil
        if timer.isRunning {
            GoalTimerManager.shared.pauseTimer()
        } else {
            GoalTimerManager.shared.resumeAfterPause()
        }
    }

    private func completeDurationSession() {
        lastErrorLine = nil
        do {
            let result = try GoalTimerManager.shared.stopTimer(
                goal: goal,
                modelContext: modelContext,
                finalizeCredits: true
            )
            _ = result
            GoalTimerManager.shared.clearCapHUD()
        } catch {
            lastErrorLine = error.localizedDescription
        }
    }

    private func syncCapHUDFromProgress() {
        guard goal.goalType == GoalType.duration, timer.activeGoalId == goal.id else { return }
        GoalTimerManager.shared.updateCapHUD(
            loggedToday: loggedToday,
            targetMinutes: goal.targetValue,
            isCapGoal: goal.isCapGoal
        )
    }

    // MARK: — Boolean

    private var booleanBlock: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Button(action: { booleanComplete(cancel: true) }) {
                Text("CANCEL")
                    .font(Font.vigil.headline)
                    .tracking(2)
                    .foregroundStyle(Color.text.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm.rawValue)
                    .background(Color.bg.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: { booleanComplete(cancel: false) }) {
                Text("COMPLETE")
                    .font(Font.vigil.headline)
                    .tracking(2)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm.rawValue)
                    .background(Color.accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func booleanComplete(cancel: Bool) {
        lastErrorLine = nil
        do {
            _ = try GoalTimerManager.shared.markBoolean(
                goal: goal,
                modelContext: modelContext,
                complete: !cancel
            )
        } catch {
            lastErrorLine = error.localizedDescription
        }
    }

    // MARK: — Count

    private var countBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Stepper(value: $countScratch, in: 1 ... 999) {
                Text("LOG \(Int(countScratch)) \(goal.unit.uppercased())")
                    .font(Font.vigil.body)
                    .foregroundStyle(Color.text.primary)
            }
            .tint(Color.accent.primary)

            Button(action: submitCount) {
                Text("LOG PROGRESS")
                    .font(Font.vigil.headline)
                    .tracking(2.4)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm.rawValue)
                    .background(Color.accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func submitCount() {
        lastErrorLine = nil
        do {
            _ = try GoalTimerManager.shared.logCountSession(
                goal: goal,
                units: countScratch,
                modelContext: modelContext
            )
            countScratch = 1
        } catch {
            lastErrorLine = error.localizedDescription
        }
    }

    // MARK: — Formatting

    private func formatElapsed(_ total: Int) -> String {
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func accessibilityElapsedLabel(_ total: Int) -> String {
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return "\(h) hours \(m) minutes \(s) seconds elapsed"
        }
        return "\(m) minutes \(s) seconds elapsed"
    }
}

