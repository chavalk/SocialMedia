//
//  Post.swift
//  SocialMedia
//
//  Created by Jose Garcia on 2/7/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: Post Model
struct Post: Identifiable, Codable, Equatable, Hashable  {
    @DocumentID var id: String?
    var text: String
    var imageURL: URL?
    var imageReferenceID: String = ""
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    // MARK: Basic User Info
    var username: String
    var userUID: String
    var userProfileURL: URL
    
    enum CodingKeys: CodingKey {
        case id
        case text
        case imageURL
        case imageReferenceID
        case publishedDate
        case likedIDs
        case dislikedIDs
        case username
        case userUID
        case userProfileURL
    }
}
