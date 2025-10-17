//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ProgramGuideView: View {

    @StateObject
    private var viewModel = EPGViewModel()

    // Configuration
    private let pixelsPerMinute: CGFloat = 3.0

    @State
    private var currentTime = Date.now

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(red: 0.15, green: 0.05, blue: 0.1)
                .ignoresSafeArea()

            content
        }
        .onAppear {
            viewModel.send(.refresh)
        }
        .onReceive(timer) { _ in
            currentTime = Date.now
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .initial:
            ProgressView()
                .scaleEffect(1.5)

        case .refreshing:
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Loading Program Guide...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

        case .content:
            if viewModel.channelPrograms.isEmpty {
                emptyView
            } else {
                epgGridView
            }

        case let .error(error):
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

                Text("Error Loading Guide")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 100)

                Button("Retry") {
                    viewModel.send(.refresh)
                }
                .buttonStyle(.card)
            }
        }
    }

    private var epgGridView: some View {
        ZStack {
            VStack(spacing: 0) {
                // Timeline header
                EPGTimelineHeader(
                    timeWindowStart: viewModel.timeWindowStart,
                    timeWindowEnd: viewModel.timeWindowEnd,
                    pixelsPerMinute: pixelsPerMinute
                )

                Divider()

                // Channel rows
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.channelPrograms, id: \.id) { channelProgram in
                            EPGChannelRow(
                                channelProgram: channelProgram,
                                timeWindowStart: viewModel.timeWindowStart,
                                timeWindowEnd: viewModel.timeWindowEnd,
                                pixelsPerMinute: pixelsPerMinute
                            )

                            Divider()
                        }
                    }
                }
            }

            // Current time indicator overlay
            EPGCurrentTimeIndicator(
                timeWindowStart: viewModel.timeWindowStart,
                pixelsPerMinute: pixelsPerMinute
            )
        }
        .navigationTitle("Program Guide")
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("No Channels Available")
                .font(.title)
                .fontWeight(.semibold)

            Text("Check your Live TV setup in Jellyfin")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 100)
        }
    }
}
