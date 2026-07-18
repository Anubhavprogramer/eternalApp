import Foundation
import Speech
import AVFoundation
import SwiftUI
internal import Combine

// MARK: - Recording State

enum RecordingState {
    case idle       // waiting for user to tap
    case listening  // recording + streaming transcript
    case done       // transcript ready
    case denied     // permission denied
}

// MARK: - MealBuilderViewModel

@MainActor
final class MealBuilderViewModel: ObservableObject {

    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var transcript: String    = ""
    @Published private(set) var audioLevel: CGFloat   = 0   // 0–1, drives waveform bars

    // MARK: - Private

    private let recognizer  = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine = AVAudioEngine()
    private var request:      SFSpeechAudioBufferRecognitionRequest?
    private var task:         SFSpeechRecognitionTask?

    // MARK: - Public API

    /// Toggle between idle/done → listening, or listening → stopped.
    func toggle() {
        switch state {
        case .idle, .done: requestPermissionsAndStart()
        case .listening:   stop()
        case .denied:      break
        }
    }

    /// Reset transcript and return to idle.
    func reset() {
        transcript = ""
        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
            state = .idle
        }
    }

    /// Stop recording cleanly (called by the view on dismiss too).
    func stop() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil

        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }

        try? AVAudioSession.sharedInstance().setActive(false)

        audioLevel = 0

        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
            state = transcript.isEmpty ? .idle : .done
        }

        if !transcript.isEmpty {
            print("🎙️ Voice input: \(transcript)")
        }
    }

    // MARK: - Permission flow

    private func requestPermissionsAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                guard status == .authorized else {
                    self.state = .denied
                    return
                }
                self.requestMicrophonePermission()
            }
        }
    }

    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                guard granted else {
                    self.state = .denied
                    return
                }
                self.beginAudioSession()
            }
        }
    }

    // MARK: - Audio session + recognition

    private func beginAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("AVAudioSession error: \(error)")
            return
        }

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

        do {
            try audioEngine.start()
        } catch {
            print("AVAudioEngine start error: \(error)")
            return
        }

        transcript = ""
        withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
            state = .listening
        }

        task = recognizer?.recognitionTask(with: newRequest) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.transcript = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self.stop()
            }
        }
    }

    // MARK: - RMS level calculation

    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }
        let rms   = (0 ..< frameCount).reduce(0.0) { $0 + channelData[$1] * channelData[$1] }
        let level = CGFloat(sqrt(rms / Float(frameCount))) * 8
        DispatchQueue.main.async { self.audioLevel = min(level, 1.0) }
    }
}
