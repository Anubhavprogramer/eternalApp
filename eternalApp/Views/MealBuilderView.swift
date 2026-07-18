import SwiftUI
import Speech
import AVFoundation
internal import Combine
// MARK: - Speech Manager

@MainActor
final class SpeechManager: ObservableObject {

    enum RecordingState {
        case idle          // mic icon, tap to start
        case listening     // recording, waveform animating
        case done          // checkmark, transcript ready
        case denied        // permission denied
    }

    @Published var state: RecordingState  = .idle
    @Published var transcript: String    = ""
    @Published var audioLevel: CGFloat   = 0   // 0–1, drives waveform

    private let recognizer   = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine  = AVAudioEngine()
    private var request:       SFSpeechAudioBufferRecognitionRequest?
    private var task:          SFSpeechRecognitionTask?
    private var levelTimer:    Timer?

    // MARK: Toggle

    func toggle() {
        switch state {
        case .idle, .done:   requestAndStart()
        case .listening:     stop()
        case .denied:        break
        }
    }

    // MARK: Start

    private func requestAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                guard let self else { return }
                switch authStatus {
                case .authorized: self.startRecording()
                default:
                    self.state = .denied
                }
            }
        }
    }

    private func startRecording() {
        // Mic permission
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self, granted else {
                    self?.state = .denied
                    return
                }
                self.beginAudioSession()
            }
        }
    }

    private func beginAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }

        audioEngine  = AVAudioEngine()
        request      = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let fmt       = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buffer, _ in
            self?.request?.append(buffer)

            // Compute RMS for waveform
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            let rms = (0 ..< frameCount).reduce(0.0) { $0 + channelData[$1] * channelData[$1] }
            let level = CGFloat(sqrt(rms / Float(frameCount))) * 8
            DispatchQueue.main.async { self?.audioLevel = min(level, 1.0) }
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
            return
        }

        state = .listening
        transcript = ""

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.transcript = result.bestTranscription.formattedString
            }
            if error != nil || (result?.isFinal == true) {
                self.stop()
            }
        }
    }

    // MARK: Stop

    func stop() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        levelTimer?.invalidate()
        audioLevel = 0

        try? AVAudioSession.sharedInstance().setActive(false)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
            state = transcript.isEmpty ? .idle : .done
        }

        if !transcript.isEmpty {
            print("🎙️ Voice input: \(transcript)")
        }
    }

    func reset() {
        transcript = ""
        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
            state = .idle
        }
    }
}

// MARK: - Typewriter Text

private struct TypewriterText: View {
    let fullText: String
    let font: Font
    let delay: Double
    var charInterval: Double    = 0.045
    var pauseAfterFinish: Double = 1.2
    var eraseInterval: Double   = 0.025

    @State private var displayed: String = ""

    var body: some View {
        Text(displayed)
            .font(font)
            .onAppear { scheduleNextCycle(initialDelay: delay) }
    }

    private func scheduleNextCycle(initialDelay: Double) {
        displayed = ""
        typeChar(index: 0, startDelay: initialDelay)
    }

    private func typeChar(index: Int, startDelay: Double) {
        let chars = Array(fullText)
        guard index < chars.count else {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                scheduleNextCycle(initialDelay: 0)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(Array(fullText).count - 1 - index) * eraseInterval) {
            if !displayed.isEmpty { displayed.removeLast() }
            eraseChar(from: index - 1)
        }
    }
}

// MARK: - Animated Gradient Background

private struct AnimatedGradientBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Color(red: 0.08, green: 0.07, blue: 0.10)))

                let b1x = size.width  * (0.20 + 0.30 * sin(t * 0.18))
                let b1y = size.height * (0.20 + 0.25 * cos(t * 0.14))
                ctx.fill(Path(ellipseIn: CGRect(x: b1x-160, y: b1y-160, width: 320, height: 320)),
                         with: .color(Color(red: 0.90, green: 0.22, blue: 0.28).opacity(0.28)))

                let b2x = size.width  * (0.75 + 0.22 * cos(t * 0.13))
                let b2y = size.height * (0.65 + 0.20 * sin(t * 0.17))
                ctx.fill(Path(ellipseIn: CGRect(x: b2x-180, y: b2y-180, width: 360, height: 360)),
                         with: .color(Color(red: 0.80, green: 0.30, blue: 0.10).opacity(0.20)))

                let b3x = size.width  * (0.80 + 0.12 * sin(t * 0.09))
                let b3y = size.height * (0.12 + 0.14 * cos(t * 0.11))
                ctx.fill(Path(ellipseIn: CGRect(x: b3x-120, y: b3y-120, width: 240, height: 240)),
                         with: .color(Color(red: 0.40, green: 0.15, blue: 0.55).opacity(0.18)))
            }
            .blur(radius: 60)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Waveform View

private struct WaveformView: View {
    let level: CGFloat   // 0–1

    private let barCount = 7

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< barCount, id: \.self) { i in
                Capsule()
                    .fill(Color.zomatoAccent.opacity(0.85))
                    .frame(width: 4, height: barHeight(for: i))
                    .animation(
                        .spring(response: 0.22, dampingFraction: 0.55)
                            .delay(Double(i) * 0.03),
                        value: level
                    )
            }
        }
        .frame(height: 40)
    }

    private func barHeight(for index: Int) -> CGFloat {
        // Centre bar is tallest, scales with level
        let centre   = Double(barCount - 1) / 2.0
        let distance = abs(Double(index) - centre)
        let shape    = 1.0 - (distance / centre) * 0.5   // 1.0 at centre, 0.5 at edges
        let base: CGFloat = 6
        let max:  CGFloat = 38
        return base + (max - base) * level * CGFloat(shape)
    }
}

// MARK: - Main View

struct MealBuilderView: View {
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var envDismiss

    @StateObject private var speech = SpeechManager()

    // Banner animations
    @State private var shimmerOffset: CGFloat = -280
    @State private var bannerOpacity: Double  = 0
    @State private var bannerScale: CGFloat   = 0.94
    @State private var glowPulse: Bool        = false

    // Entrance
    @State private var contentOpacity: Double = 0
    @State private var contentOffset:  CGFloat = 28

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {

                // ── Top bar ──────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.10))
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 18)

                // ── Banner ───────────────────────────────────────────
                animatedBanner
                    .padding(.horizontal, 20)

                Spacer()

                // ── Centre: headline or live transcript ───────────────
                centreSection

                Spacer()

                // ── Mic control ──────────────────────────────────────
                micControl
                    .padding(.bottom, 40)
            }
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear { runAnimations() }
    }

    // MARK: - Dismiss

    private func dismiss() {
        speech.stop()
        if let onDismiss { onDismiss() } else { envDismiss() }
    }

    // MARK: - Banner

    private var animatedBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.55, green: 0.10, blue: 0.16),
                        Color.zomatoAccent,
                        Color(red: 0.95, green: 0.48, blue: 0.18)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(height: 88)

            Circle().fill(.white.opacity(0.08))
                .frame(width: 110, height: 110).offset(x: -110, y: -20).blur(radius: 1)
            Circle().fill(.white.opacity(0.06))
                .frame(width: 80,  height: 80 ).offset(x:  120, y:  30).blur(radius: 1)

            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, .white.opacity(0.22), .clear],
                    startPoint: .leading, endPoint: .trailing))
                .frame(width: 100)
                .offset(x: shimmerOffset)
                .mask(RoundedRectangle(cornerRadius: 22, style: .continuous).frame(height: 88))
                .clipped()

            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(.white.opacity(0.14)).frame(width: 46, height: 46)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("LET US HELP YOU")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2.5).foregroundStyle(.white.opacity(0.75))
                    Text("Build a Meal")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.20), radius: 4, x: 0, y: 2)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 88)
        .scaleEffect(bannerScale)
        .opacity(bannerOpacity)
        .clipped()
    }

    // MARK: - Centre Section

    @ViewBuilder
    private var centreSection: some View {
        switch speech.state {

        case .idle:
            // Typewriter prompt
            VStack(spacing: 14) {
                Text("Speak or type what you have —\nwe'll suggest the perfect dish.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.42))
                    .multilineTextAlignment(.center)

                TypewriterText(
                    fullText: "LIST YOUR\nITEMS HERE..",
                    font: .system(size: 40, weight: .black, design: .rounded),
                    delay: 0.05
                )
                .multilineTextAlignment(.center)
                .foregroundStyle(LinearGradient(
                    colors: [Color.zomatoAccent, Color(red: 0.95, green: 0.52, blue: 0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(
                    color: Color.zomatoAccent.opacity(glowPulse ? 0.60 : 0.15),
                    radius: glowPulse ? 18 : 5, x: 0, y: 0)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowPulse)
            }
            .padding(.horizontal, 28)
            .transition(.opacity)

        case .listening:
            // Live waveform + partial transcript
            VStack(spacing: 20) {
                WaveformView(level: speech.audioLevel)

                Text(speech.transcript.isEmpty ? "Listening…" : speech.transcript)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .animation(.easeInOut(duration: 0.15), value: speech.transcript)
            }
            .transition(.scale(scale: 0.92).combined(with: .opacity))

        case .done:
            // Final transcript with copy hint
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: speech.state)

                Text(speech.transcript)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    speech.reset()
                } label: {
                    Text("Tap to speak again")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
            .transition(.scale(scale: 0.92).combined(with: .opacity))

        case .denied:
            VStack(spacing: 10) {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.zomatoAccent)
                Text("Microphone access denied.\nPlease enable it in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .transition(.opacity)
        }
    }

    // MARK: - Mic Control

    private var micControl: some View {
        VStack(spacing: 10) {
            ZStack {

                // Ripple rings — only while listening
                if speech.state == .listening {
                    Circle()
                        .stroke(Color.zomatoAccent.opacity(0.22), lineWidth: 10)
                        .frame(width: 100, height: 100)
                        .scaleEffect(speech.state == .listening ? 1.30 : 1.0)
                        .opacity(speech.state == .listening ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.4).repeatForever(autoreverses: false),
                            value: speech.state == .listening)

                    Circle()
                        .stroke(Color.zomatoAccent.opacity(0.12), lineWidth: 6)
                        .frame(width: 80, height: 80)
                        .scaleEffect(speech.state == .listening ? 1.20 : 1.0)
                        .opacity(speech.state == .listening ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(0.22),
                            value: speech.state == .listening)
                }

                // Core button
                Button { speech.toggle() } label: {
                    ZStack {
                        Circle()
                            .fill(buttonGradient)
                            .frame(width: 66, height: 66)
                            .shadow(color: buttonShadowColor, radius: 20, x: 0, y: 8)

                        Image(systemName: buttonIcon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .buttonStyle(.plain)
            }

            Text(buttonLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.38))
                .animation(.easeInOut(duration: 0.2), value: speech.state)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: speech.state)
    }

    // MARK: - Button appearance helpers

    private var buttonIcon: String {
        switch speech.state {
        case .idle:      return "mic.fill"
        case .listening: return "stop.fill"
        case .done:      return "arrow.counterclockwise"
        case .denied:    return "mic.slash.fill"
        }
    }

    private var buttonLabel: String {
        switch speech.state {
        case .idle:      return "Tap to speak"
        case .listening: return "Tap to stop"
        case .done:      return "Tap to redo"
        case .denied:    return "Permission denied"
        }
    }

    private var buttonGradient: LinearGradient {
        switch speech.state {
        case .done:
            return LinearGradient(
                colors: [Color.green.opacity(0.85), Color.green],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .denied:
            return LinearGradient(
                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(
                colors: [Color.zomatoAccent, Color(red: 0.85, green: 0.20, blue: 0.28)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var buttonShadowColor: Color {
        switch speech.state {
        case .done:   return .green.opacity(0.50)
        case .denied: return .clear
        default:      return Color.zomatoAccent.opacity(0.55)
        }
    }

    // MARK: - Animations

    private func runAnimations() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.80).delay(0.05)) {
            contentOpacity = 1
            contentOffset  = 0
        }
        withAnimation(.spring(response: 0.50, dampingFraction: 0.75).delay(0.12)) {
            bannerOpacity = 1
            bannerScale   = 1.0
        }
        shimmerOffset = -280
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false).delay(0.3)) {
            shimmerOffset = 380
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(1.8)) {
            glowPulse = true
        }
    }
}
