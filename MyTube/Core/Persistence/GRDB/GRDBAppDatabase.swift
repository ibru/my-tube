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

    init(fileName: String) throws {
        let fileManager = FileManager()
        let folderURL = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("database", isDirectory: true)

        // Support for tests: delete the database if requested
        if CommandLine.arguments.contains("-reset") {
            try? fileManager.removeItem(at: folderURL)
        }

        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let dbURL = folderURL.appendingPathComponent(fileName)
        let dbPool = try DatabasePool(path: dbURL.path)

        try self.init(dbPool)
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

    static var defaultDBFileName = "db.sqlite"
}

extension GRDBAppDatabase {
    /// Provides a read-only access to the database
    var dbReader: DatabaseReader {
        dbWriter
    }
}
