import Foundation
import Speech
import AVFoundation
import SwiftUI
internal import Combine

// MARK: - Recording State

enum RecordingState {
    case idle
    case listening
    case done
    case denied
}

// MARK: - Recommendation State

enum RecommendationState: Equatable {
    case idle
    case loading
    case success(RecommendationResponse)
    case failure(String)

    static func == (lhs: RecommendationState, rhs: RecommendationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle,    .idle):    return true
        case (.loading, .loading): return true
        case (.success, .success): return true
        case (.failure(let a), .failure(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - MealBuilderViewModel

@MainActor
final class MealBuilderViewModel: ObservableObject {

    @Published private(set) var state: RecordingState                    = .idle
    @Published private(set) var transcript: String                       = ""
    @Published private(set) var audioLevel: CGFloat                      = 0
    @Published private(set) var recommendationState: RecommendationState = .idle

    // MARK: - Private audio

    private let recognizer  = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine = AVAudioEngine()
    private var request:      SFSpeechAudioBufferRecognitionRequest?
    private var task:         SFSpeechRecognitionTask?

    // MARK: - Public API

    func toggle() {
        switch state {
        case .idle, .done: requestPermissionsAndStart()
        case .listening:   confirm()
        case .denied:      break
        }
    }

    func confirm() {
        stopAudio()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
            state = transcript.isEmpty ? .idle : .done
        }
        if !transcript.isEmpty { print("🎙️ Voice input: \(transcript)") }
    }

    func cancel() {
        stopAudio()
        transcript = ""
        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) { state = .idle }
    }

    func reset() {
        transcript = ""
        recommendationState = .idle
        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) { state = .idle }
    }

    func stop() {
        stopAudio()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
            state = transcript.isEmpty ? .idle : .done
        }
    }

    // MARK: - Recommend

    func recommend(
        vegetarian: Bool,
        nonVegetarian: Bool,
        vegan: Bool,
        highProtein: Bool,
        diabeticFriendly: Bool,
        budgetFriendly: Bool,
        maxBudget: Int
    ) {
        guard recommendationState != .loading else { return }
        recommendationState = .loading

        let req = MealRecommendationRequest(
            user_response:            transcript,
            vegetarian:               vegetarian,
            non_vegetarian:           nonVegetarian,
            vegan:                    vegan,
            high_protein:             highProtein,
            diabetic_friendly:        diabeticFriendly,
            budget_friendly:          budgetFriendly,
            max_budget:               maxBudget,
            max_cooking_time_minutes: 25
        )

        Task {
            do {
                let response = try await MealRecommendationService.shared.recommend(req)
                print("✅ Got \(response.recommendations.count) recommendations")
                withAnimation(.spring(response: 0.40, dampingFraction: 0.75)) {
                    recommendationState = .success(response)
                }
            } catch {
                print("❌ Recommendation error: \(error.localizedDescription)")
                withAnimation(.spring(response: 0.40, dampingFraction: 0.75)) {
                    recommendationState = .failure(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Audio teardown

    private func stopAudio() {
        task?.cancel(); task = nil
        request?.endAudio(); request = nil
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        try? AVAudioSession.sharedInstance().setActive(false)
        audioLevel = 0
    }

    // MARK: - Permission flow

    private func requestPermissionsAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                guard status == .authorized else { self.state = .denied; return }
                self.requestMicrophonePermission()
            }
        }
    }

    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                guard granted else { self.state = .denied; return }
                self.beginAudioSession()
            }
        }
    }

    // MARK: - Audio session

    private func beginAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch { print("AVAudioSession error: \(error)"); return }

        audioEngine = AVAudioEngine()
        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        newRequest.shouldReportPartialResults = true
        request = newRequest

        let inputNode = audioEngine.inputNode
        let format    = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            newRequest.append(buffer)
            self?.updateAudioLevel(from: buffer)
        }

        do { try audioEngine.start() } catch { print("AVAudioEngine error: \(error)"); return }

        transcript = ""
        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) { state = .listening }

        task = recognizer?.recognitionTask(with: newRequest) { [weak self] result, error in
            guard let self else { return }
            if let result { self.transcript = result.bestTranscription.formattedString }
            if error != nil || result?.isFinal == true { self.stop() }
        }
    }

    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }
        let rms   = (0..<frameCount).reduce(0.0) { $0 + channelData[$1] * channelData[$1] }
        let level = CGFloat(sqrt(rms / Float(frameCount))) * 8
        DispatchQueue.main.async { self.audioLevel = min(level, 1.0) }
    }
}
