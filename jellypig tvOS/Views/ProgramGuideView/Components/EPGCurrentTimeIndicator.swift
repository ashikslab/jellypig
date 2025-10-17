//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EPGCurrentTimeIndicator: View {

    let timeWindowStart: Date
    let pixelsPerMinute: CGFloat
    let channelColumnWidth: CGFloat = 200

    @State
    private var currentTime = Date.now

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            if currentTime >= timeWindowStart {
                let offsetMinutes = currentTime.timeIntervalSince(timeWindowStart) / 60
                let xPosition = channelColumnWidth + (CGFloat(offsetMinutes) * pixelsPerMinute)

                if xPosition >= channelColumnWidth && xPosition <= geometry.size.width {
                    VStack(spacing: 0) {
                        // Time marker at top
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)

                            Text(currentTime, style: .time)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.red)
                                )
                                .offset(y: -25)
                        }
                        .frame(height: 50)

                        // Vertical line
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 2)
                    }
                    .offset(x: xPosition)
                }
            }
        }
        .allowsHitTesting(false) // Allow interactions to pass through
        .onReceive(timer) { _ in
            currentTime = Date.now
        }
    }
}
