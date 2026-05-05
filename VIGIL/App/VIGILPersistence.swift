//
//  VIGILPersistence.swift
//  VIGIL
//

import SwiftData

/// Container reference so App Intents (e.g. Live Activity STOP) can open a ModelContext safely.
enum VIGILPersistence {
    private static weak var cached: ModelContainer?
    private static weak var cachedMainContext: ModelContext?

    /// Call once after `ModelContainer` is constructed.
    @MainActor
    static func install(container: ModelContainer, mainContext: ModelContext?) {
        cached = container
        cachedMainContext = mainContext
    }

    @MainActor
    static func makeContext() -> ModelContext? {
        guard let cached else { return nil }
        if let cachedMainContext {
            return cachedMainContext
        }
        return ModelContext(cached)
    }
}
