//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Get
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class ItemLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    // MARK: get

    override func get(page: Int) async throws -> [BaseItemDto] {

        // Use channel API for channels and channel folders
        if let parent = parent as? BaseItemDto, parent.type == .channel || parent.type == .channelFolderItem {
            print("🔵 DEBUG: Using channel API for parent type: \(parent.type), name: \(parent.name ?? "nil"), id: \(parent.id ?? "nil")")
            return try await getChannelItems(page: page, parent: parent)
        }

        print(
            "🟢 DEBUG: Using regular API, parent: \(String(describing: (parent as? BaseItemDto)?.name)), type: \(String(describing: (parent as? BaseItemDto)?.type))"
        )
        let parameters = itemParameters(for: page)
        print("📋 DEBUG: includeItemTypes: \(parameters.includeItemTypes ?? [])")
        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        print("📦 DEBUG: API returned \(response.value.items?.count ?? 0) items")
        let rawItems = response.value.items ?? []
        for item in rawItems.prefix(10) {
            print("  - Item: \(item.name ?? "nil"), type: \(item.type), collectionType: \(item.collectionType?.rawValue ?? "nil")")
        }

        // 1 - only care to keep collections that hold valid items
        // 2 - if parent is type `folder`, then we are in a folder-view
        //     context so change `collectionFolder` types to `folder`
        //     for better view handling
        let items = rawItems
            .filter { item in
                if let collectionType = item.collectionType {
                    let supported = CollectionType.supportedCases.contains(collectionType)
                    if !supported {
                        print("❌ DEBUG: Filtered out \(item.name ?? "nil") - unsupported collectionType: \(collectionType.rawValue)")
                    }
                    return supported
                }

                return true
            }
            .map { item in
                if parent?.libraryType == .folder, item.type == .collectionFolder {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }

        print("✅ DEBUG: After filtering, returning \(items.count) items")
        return items
    }

    // MARK: getChannelItems

    private func getChannelItems(page: Int, parent: BaseItemDto) async throws -> [BaseItemDto] {

        guard let channelID = parent.channelID ?? parent.id else {
            print("❌ DEBUG: No channelID found for parent: \(parent.name ?? "nil")")
            return []
        }

        var parameters = Paths.GetChannelItemsParameters()
        parameters.userID = userSession.user.id
        parameters.fields = .MinimumFields

        // If parent is a channel folder, set the folderID
        if parent.type == .channelFolderItem {
            parameters.folderID = parent.id
            print("📁 DEBUG: Channel folder - channelID: \(channelID), folderID: \(parent.id ?? "nil")")
        } else {
            print("📺 DEBUG: Channel root - channelID: \(channelID)")
        }

        // Page size
        parameters.limit = pageSize
        parameters.startIndex = page * pageSize

        let request = Paths.getChannelItems(channelID: channelID, parameters: parameters)
        let response = try await userSession.client.send(request)

        print("✅ DEBUG: Channel API returned \(response.value.items?.count ?? 0) items")

        return response.value.items ?? []
    }

    // MARK: item parameters

    private func itemParameters(for page: Int?) -> Paths.GetItemsByUserIDParameters {

        var parameters = Paths.GetItemsByUserIDParameters()

        parameters.enableUserData = true
        parameters.fields = .MinimumFields

        // Default values, expected to be overridden
        // by parent or filters
        parameters.includeItemTypes = BaseItemKind.supportedCases
        parameters.sortOrder = [.ascending]
        parameters.sortBy = [ItemSortBy.name.rawValue]

        /// Recursive should only apply to parents/folders and not to baseItems
        parameters.isRecursive = (parent as? BaseItemDto)?.isRecursiveCollection ?? true

        // Parent
        if let parent {
            parameters = parent.setParentParameters(parameters)
        }

        // Page size
        if let page {
            parameters.limit = pageSize
            parameters.startIndex = page * pageSize
        }

        // Filters
        if let filterViewModel {
            let filters = filterViewModel.currentFilters
            parameters.filters = filters.traits
            parameters.genres = filters.genres.map(\.value)
            parameters.sortBy = filters.sortBy.map(\.rawValue)
            parameters.sortOrder = filters.sortOrder
            parameters.tags = filters.tags.map(\.value)
            parameters.years = filters.years.compactMap { Int($0.value) }

            // Only set filtering on item types if selected, where
            // supported values should have been set by the parent.
            if filters.itemTypes.isNotEmpty {
                parameters.includeItemTypes = filters.itemTypes
            }

            if filters.letter.first?.value == "#" {
                parameters.nameLessThan = "A"
            } else {
                parameters.nameStartsWith = filters.letter
                    .map(\.value)
                    .filter { $0 != "#" }
                    .first
            }

            // Random sort won't take into account previous items, so
            // manual exclusion is necessary. This could possibly be
            // a performance issue for loading pages after already loading
            // many items, but there's nothing we can do about that.
            if filters.sortBy.first == ItemSortBy.random {
                parameters.excludeItemIDs = elements.compactMap(\.id)
            }
        }

        return parameters
    }

    // MARK: getRandomItem

    override func getRandomItem() async -> BaseItemDto? {

        var parameters = itemParameters(for: nil)
        parameters.limit = 1
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try? await userSession.client.send(request)

        return response?.value.items?.first
    }
}
