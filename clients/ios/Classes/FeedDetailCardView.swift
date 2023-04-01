//
//  FeedDetailCardView.swift
//  NewsBlur
//
//  Created by David Sinclair on 2023-02-01.
//  Copyright © 2023 NewsBlur. All rights reserved.
//

import SwiftUI
import SwipeCell

/// Card view within the feed detail view, representing a story row in list layout or a story card in grid layout.
struct CardView: View {
    let feedDetailInteraction: FeedDetailInteraction
    
    let cache: StoryCache
    
    let story: Story
    
    @State private var isPinned: Bool = false
    
    var body: some View {
        let swipeSaveButton = SwipeCellButton(
            buttonStyle: .view,
            title: "",
            systemImage: "",
            titleColor: .white,
            imageColor: .white,
            view: {
                AnyView(
                    VStack(spacing: 5) {
                        Image(uiImage: UIImage(named: "saved-stories") ?? UIImage())
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                        Text(story.isSaved ? "Unsave" : "Save")
                            .font(.callout)
                            .bold()
                            .foregroundColor(.white)
                    }
                )},
            backgroundColor: .purple,
            action: {
                cache.appDelegate.storiesCollection.toggleStorySaved(story.dictionary)
                cache.appDelegate.feedDetailViewController.reload()
            },
            feedback: true
        )
        
        let swipeReadButton = SwipeCellButton(
            buttonStyle: .view,
            title: "",
            systemImage: "",
            titleColor: .white,
            imageColor: .white,
            view: {
                AnyView(
                    VStack(spacing: 5) {
                        Image(uiImage: UIImage(named: "mark-read") ?? UIImage())
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                        Text(story.isRead ? "Unread" : "Read")
                            .font(.callout)
                            .bold()
                            .foregroundColor(.white)
                    }
                )},
            backgroundColor: .blue,
            action: {
                cache.appDelegate.storiesCollection.toggleStoryUnread(story.dictionary)
                cache.appDelegate.feedDetailViewController.reload()
            },
            feedback: true
        )
        
        ZStack(alignment: .leading) {
            if story.isSelected || cache.isGrid {
                RoundedRectangle(cornerRadius: 10).foregroundColor(highlightColor)
                
                CardFeedBarView(cache: cache, story: story)
                    .padding(.leading, 2)
            } else {
                CardFeedBarView(cache: cache, story: story)
                    .padding(.leading, 2)
            }
            
            VStack {
                if cache.isGrid, let previewImage {
                    gridPreview(image: previewImage)
                }
                
                HStack {
                    if !cache.isGrid, cache.settings.preview.isLeft, let previewImage {
                        listPreview(image: previewImage)
                    }
                    
                    CardContentView(cache: cache, story: story)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding([.leading, .trailing], 15)
                        .padding([.top, .bottom], cache.settings.spacing == .compact ? 10 : 15)
                    
                    if !cache.isGrid, !cache.settings.preview.isLeft, let previewImage {
                        listPreview(image: previewImage)
                    }
                }
            }
        }
        .opacity(story.isRead ? 0.7 : 1)
        .if(cache.isGrid || story.isSelected) { view in
            view.clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .if(story.isSelected) { view in
            view.padding(10)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture {
            feedDetailInteraction.tapped(story: story)
        }
        .swipeCell(cellPosition: .both, leftSlot: SwipeCellSlot(slots: [swipeSaveButton], slotStyle: .destructive, buttonWidth: 80), rightSlot: SwipeCellSlot(slots: [swipeReadButton], slotStyle: .destructive, buttonWidth: 80))
        .dismissSwipeCellForScrollViewForLazyVStack()
        .contextMenu {
            Button {
                cache.appDelegate.storiesCollection.toggleStoryUnread(story.dictionary)
                cache.appDelegate.feedDetailViewController.reload()
            } label: {
                Label(story.isRead ? "Mark as unread" : "Mark as read", image: "mark-read")
            }
            
            Button {
                cache.appDelegate.feedDetailViewController.markFeedsRead(fromTimestamp: story.timestamp, andOlder: false)
                cache.appDelegate.feedDetailViewController.reload()
            } label: {
                Label("Mark newer stories read", image: "mark-read")
            }
            
            Button {
                cache.appDelegate.feedDetailViewController.markFeedsRead(fromTimestamp: story.timestamp, andOlder: true)
                cache.appDelegate.feedDetailViewController.reload()
            } label: {
                Label("Mark older stories read", image: "mark-read")
            }
            
            Button {
                cache.appDelegate.storiesCollection.toggleStorySaved(story.dictionary)
                cache.appDelegate.feedDetailViewController.reload()
            } label: {
                Label(story.isSaved ? "Unsave this story" : "Save this story", image: "saved-stories")
            }
            
            Button {
                cache.appDelegate.showSend(to: cache.appDelegate.feedDetailViewController, sender: cache.appDelegate.feedDetailViewController.view)
            } label: {
                Label("Send this story to…", image: "email")
            }
            
            Button {
                cache.appDelegate.openTrainStory(nil)
            } label: {
                Label("Train this story", image: "train")
            }
        }
    }
    
    var highlightColor: Color {
        if cache.isGrid {
            return Color.themed([0xFDFCFA, 0xFFFDEF, 0x4F4F4F, 0x292B2C])
        } else {
            return Color.themed([0xFFFDEF, 0xEEECCD, 0x303A40, 0x303030])
        }
    }
    
    var previewImage: UIImage? {
        guard cache.settings.preview != .none, let image = cache.appDelegate.cachedImage(forStoryHash: story.hash), image.isKind(of: UIImage.self) else {
            return nil
        }
        
        return image
    }
    
    @ViewBuilder
    func gridPreview(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: cache.settings.gridHeight / 3)
            .cornerRadius(10, corners: .topRight)
            .padding(0)
            .padding(.leading, 8)
    }
    
    @ViewBuilder
    func listPreview(image: UIImage) -> some View {
        let isLeft = cache.settings.preview.isLeft
        
        if cache.settings.preview.isSmall {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding([.top, .bottom], 10)
                .padding(.leading, isLeft ? 15 : -10)
                .padding(.trailing, isLeft ? -10 : 10)
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 90)
                .clipped()
                .padding(.leading, isLeft ? 8 : -10)
                .padding(.trailing, isLeft ? -10 : 0)
        }
    }
}

struct CardContentView: View {
    let cache: StoryCache
    
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading) {
            if story.isRiverOrSocial, let feedImage {
                HStack {
                    Image(uiImage: feedImage)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(.leading, 24)
                    
                    Text(story.feedName)
                        .font(font(named: "WhitneySSm-Medium", size: 12))
                        .lineLimit(1)
                        .foregroundColor(feedColor)
                }
            }
            
            HStack(alignment: .top) {
                if let unreadImage {
                    Image(uiImage: unreadImage)
                        .resizable()
                        .opacity(story.isRead ? 0.15 : 1)
                        .frame(width: 16, height: 16)
                        .padding(.top, 3)
                }
                
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        if story.isSaved, let image = UIImage(named: "saved-stories") {
                            Image(uiImage: image)
                                .resizable()
                                .opacity(story.isRead ? 0.15 : 1)
                                .frame(width: 16, height: 16)
                                .padding(.top, 3)
                        }
                        
                        if story.isShared, let image = UIImage(named: "share") {
                            Image(uiImage: image)
                                .resizable()
                                .opacity(story.isRead ? 0.15 : 1)
                                .frame(width: 16, height: 16)
                                .padding(.top, 3)
                        }
                        
                        Text(story.title)
                            .font(font(named: "WhitneySSm-Medium", size: 18).bold())
                            .foregroundColor(titleColor)
                            .lineLimit(cache.isGrid ? StorySettings.Content.titleLimit : cache.settings.content.limit)
                            .truncationMode(.tail)
                    }
                    .padding(.bottom, cache.settings.spacing == .compact ? -5 : 0)
                    
                    if cache.isGrid || cache.settings.content != .title {
                        Text(story.content)
                            .font(font(named: "WhitneySSm-Book", size: 13))
                            .foregroundColor(contentColor)
                            .lineLimit(cache.isGrid ? StorySettings.Content.contentLimit : cache.settings.content.limit)
                            .truncationMode(.tail)
                            .padding(.top, 5)
                            .padding(.bottom, cache.settings.spacing == .compact ? -5 : 0)
                    }
                    
                    Spacer()
                    
                    Text(story.dateAndAuthor)
                        .font(font(named: "WhitneySSm-Medium", size: 12))
                        .foregroundColor(dateAndAuthorColor)
                        .padding(.top, 5)
                }
            }
        }
    }
    
    var feedImage: UIImage? {
        if let image = cache.appDelegate.getFavicon(story.feedID) {
            return Utilities.roundCorneredImage(image, radius: 4, convertTo: CGSizeMake(16, 16))
        } else {
            return nil
        }
    }
    
    var unreadImage: UIImage? {
        guard story.isReadAvailable else {
            return nil
        }
        
        switch story.score {
        case -1:
            return UIImage(named: "indicator-hidden")
        case 1:
            return UIImage(named: "indicator-focus")
        default:
            return UIImage(named: "indicator-unread")
        }
    }
    
    func font(named: String, size: CGFloat) -> Font {
        return Font.custom(named, size: size + cache.settings.fontSize.offset, relativeTo: .caption)
    }
    
    var feedColor: Color {
        return contentColor
    }
    
    var titleColor: Color {
        if story.isSelected {
            return Color.themed([0x686868, 0xA0A0A0])
        } else if story.isRead {
            return Color.themed([0x585858, 0x585858, 0x989898, 0x888888])
        } else {
            return Color.themed([0x111111, 0x333333, 0xD0D0D0, 0xCCCCCC])
        }
    }
    
    var contentColor: Color {
        if story.isSelected, story.isRead {
            return Color.themed([0xB8B8B8, 0xB8B8B8, 0xA0A0A0, 0x707070])
        } else if story.isSelected {
            return Color.themed([0x888785, 0x686868, 0xA9A9A9, 0x989898])
        } else if story.isRead {
            return Color.themed([0xB8B8B8, 0xB8B8B8, 0xA0A0A0, 0x707070])
        } else {
            return Color.themed([0x404040, 0x404040, 0xC0C0C0, 0xB0B0B0])
        }
    }
    
    var dateAndAuthorColor: Color {
        return contentColor
    }
}

struct CardFeedBarView: View {
    let cache: StoryCache
    
    let story: Story
    
    var body: some View {
        GeometryReader { geometry in
            if let color = story.feedColorBarLeft {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                }
                .stroke(Color(color), lineWidth: 4)
            }
            
            if let color = story.feedColorBarRight {
                Path { path in
                    path.move(to: CGPoint(x: 4, y: 0))
                    path.addLine(to: CGPoint(x: 4, y: geometry.size.height))
                }
                .stroke(Color(color), lineWidth: 4)
            }
        }
    }
}
