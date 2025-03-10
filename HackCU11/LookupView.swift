//
//  ContentView.swift
//  HackCU11
//
//  Created by Akshay Patnaik on 3/1/25.
//
// Akshay:  AIzaSyC83PbtVzqrGY5KmTzS1ow0a5V9wr_J0ns
// Sohan:   AIzaSyB_qxzPhvouxFbHn8vGPNopyNDIsxaTRhc
// Sohan2: AIzaSyDPzmFnladufje-IDp5RyUJdC_Nf1xvOVQ


import SwiftUI

struct LookupView: View {
    // Allows dismissing the view
    @Environment(\.presentationMode) var presentationMode
    
    @State private var inputText = ""
    @State private var apiOutput = ""
    @State private var isLoading = false
    @State private var currTitle = ""
    @State private var articles: [Article] = []
    @State private var selectedArticle: Article? = nil

    struct Article: Identifiable {
        let id = UUID()
        let title: String
        let url: String
        let summary: String
        let details: String
    }

    let model = GenerativeModel(
        name: "gemini-1.5-pro",
        apiKey: "AIzaSyDPzmFnladufje-IDp5RyUJdC_Nf1xvOVQ"
    )
    
    // MARK: - Custom init to make NavBar background transparent
    init() {
        let appearance = UINavigationBarAppearance()
        // Make background fully transparent
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear

        // Apply to both standard (inline) and scroll-edge (large title) appearances
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Lighter gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all) // Extend under the dynamic island / status bar

                VStack {
                    // Input field with search icon
                    HStack {
                        TextField("Enter Semantic Scholar ID or Topic", text: $inputText)
                            .padding(.vertical, 10)
                            .padding(.leading, 40)
                            .background(Color.clear)
                            .overlay(
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.purple)
                                        .padding(.leading, 8)
                                    Spacer()
                                }
                            )
                            .padding(.horizontal)
                    }

                    // Underline for input field
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.purple)
                        .padding(.bottom, 15)

                    // Fetch data button
                    Button(action: {
                        isLoading = true
                        articles.removeAll()
                        Task {
                            await fetchRelevantArticles()
                            isLoading = false
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        } else {
                            Text("Fetch Relevant Articles")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        }
                    }
                    .padding(.horizontal, 16)
                    .disabled(isLoading)

                    // Display list of relevant articles
                    List(articles) { article in
                        VStack(alignment: .leading) {
                            Text(article.title)
                                .font(.headline)
                            Text(article.summary)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Button("More Info") {
                                selectedArticle = article
                            }
                            .foregroundColor(.blue)
                        }
                        .padding()
                        // Make each row transparent
                        .listRowBackground(Color.clear)
                    }
                    // Make the list background transparent (iOS 16+)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .listStyle(.plain)

                    Spacer()
                }
                .padding()
                .overlay(
                    Group {
                        if let selected = selectedArticle {
                            ZStack {
                                Color.black.opacity(0.4)
                                    .edgesIgnoringSafeArea(.all)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(selected.title)
                                        .font(.headline)
                                    Text(selected.details)
                                        .font(.body)
                                    Button("Close") {
                                        selectedArticle = nil
                                    }
                                    .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            }
                        }
                    }
                )
            }
            .navigationTitle("Lookup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Fetch relevant articles
    func fetchRelevantArticles() async {
        guard let encodedQuery = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            apiOutput = "Invalid search query."
            return
        }

        let urlString =
            "https://api.semanticscholar.org/graph/v1/paper/search?query=\(encodedQuery)&fields=title,url,citationCount,authors,abstract&offset=0&limit=10&minCitationCount=5"
        guard let url = URL(string: urlString) else {
            apiOutput = "Invalid URL."
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataArray = json["data"] as? [[String: Any]] {
                articles = dataArray.compactMap { paper in
                    guard let title = paper["title"] as? String,
                          let url = paper["url"] as? String,
                          let abstract = paper["abstract"] as? String else {
                        return nil
                    }
                    let authors = (paper["authors"] as? [[String: String]])?
                        .compactMap { $0["name"] }
                        .joined(separator: ", ") ?? "Unknown Authors"
                    let citationCount = paper["citationCount"] as? Int ?? 0
                    let details = """
                        Authors: \(authors)
                        Citations: \(citationCount)
                        URL: \(url)
                        """
                    return Article(title: title, url: url, summary: abstract, details: details)
                }
            } else {
                apiOutput = "Could not parse response."
            }
        } catch {
            apiOutput = "Error fetching data: \(error)"
        }
    }
}

struct LookupView_Previews: PreviewProvider {
    static var previews: some View {
        LookupView()
    }
}
