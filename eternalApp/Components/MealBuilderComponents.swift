import SwiftUI

// MARK: - Typewriter Text

struct TypewriterText: View {
    let fullText: String
    let font: Font
    var delay: Double        = 0.0
    var charInterval: Double = 0.045   // time between each character typed
    var pauseAfterFinish: Double = 1.2 // hold at full string before erasing
    var eraseInterval: Double = 0.025  // time between each character erased

    @State private var displayed: String = ""

    var body: some View {
        Text(displayed)
            .font(font)
            .onAppear { scheduleNextCycle(initialDelay: delay) }
    }

    // MARK: - Cycle

    private func scheduleNextCycle(initialDelay: Double) {
        displayed = ""
        typeChar(index: 0, startDelay: initialDelay)
    }

    private func typeChar(index: Int, startDelay: Double) {
        let chars = Array(fullText)
        guard index < chars.count else {
            // Finished — pause then erase
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + pauseAfterFinish) {
                eraseChar(from: chars.count - 1)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + Double(index) * charInterval) {
            displayed.append(chars[index])
            typeChar(index: index + 1, startDelay: startDelay)
        }
    }

    private func eraseChar(from index: Int) {
        guard index >= 0 else {
            // Fully erased — brief gap then restart
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                scheduleNextCycle(initialDelay: 0)
            }
            return
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Double(Array(fullText).count - 1 - index) * eraseInterval
        ) {
            if !displayed.isEmpty { displayed.removeLast() }
            eraseChar(from: index - 1)
        }
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let level: CGFloat   // 0–1

    private let barCount = 12

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0 ..< barCount, id: \.self) { i in
                Capsule()
                    .fill(Color.zomatoAccent.opacity(0.90))
                    .frame(width: 6, height: barHeight(for: i))
                    .animation(
                        .spring(response: 0.18, dampingFraction: 0.45)
                            .delay(Double(i) * 0.025),
                        value: level
                    )
            }
        }
        .frame(height: 90)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let amplitude: CGFloat = 1.8
        let centre   = Double(barCount - 1) / 2.0
        let distance = abs(Double(index) - centre)
        // Bell-curve shape: centre bars peak higher
        let shape    = pow(1.0 - (distance / centre), 1.4)
        let base: CGFloat = 4
        let maxH: CGFloat = 140
        return base + (maxH - base) *
            min(max(level * amplitude, 0.08), 1.0) *
            CGFloat(shape)
    }
}
