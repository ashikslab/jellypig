//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EPGChannelRow: View {

    let channelProgram: ChannelProgram
    let timeWindowStart: Date
    let timeWindowEnd: Date
    let pixelsPerMinute: CGFloat

    private let channelColumnWidth: CGFloat = 200

    var body: some View {
        HStack(spacing: 0) {
            // Channel info column (fixed width on left)
            channelInfoView
                .frame(width: channelColumnWidth)

            // Programs timeline
            programsTimeline
        }
        .frame(height: 120)
    }

    private var channelInfoView: some View {
        VStack(spacing: 8) {
            ZStack {
                Color.clear

                ImageView(channelProgram.portraitImageSources(maxWidth: 80))
                    .image {
                        $0.aspectRatio(contentMode: .fit)
                    }
                    .failure {
                        SystemImageContentView(systemName: channelProgram.systemImage, ratio: 0.66)
                            .background(color: .clear)
                    }
                    .placeholder { _ in
                        EmptyView()
                    }
            }
            .frame(width: 80, height: 80)
            .aspectRatio(1.0, contentMode: .fit)

            Text(channelProgram.displayTitle)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }

    private var programsTimeline: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(channelProgram.programs, id: \.id) { program in
                        if let startDate = program.startDate,
                           let endDate = program.endDate
                        {

                            let duration = endDate.timeIntervalSince(startDate) / 60 // minutes
                            let cellWidth = CGFloat(duration) * pixelsPerMinute

                            let isCurrentlyAiring = (startDate ... endDate).contains(Date.now)

                            EPGProgramCell(
                                program: program,
                                channel: channelProgram.channel,
                                cellWidth: max(cellWidth, 150), // Minimum width for readability
                                isCurrentlyAiring: isCurrentlyAiring
                            )
                            .id(program.id)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .onAppear {
                // Scroll to currently airing program
                if let currentProgram = channelProgram.currentProgram {
                    proxy.scrollTo(currentProgram.id, anchor: .leading)
                }
            }
        }
    }
}
