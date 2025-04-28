//
//  DownloadButton.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import SwiftUI
import Combine

struct DownloadButton: View {
    @ObservedObject var state: DownloadButtonState
    let title: String
    let downloadDuration: Double
    let onDownloadStart: () -> Void
    let onDownloadPause: () -> Void
    let onDownloadComplete: () -> Void
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var downloadProgress: Double = 0.0
    @State private var startTime: Date?
    @State private var pauseTime: Date?
    
    private let userDefaults = UserDefaults.standard
    
    enum DownloadState: String {
        case idle
        case downloading
        case paused
        case completed
    }
    
    var body: some View {
        Group {
            switch state.downloadState {
            case .idle:
                Text(title)
                    .wrapToButton {
                        startDownload()
                        onDownloadStart()
                    }
                    .asPointBorderText()
                
            case .downloading:
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .trim(from: 0, to: downloadProgress)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: downloadProgress)
                    
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
                .frame(width: 30, height: 30)
                .wrapToButton {
                    pauseDownload()
                    onDownloadPause()
                }
                
            case .paused:
                Text("재개")
                    .wrapToButton {
                        resumeDownload()
                        onDownloadStart()
                    }
                    .asPointBorderText()
                
            case .completed:
                Text("열기")
                    .wrapToButton {
                        onDownloadComplete()
                    }
                    .asPointBorderText()
            }
        }
        .onAppear {
            restoreDownloadState()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                updateProgressOnForeground()
            case .background:
                saveDownloadState()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func startDownload() {
        state.downloadState = .downloading
        startTime = Date()
        downloadProgress = 0.0
        updateProgress()
        saveDownloadState()
    }
    
    private func pauseDownload() {
        state.downloadState = .paused
        pauseTime = Date()
        saveDownloadState()
    }
    
    private func resumeDownload() {
        guard let pause = pauseTime, let start = startTime else { return }
        let pausedDuration = pause.timeIntervalSince(start)
        startTime = Date().addingTimeInterval(-pausedDuration)
        state.downloadState = .downloading
        updateProgress()
        saveDownloadState()
    }
    
    private func updateProgress() {
        guard state.downloadState == .downloading, let start = startTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(start)
        downloadProgress = min(elapsedTime / downloadDuration, 1.0)
        
        if downloadProgress < 1.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                updateProgress()
            }
        } else {
            state.downloadState = .completed
            startTime = nil
            pauseTime = nil
            onDownloadComplete()
            saveDownloadState()
        }
    }
    
    private func updateProgressOnForeground() {
        guard state.downloadState == .downloading || state.downloadState == .paused, let start = startTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(start)
        downloadProgress = min(elapsedTime / downloadDuration, 1.0)
        
        if downloadProgress >= 1.0 {
            state.downloadState = .completed
            startTime = nil
            pauseTime = nil
            onDownloadComplete()
            saveDownloadState()
        } else if state.downloadState == .downloading {
            updateProgress()
        }
    }
    
    private func saveDownloadState() {
        userDefaults.set(state.downloadState.rawValue, forKey: "downloadState_\(state.identifier)")
        if let start = startTime {
            userDefaults.set(start.timeIntervalSince1970, forKey: "startTime_\(state.identifier)")
        }
        if let pause = pauseTime {
            userDefaults.set(pause.timeIntervalSince1970, forKey: "pauseTime_\(state.identifier)")
        }
        userDefaults.set(downloadProgress, forKey: "downloadProgress_\(state.identifier)")
    }
    
    private func restoreDownloadState() {
        if let savedState = userDefaults.string(forKey: "downloadState_\(state.identifier)"),
           let restoredState = DownloadState(rawValue: savedState) {
            state.downloadState = restoredState
        } else {
            state.downloadState = .idle // 상태가 없으면 초기화
        }
        
        if let startTimestamp = userDefaults.object(forKey: "startTime_\(state.identifier)") as? Double {
            startTime = Date(timeIntervalSince1970: startTimestamp)
        }
        
        if let pauseTimestamp = userDefaults.object(forKey: "pauseTime_\(state.identifier)") as? Double {
            pauseTime = Date(timeIntervalSince1970: pauseTimestamp)
        }
        
        downloadProgress = userDefaults.double(forKey: "downloadProgress_\(state.identifier)")
        
        if state.downloadState == .downloading || state.downloadState == .paused {
            updateProgressOnForeground()
        }
    }
}


class DownloadButtonState: ObservableObject {
    @Published var downloadState: DownloadButton.DownloadState
    let identifier: String
    
    init(identifier: String, initialState: DownloadButton.DownloadState = .idle) {
        self.identifier = identifier
        self.downloadState = initialState
    }
}
