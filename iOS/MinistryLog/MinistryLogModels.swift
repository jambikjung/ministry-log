import Foundation
import SwiftData

// CloudKit private database: these records belong to the signed-in iCloud account.
@Model final class MinistryLog {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var hours: Double = 0
    var returnVisits: Int = 0
    var bibleStudies: Int = 0
    var companionsText: String = ""
    var note: String = ""

    init(date: Date = .now, hours: Double = 0, returnVisits: Int = 0,
         bibleStudies: Int = 0, companionsText: String = "", note: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.hours = hours
        self.returnVisits = returnVisits
        self.bibleStudies = bibleStudies
        self.companionsText = companionsText
        self.note = note
    }
}

@Model final class MinistryPerson {
    var id: String = UUID().uuidString
    var name: String = ""
    var kind: String = "재방문"
    var mapURL: String = ""
    var nextVisit: Date?
    var lastVisited: Date?
    var note: String = ""

    init(name: String = "", kind: String = "재방문", mapURL: String = "",
         nextVisit: Date? = nil, lastVisited: Date? = nil, note: String = "") {
        self.name = name
        self.kind = kind
        self.mapURL = mapURL
        self.nextVisit = nextVisit
        self.lastVisited = lastVisited
        self.note = note
    }
}

@Model final class MinistryPartner {
    var id: String = UUID().uuidString
    var name: String = ""
    var note: String = ""

    init(name: String = "", note: String = "") {
        self.name = name
        self.note = note
    }
}

@Model final class MinistryDayPlan {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var activity: String = ""
    var note: String = ""
    var hours: Double = 0
    var returnVisits: Int = 0
    var bibleStudies: Int = 0
    var companionsText: String = ""

    init(date: Date = .now, activity: String = "", note: String = "",
         hours: Double = 0, returnVisits: Int = 0, bibleStudies: Int = 0,
         companionsText: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.activity = activity
        self.note = note
        self.hours = hours
        self.returnVisits = returnVisits
        self.bibleStudies = bibleStudies
        self.companionsText = companionsText
    }
}

@Model final class MinistryMonthRate {
    var id: String = UUID().uuidString
    var monthKey: String = ""
    var visitsPerHour: Double = 0
    var studiesPerHour: Double = 0

    init(monthKey: String = "", visitsPerHour: Double = 0, studiesPerHour: Double = 0) {
        self.monthKey = monthKey
        self.visitsPerHour = visitsPerHour
        self.studiesPerHour = studiesPerHour
    }
}

enum MinistryDate {
    static let korean = Locale(identifier: "ko_KR")
    static let calendar = Calendar(identifier: .gregorian)

    static func monthKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    static func weekday(_ date: Date) -> String {
        date.formatted(.dateTime.locale(korean).weekday(.wide))
    }

    static func koreanDate(_ date: Date) -> String {
        date.formatted(.dateTime.locale(korean).year().month().day())
    }

    static func count(_ value: Double) -> Int {
        Int(value.rounded())
    }
}
