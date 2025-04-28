//
//  SearchDetailView.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/28/25.
//

import SwiftUI

struct SearchDetailView: View {
    let app: ItunesSearchResponseDTO
    @State private var isExpanded: Bool = false
    @Environment(\.injected) private var container: DIContainer
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 15) {
                    AsyncImage(url: URL(string: app.artworkUrl512)) { image in
                        image.resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } placeholder: {
                        ProgressView()
                            .frame(width: 100, height: 100)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(app.trackName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(app.sellerName)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        DownloadButton(
                            appId: app.bundleId,
                            title: "받기",
                            downloadDuration: 30.0,
                            appName: app.trackName,
                            iconUrl: app.artworkUrl60
                        )
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        InfoItem(title: "평점", value: String(format: "%.1f", app.averageUserRating))
                        InfoItem(title: "연령", value: "\(app.contentAdvisoryRating )")
                        InfoItem(title: "카테고리", value: app.genres.first ?? "N/A")
                        InfoItem(title: "개발자", value: app.sellerName)
                        InfoItem(title: "버전", value: app.version)
                    }
                    .padding(.horizontal)
                }
                
                if !app.screenshotUrls.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(app.screenshotUrls, id: \.self) { url in
                                NavigationLink(destination: ScreenshotDetailView(screenshotUrls: app.screenshotUrls, selectedUrl: url, app: app)) {
                                    AsyncImage(url: URL(string: url)) { image in
                                        image.resizable()
                                            .scaledToFit()
                                            .frame(width: UIScreen.main.bounds.width / 3 - 16, height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("새로운 소식")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(app.releaseNotes)
                        .font(.body)
                        .foregroundColor(.gray)
                        .lineLimit(isExpanded ? nil : 3)
                    
                    if (app.releaseNotes.count) > 100 {
                        Button(action: {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "접기" : "더보기")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("설명")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(app.description)
                        .font(.body)
                        .foregroundColor(.gray)
                    
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(app.trackName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
}
struct InfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 80, alignment: .center)
    }
}

struct ScreenshotDetailView: View {
    let screenshotUrls: [String]
    let selectedUrl: String
    let app: ItunesSearchResponseDTO
    @Environment(\.dismiss) private var dismiss
    @Environment(\.injected) private var container: DIContainer
    
    var body: some View {
        ZStack {
            TabView(selection: Binding(
                get: { selectedUrl },
                set: { _ in }
            )) {
                ForEach(screenshotUrls, id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { image in
                        image.resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .tag(url)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Text("완료")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                DownloadButton(
                    appId: app.bundleId,
                    title: "받기",
                    downloadDuration: 30.0,
                    appName: app.trackName,
                    iconUrl: app.artworkUrl60
                )
                .scaleEffect(0.85)
            }
        }
    }
}

//#Preview {
//    SearchDetailView()
//}
