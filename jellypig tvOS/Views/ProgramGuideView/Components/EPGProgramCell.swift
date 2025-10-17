//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EPGProgramCell: View {

    @EnvironmentObject
    private var router: VideoPlayerWrapperCoordinator.Router

    @Environment(\.isFocused)
    private var isFocused

    let program: BaseItemDto
    let channel: BaseItemDto
    let cellWidth: CGFloat
    let isCurrentlyAiring: Bool

    @State
    private var currentTime = Date.now

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        Button {
            handleSelection()
        } label: {
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(borderColor, lineWidth: isFocused ? 4 : 2)
                    )

                // Progress indicator for currently airing programs
                if isCurrentlyAiring, let progress = program.programProgress(relativeTo: currentTime) {
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(width: geometry.size.width * progress)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.displayTitle)
                        .font(.callout)
                        .fontWeight(isFocused ? .semibold : .regular)
                        .lineLimit(2)
                        .foregroundColor(isFocused ? .black : .white)

                    if let startDate = program.startDate,
                       let endDate = program.endDate
                    {
                        HStack(spacing: 4) {
                            Text(startDate, style: .time)
                            Text("-")
                            Text(endDate, style: .time)
                        }
                        .font(.caption2)
                        .foregroundColor(isFocused ? .black.opacity(0.7) : .secondary)
                    }

                    if isCurrentlyAiring {
                        Text("Live")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(isFocused ? .black : .red)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: cellWidth, height: 100)
        .buttonStyle(.card)
        .onReceive(timer) { _ in
            currentTime = Date.now
        }
    }

    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isCurrentlyAiring {
            return Color.accentColor.opacity(0.2)
        } else {
            return Color(white: 0.2)
        }
    }

    private var borderColor: Color {
        if isFocused {
            return .white
        } else if isCurrentlyAiring {
            return .accentColor
        } else {
            return Color(white: 0.3)
        }
    }

    private func handleSelection() {
        // For Live TV from EPG, we play the channel
        // If program is currently airing, playback will start from current position
        // If program is in the future, channel will start playing whatever is currently on
        guard let mediaSource = channel.mediaSources?.first else { return }

        router.route(
            to: \.liveVideoPlayer,
            LiveVideoPlayerManager(item: channel, mediaSource: mediaSource)
        )
    }
}
