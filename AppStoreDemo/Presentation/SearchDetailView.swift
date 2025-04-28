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
    @ObservedObject var downloadButtonState: DownloadButtonState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 앱 헤더
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
                        
                        DownloadButton(
                            state: downloadButtonState,
                            title: "받기",
                            downloadDuration: 30.0,
                            onDownloadStart: {},
                            onDownloadPause: {},
                            onDownloadComplete: {}
                        )
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // 앱 정보 (가로 스크롤)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        InfoItem(title: "평점", value: "\(app.averageUserRating)")
                        InfoItem(title: "연령", value: "\(app.contentAdvisoryRating )")
                        InfoItem(title: "카테고리", value: app.genres.first ?? "N/A")
                        InfoItem(title: "개발자", value: app.sellerName)
                        InfoItem(title: "버전", value: app.version)
                    }
                    .padding(.horizontal)
                }
                
                // 스크린샷
                if !app.screenshotUrls.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(app.screenshotUrls, id: \.self) { url in
                                NavigationLink(destination: ScreenshotDetailView(screenshotUrls: app.screenshotUrls, selectedUrl: url)) {
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
                
                // 새로운 소식
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
                
                // 설명
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
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 80, alignment: .center)
    }
}

struct ScreenshotDetailView: View {
    let screenshotUrls: [String]
    let selectedUrl: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
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
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // 닫기 버튼
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

//#Preview {
//    SearchDetailView()
//}
