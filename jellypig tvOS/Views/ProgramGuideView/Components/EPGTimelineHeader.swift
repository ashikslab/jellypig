//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EPGTimelineHeader: View {

    let timeWindowStart: Date
    let timeWindowEnd: Date
    let pixelsPerMinute: CGFloat

    private let channelColumnWidth: CGFloat = 200
    private let timeSlotInterval: TimeInterval = 1800 // 30 minutes

    var body: some View {
        HStack(spacing: 0) {
            // Empty space for channel column
            Color.clear
                .frame(width: channelColumnWidth)

            // Time markers
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(timeSlots, id: \.self) { time in
                        timeMarker(for: time)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: 50)
        .background(Color(white: 0.15))
    }

    private var timeSlots: [Date] {
        var slots: [Date] = []
        var currentTime = timeWindowStart

        while currentTime <= timeWindowEnd {
            slots.append(currentTime)
            currentTime = currentTime.addingTimeInterval(timeSlotInterval)
        }

        return slots
    }

    private func timeMarker(for date: Date) -> some View {
        let slotWidth = CGFloat(timeSlotInterval / 60) * pixelsPerMinute

        return VStack(spacing: 4) {
            Text(date, style: .time)
                .font(.headline)
                .fontWeight(.semibold)

            Rectangle()
                .fill(Color.secondary)
                .frame(width: 2, height: 15)
        }
        .frame(width: slotWidth)
    }
}
