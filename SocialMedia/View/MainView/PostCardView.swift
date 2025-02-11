//
//  PostCardView.swift
//  SocialMedia
//
//  Created by Jose Garcia on 2/7/25.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    /// - Callbacks
    var onUpdate: (Post) -> ()
    var onDelete: () -> ()
    /// - View Properties
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var docListener: ListenerRegistration?
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.username)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical, 8)
                
                /// Post Image If Any
                if let postImageURL = post.imageURL {
                    GeometryReader {
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                
                PostInteraction()
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            /// Displaying Delete Button (if it's Author of that post)
            if post.userUID == userUID {
                Menu {
                    Button("Delete Post", role: .destructive, action: deletePost)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundStyle(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
            }
        })
        .onAppear {
            /// - Adding Only Once
            if docListener == nil {
                guard let postID = post.id else { return }
                docListener = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot, error in
                    if let snapshot {
                        if snapshot.exists {
                            /// - Document Updated
                            /// Fetching Updated Document
                            if let updatedPost = try? snapshot.data(as: Post.self) {
                                onUpdate(updatedPost)
                            }
                        } else {
                            /// - Document Deleted
                            onDelete()
                        }
                    }
                })
            }
        }
        .onDisappear {
            // MARK: Applying SnapShot Listener Only When the Post is Available on the Screen
            // Else Removing the Listener (It saves unwanted live updates from the posts which was swiped away from the screen
            if let docListener {
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    
    // MARK: Like/Dislike Interaction
    @ViewBuilder
    func PostInteraction() -> some View {
        HStack(spacing: 6) {
            Button {
                likePost()
            } label: {
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }

            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundStyle(.gray)
            
            Button {
                dislikePost()
            } label: {
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading, 25)
            
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .foregroundStyle(.black)
        .padding(.vertical, 8)
    }
    
    /// - Liking Post
    @MainActor
    func likePost() {
        Task {
            guard let postID = post.id else { return }
            if post.likedIDs.contains(userUID) {
                /// - Removing User ID From the Array
                let updateData: [String: Any] = [
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ]
                try await Firestore.firestore().collection("Posts").document(postID).updateData(updateData)
                print("Post liked")
            } else {
                /// - Adding User ID To Liked Array and Removing our ID from Disliked Array (if Added in Prior)
                let updateData: [String: Any] = [
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ]
                try await Firestore.firestore().collection("Posts").document(postID).updateData(updateData )
            }
        }
    }
    
    /// - Dislike Post
    @MainActor
    func dislikePost() {
        Task {
            guard let postID = post.id else { return }
            if post.dislikedIDs.contains(userUID) {
                /// - Removing User ID From the Array
                let updateData: [String: Any] = [
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ]
                try await Firestore.firestore().collection("Posts").document(postID).updateData(updateData)
            } else {
                /// - Adding User ID To Liked Array and Removing our ID from Disliked Array (if Added in Prior)
                let updateData: [String: Any] = [
                    "likedIDs": FieldValue.arrayRemove([userUID]),
                    "dislikedIDs": FieldValue.arrayUnion([userUID])
                ]
                try await Firestore.firestore().collection("Posts").document(postID).updateData(updateData)
            }
        }
    }
    
    /// - Deleting Post
    func deletePost() {
        Task {
            /// Step 1: Delete Image from Firebase Storage if present
            if post.imageReferenceID != "" {
                try await Storage.storage().reference().child("Post_Images").child(post.imageReferenceID).delete()
            }
            /// Step 2: Delete Firestore Document
            guard let postID = post.id else { return }
            try await Firestore.firestore().collection("Posts").document(postID).delete()
        }
    }
}
