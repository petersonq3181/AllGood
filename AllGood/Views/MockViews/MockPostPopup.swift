//
//  PostPopup.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/24/25.
//

import SwiftUI
import FirebaseFirestore

struct MockPostPopup: View {
    @Environment(\.colorTheme) var theme
    let post: Post
    
    let postViewModel: PostViewModel = PostViewModel(postManager: PostManager())

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let formatted = postViewModel.formattedLocation(for: post) {
                Text(formatted)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(post.timestamp.formatted(date: .long, time: .omitted))
                .font(.body)

            Text(post.type.displayName)
                .font(.body)
                .foregroundColor(theme.quaternary)

            Text(post.description)
                .font(.body)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .truncationMode(.tail)
                .padding(.top, 12)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Text("Post from")
                    .font(.body)
                    .foregroundColor(.primary)
                Text("@\(post.userName)")
                    .font(.body)
                    .foregroundColor(theme.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // force to left
        .padding(.horizontal, 25)
        .padding(.vertical, 30)
        .frame(maxWidth: 294, maxHeight: 432)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 8)
    }
}

#Preview {
    let mock = Post.mockPosts.first!
    MockPostPopup(post: mock)
}
