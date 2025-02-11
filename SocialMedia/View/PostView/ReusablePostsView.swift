//
//  ReusablePostsView.swift
//  SocialMedia
//
//  Created by Jose Garcia on 2/7/25.
//

import SwiftUI
import Firebase

struct ReusablePostsView: View {
    @Binding var posts: [Post]
    /// - View Properties
    @State var isFetching: Bool = true
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                if isFetching {
                    ProgressView()
                        .padding(.top, 30)
                } else {
                    if posts.isEmpty {
                        /// - No Posts Found on Firestore
                        Text("No Posts Found")
                            .font(.callout)
                            .foregroundStyle(.gray)
                            .padding(.top, 30)
                    } else {
                        /// - Displaying Posts
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            /// - Scroll to Refresh
            isFetching = true
            posts = []
            await fetchPosts()
        }
        .task {
            /// - Fetching For One Time Only
            guard posts.isEmpty else { return }
            await fetchPosts()
        }
    }
    
    /// - Displaying Fetched Posts
    @ViewBuilder
    func Posts() -> some View {
        ForEach(posts) { post in
            PostCardView(post: post) { updatedPost in
                /// Updating Post in the Array
                if let index = posts.firstIndex(where: { post in
                    post.id == updatedPost.id
                }) {
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs  = updatedPost.dislikedIDs
                }
            } onDelete: {
                /// Removing Post From the Array
                withAnimation(.easeInOut(duration: 0.25)) {
                    posts.removeAll{post.id == $0.id }
                }
            }
            
            Divider()
                .padding(.horizontal, -15)
        }
    }
    
    /// - Fetching Posts
    func fetchPosts() async {
        do {
            var query: Query!
            query = Firestore.firestore().collection("Posts")
                .order(by: "publishedDate", descending: true)
                .limit(to: 20)
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts = fetchedPosts
                isFetching = false
            })
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
}
