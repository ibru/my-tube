//
//  GRDBAppDatabase.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/5/21.
//

import Foundation
import Combine
import GRDB

/// GRDBAppDatabase lets the application access the database.
///
/// It applies the pratices recommended at
/// https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md
struct GRDBAppDatabase {
    let dbWriter: DatabaseWriter

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1.0.0") { db in
            try db.create(table: "videos") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("videoID", .integer).unique().notNull()
                t.column("title", .text).notNull()
                t.column("dateSaved", .datetime).notNull()
                t.column("imageThumbnailURL", .text)
            }
        }
        return migrator
    }

    init(_ dbWriter: DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
}

extension GRDBAppDatabase {
    static let shared = makeShared()

    private static func makeShared() -> GRDBAppDatabase {
        do {
            let fileManager = FileManager()
            let folderURL = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("database", isDirectory: true)

            // Support for tests: delete the database if requested
            if CommandLine.arguments.contains("-reset") {
                try? fileManager.removeItem(at: folderURL)
            }

            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let dbURL = folderURL.appendingPathComponent("db.sqlite")
            let dbPool = try DatabasePool(path: dbURL.path)
            let appDatabase = try GRDBAppDatabase(dbPool)

            return appDatabase
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            //
            // Typical reasons for an error here include:
            // * The parent directory cannot be created, or disallows writing.
            // * The database is not accessible, due to permissions or data protection when the device is locked.
            // * The device is out of space.
            // * The database could not be migrated to its latest schema version.
            // Check the error message to determine what the actual problem was.
            fatalError("Unresolved error \(error)")
        }
    }
}

extension GRDBAppDatabase {
    enum ValidationError: Equatable, LocalizedError {
        case missingRequiredField(String)

        var errorDescription: String? {
            switch self {
            case .missingRequiredField(let name):
                return "Please provide value for required field `\(name)`"
            }
        }
    }
}

extension GRDBAppDatabase {
    /// Provides a read-only access to the database
    var dbReader: DatabaseReader {
        dbWriter
    }
}
