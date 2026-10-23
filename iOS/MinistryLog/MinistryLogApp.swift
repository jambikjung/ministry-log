import SwiftUI
import SwiftData

@main
struct MinistryLogApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema([
            MinistryLog.self,
            MinistryPerson.self,
            MinistryPartner.self,
            MinistryDayPlan.self,
            MinistryMonthRate.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.jambikjung.MinistryLog")
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("iCloud 저장소를 준비하지 못했습니다: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MinistryRootView()
        }
        .modelContainer(container)
    }
}
