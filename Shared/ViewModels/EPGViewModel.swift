//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import SwiftUI

final class EPGViewModel: ViewModel, Stateful {

    enum Action: Equatable {
        case refresh
    }

    enum BackgroundState: Hashable {
        case refresh
    }

    enum State: Hashable {
        case initial
        case refreshing
        case content
        case error(JellyfinAPIError)
    }

    @Published
    var channelPrograms: [ChannelProgram] = []

    @Published
    var state: State = .initial

    @Published
    var backgroundStates: Set<BackgroundState> = []

    // Time window configuration
    var timeWindowStart: Date {
        Calendar.current.date(byAdding: .hour, value: -1, to: .now) ?? .now
    }

    var timeWindowEnd: Date {
        Calendar.current.date(byAdding: .hour, value: 12, to: .now) ?? .now
    }

    // Auto-refresh timer
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 300 // 5 minutes

    override init() {
        super.init()
        setupRefreshTimer()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            Task {
                await fetchChannelsAndPrograms()
            }
            return .refreshing
        }
    }

    func fetchChannelsAndPrograms() async {
        do {
            state = .refreshing

            // Fetch all channels
            var channelParameters = Paths.GetLiveTvChannelsParameters()
            channelParameters.fields = .MinimumFields
            channelParameters.userID = userSession.user.id
            channelParameters.sortBy = [ItemSortBy.name]
            // No limit - fetch all channels for EPG

            let channelRequest = Paths.getLiveTvChannels(parameters: channelParameters)
            let channelResponse = try await userSession.client.send(channelRequest)

            guard let channels = channelResponse.value.items, !channels.isEmpty else {
                state = .content
                return
            }

            // Fetch programs for all channels in time window
            var programParameters = Paths.GetLiveTvProgramsParameters()
            programParameters.channelIDs = channels.compactMap(\.id)
            programParameters.userID = userSession.user.id
            programParameters.minEndDate = timeWindowStart
            programParameters.maxStartDate = timeWindowEnd
            programParameters.sortBy = [ItemSortBy.startDate]
            programParameters.fields = .MinimumFields

            let programRequest = Paths.getLiveTvPrograms(parameters: programParameters)
            let programResponse = try await userSession.client.send(programRequest)

            // Group programs by channel
            let groupedPrograms = (programResponse.value.items ?? [])
                .grouped { program in
                    channels.first(where: { $0.id == program.channelID })
                }

            // Create ChannelProgram objects
            let programs: [ChannelProgram] = channels
                .reduce(into: [:]) { partialResult, channel in
                    partialResult[channel] = (groupedPrograms[channel] ?? [])
                        .sorted(using: \.startDate)
                }
                .map(ChannelProgram.init)
                .sorted(using: \.channel.name)

            await MainActor.run {
                self.channelPrograms = programs
                self.state = .content
            }

        } catch {
            await MainActor.run {
                self.state = .error(JellyfinAPIError(error.localizedDescription))
            }
        }
    }

    private func setupRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.fetchChannelsAndPrograms()
            }
        }
    }
}
