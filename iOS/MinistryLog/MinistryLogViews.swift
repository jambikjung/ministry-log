import SwiftUI
import SwiftData

struct MinistryRootView: View {
    var body: some View {
        TabView {
            MinistryHomeView().tabItem { Label("오늘", systemImage: "house") }
            LogListView().tabItem { Label("기록", systemImage: "list.clipboard") }
            MonthPlanView().tabItem { Label("월 계획", systemImage: "calendar") }
            PeopleListView().tabItem { Label("대상자", systemImage: "person.2") }
            SettingsView().tabItem { Label("설정", systemImage: "gearshape") }
        }
        .tint(.teal)
    }
}

struct MinistryHomeView: View {
    @Query(sort: \MinistryLog.date, order: .reverse) private var logs: [MinistryLog]
    @Query private var people: [MinistryPerson]
    @Query private var partners: [MinistryPartner]
    @Query private var plans: [MinistryDayPlan]
    @State private var month = Date.now

    private var todayLogs: [MinistryLog] { logs.filter { Calendar.current.isDateInToday($0.date) } }
    private var todayPlan: MinistryDayPlan? { plans.first { Calendar.current.isDateInToday($0.date) } }
    private var dueStudies: [MinistryPerson] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return people.filter { $0.kind == "성서 연구" && ($0.lastVisited ?? .distantPast) < cutoff }
    }
    private var completedCompanions: Set<String> {
        Set(logs.filter { MinistryDate.monthKey($0.date) == MinistryDate.monthKey(month) }
            .flatMap { $0.companionsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } })
    }
    private var companionsToMeet: [String] {
        let names = partners.map(\.name)
        return names.filter { !completedCompanions.contains($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("오늘의 목표 · \(MinistryDate.koreanDate(.now))") {
                    goalRow("봉사 시간", actual: todayLogs.reduce(0) { $0 + $1.hours }, target: todayPlan?.hours ?? 0, unit: "시간")
                    goalRow("재방문", actual: Double(todayLogs.reduce(0) { $0 + $1.returnVisits }), target: Double(todayPlan?.returnVisits ?? 0), unit: "건")
                    goalRow("성서 연구", actual: Double(todayLogs.reduce(0) { $0 + $1.bibleStudies }), target: Double(todayPlan?.bibleStudies ?? 0), unit: "건")
                    if let activity = todayPlan?.activity, !activity.isEmpty { Text(activity).font(.subheadline) }
                    if let note = todayPlan?.note, !note.isEmpty { Text(note).foregroundStyle(.secondary) }
                }
                Section("최근 7일 미방문 성서 연구") {
                    if dueStudies.isEmpty { Text("방문할 성서 연구가 없습니다.").foregroundStyle(.secondary) }
                    ForEach(dueStudies) { person in
                        VStack(alignment: .leading) {
                            Text(person.name)
                            if let date = person.lastVisited { Text("마지막 방문: \(MinistryDate.koreanDate(date))").font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
                Section("\(month.formatted(.dateTime.locale(MinistryDate.korean).year().month())) 아직 함께 봉사하지 않은 봉사짝") {
                    if companionsToMeet.isEmpty { Text("미완료 봉사짝이 없습니다.").foregroundStyle(.secondary) }
                    ForEach(companionsToMeet, id: \.self) { Text($0) }
                    if partners.isEmpty { Text("설정에서 봉사짝을 등록하세요.").foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("야외 봉사 기록")
        }
    }

    private func goalRow(_ title: String, actual: Double, target: Double, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(actual.formatted(.number.precision(.fractionLength(0...2)))) / \(target.formatted(.number.precision(.fractionLength(0...2)))) \(unit)")
                .foregroundStyle(.secondary)
        }
    }
}

struct LogListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MinistryLog.date, order: .reverse) private var logs: [MinistryLog]
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(logs) { log in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(MinistryDate.koreanDate(log.date)).font(.headline)
                        Text("시간 \(log.hours.formatted()) · 재방문 \(log.returnVisits)건 · 연구 \(log.bibleStudies)건")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if !log.companionsText.isEmpty { Text("봉사짝: \(log.companionsText)").font(.caption) }
                        if !log.note.isEmpty { Text(log.note).font(.caption) }
                    }
                }
                .onDelete { offsets in offsets.map { logs[$0] }.forEach(context.delete) }
            }
            .navigationTitle("봉사 기록")
            .toolbar { Button("추가", systemImage: "plus") { showingEditor = true } }
            .sheet(isPresented: $showingEditor) { LogEditorView() }
        }
    }
}

struct LogEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date.now
    @State private var hours = 0.0
    @State private var visits = 0
    @State private var studies = 0
    @State private var companions = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("날짜", selection: $date, displayedComponents: .date)
                LabeledContent("봉사 시간") { TextField("시간", value: $hours, format: .number).keyboardType(.decimalPad) }
                Stepper("재방문 \(visits)건", value: $visits, in: 0...999)
                Stepper("성서 연구 \(studies)건", value: $studies, in: 0...999)
                TextField("봉사짝 (쉼표로 구분)", text: $companions)
                TextField("메모", text: $note, axis: .vertical)
            }
            .navigationTitle("봉사 기록 입력")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        context.insert(MinistryLog(date: date, hours: hours, returnVisits: visits,
                                                   bibleStudies: studies, companionsText: companions, note: note))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MonthPlanView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MinistryDayPlan.date) private var allPlans: [MinistryDayPlan]
    @Query private var rates: [MinistryMonthRate]
    @State private var month = Calendar.current.startOfMonth(for: .now)
    @State private var editingDate: Date?

    private var key: String { MinistryDate.monthKey(month) }
    private var monthPlans: [MinistryDayPlan] {
        allPlans.filter { MinistryDate.monthKey($0.date) == key }.sorted { $0.date < $1.date }
    }
    private var monthRate: MinistryMonthRate? { rates.first { $0.monthKey == key } }
    private var days: [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: month),
              let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: month))
        else { return [] }
        return range.compactMap { Calendar.current.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("연도와 월", selection: $month, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                    HStack {
                        Text("시간당 재방문")
                        Spacer()
                        Text("\((monthRate?.visitsPerHour ?? 0).formatted())건")
                    }
                    HStack {
                        Text("시간당 성서 연구")
                        Spacer()
                        Text("\((monthRate?.studiesPerHour ?? 0).formatted())건")
                    }
                    NavigationLink("시간당 목표 설정") {
                        MonthRateEditorView(month: month)
                    }
                }
                Section("\(month.formatted(.dateTime.locale(MinistryDate.korean).year().month())) 일별 계획") {
                    ForEach(days, id: \.self) { day in
                        let plan = monthPlans.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
                        Button { editingDate = day } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(day.formatted(.dateTime.locale(MinistryDate.korean).day())) · \(MinistryDate.weekday(day))")
                                        .font(.headline)
                                    Text(plan?.activity.isEmpty == false ? plan!.activity : "계획 입력")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(plan?.hours.formatted() ?? "0")시간 · 재방문 \(plan?.returnVisits ?? 0) · 연구 \(plan?.bibleStudies ?? 0)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }.buttonStyle(.plain)
                    }
                }
                Section("월간 합계") {
                    LabeledContent("봉사 시간", value: "\(monthPlans.reduce(0) { $0 + $1.hours }.formatted())시간")
                    LabeledContent("재방문", value: "\(monthPlans.reduce(0) { $0 + $1.returnVisits })건")
                    LabeledContent("성서 연구", value: "\(monthPlans.reduce(0) { $0 + $1.bibleStudies })건")
                }
            }
            .navigationTitle("월 봉사 계획")
            .sheet(item: Binding(
                get: { editingDate.map(PlanSheetDate.init(date:)) },
                set: { editingDate = $0?.date }
            )) { selection in
                PlanEditorView(date: selection.date, rate: monthRate)
            }
        }
    }
}

private struct PlanSheetDate: Identifiable {
    let date: Date
    var id: Date { date }
    init(date: Date) { self.date = date }
}

struct PlanEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var plans: [MinistryDayPlan]
    let date: Date
    let rate: MinistryMonthRate?
    @State private var activity = ""
    @State private var note = ""
    @State private var hours = 0.0
    @State private var visits = 0
    @State private var studies = 0
    @State private var companions = ""

    private var existing: MinistryDayPlan? { plans.first { Calendar.current.isDate($0.date, inSameDayAs: date) } }

    var body: some View {
        NavigationStack {
            Form {
                Section(MinistryDate.koreanDate(date) + " · " + MinistryDate.weekday(date)) {
                    TextField("봉사 계획", text: $activity)
                    TextField("계획 시간", value: $hours, format: .number).keyboardType(.decimalPad)
                    Stepper("재방문 목표 \(visits)건", value: $visits, in: 0...999)
                    Stepper("성서 연구 목표 \(studies)건", value: $studies, in: 0...999)
                    TextField("봉사짝 (쉼표로 구분)", text: $companions)
                }
                Section("특별 일정 메모") { TextField("메모", text: $note, axis: .vertical) }
            }
            .navigationTitle("일별 봉사 계획")
            .onAppear {
                activity = existing?.activity ?? ""
                note = existing?.note ?? ""
                hours = existing?.hours ?? 0
                visits = existing?.returnVisits ?? 0
                studies = existing?.bibleStudies ?? 0
                companions = existing?.companionsText ?? ""
            }
            .onChange(of: hours) { _, value in
                visits = MinistryDate.count(value * (rate?.visitsPerHour ?? 0))
                studies = MinistryDate.count(value * (rate?.studiesPerHour ?? 0))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let plan = existing ?? MinistryDayPlan(date: date)
                        plan.activity = activity
                        plan.note = note
                        plan.hours = hours
                        plan.returnVisits = visits
                        plan.bibleStudies = studies
                        plan.companionsText = companions
                        if existing == nil { context.insert(plan) }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MonthRateEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var rates: [MinistryMonthRate]
    @Query private var plans: [MinistryDayPlan]
    let month: Date
    @State private var visits = 0.0
    @State private var studies = 0.0

    private var key: String { MinistryDate.monthKey(month) }
    private var existing: MinistryMonthRate? { rates.first { $0.monthKey == key } }

    var body: some View {
        Form {
            Section("시간당 자동 목표") {
                TextField("시간당 재방문 건수", value: $visits, format: .number).keyboardType(.decimalPad)
                TextField("시간당 성서 연구 건수", value: $studies, format: .number).keyboardType(.decimalPad)
                Text("날짜별 계획 시간에 기준을 곱해 목표 건수를 자동 계산합니다. 소수 결과는 반올림합니다.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("월간 시간당 기준")
        .onAppear { visits = existing?.visitsPerHour ?? 0; studies = existing?.studiesPerHour ?? 0 }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    let rate = existing ?? MinistryMonthRate(monthKey: key)
                    rate.visitsPerHour = visits
                    rate.studiesPerHour = studies
                    if existing == nil { context.insert(rate) }
                    for plan in plans where MinistryDate.monthKey(plan.date) == key {
                        plan.returnVisits = MinistryDate.count(plan.hours * visits)
                        plan.bibleStudies = MinistryDate.count(plan.hours * studies)
                    }
                    dismiss()
                }
            }
        }
    }
}

struct PeopleListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MinistryPerson.name) private var people: [MinistryPerson]
    @Query(sort: \MinistryPartner.name) private var partners: [MinistryPartner]
    @State private var showingPerson = false
    @State private var showingPartner = false

    var body: some View {
        NavigationStack {
            List {
                Section("재방문 · 성서 연구") {
                    ForEach(people) { person in
                        VStack(alignment: .leading) {
                            Text(person.name)
                            Text(person.kind).font(.caption).foregroundStyle(.secondary)
                            if !person.note.isEmpty { Text(person.note).font(.caption) }
                        }
                    }.onDelete { offsets in offsets.map { people[$0] }.forEach(context.delete) }
                }
                Section("봉사짝") {
                    ForEach(partners) { Text($0.name) }
                        .onDelete { offsets in offsets.map { partners[$0] }.forEach(context.delete) }
                }
            }
            .navigationTitle("사람 관리")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("대상자 추가", systemImage: "person.badge.plus") { showingPerson = true }
                        Button("봉사짝 추가", systemImage: "person.2.badge.plus") { showingPartner = true }
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingPerson) { PersonEditorView() }
            .sheet(isPresented: $showingPartner) { PartnerEditorView() }
        }
    }
}

struct PersonEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind = "재방문"
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("이름 또는 별칭", text: $name)
                Picker("구분", selection: $kind) {
                    Text("재방문").tag("재방문")
                    Text("성서 연구").tag("성서 연구")
                }
                TextField("개인 메모", text: $note, axis: .vertical)
            }
            .navigationTitle("대상자 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        context.insert(MinistryPerson(name: name, kind: kind, note: note))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct PartnerEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("이름 또는 별칭", text: $name)
                TextField("메모", text: $note, axis: .vertical)
            }
            .navigationTitle("봉사짝 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        context.insert(MinistryPartner(name: name, note: note))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("비공개 iCloud 저장") {
                    Label("CloudKit 비공개 데이터베이스 사용", systemImage: "lock.icloud")
                    Text("앱의 봉사 기록, 대상자, 메모는 로그인한 사용자의 iCloud 계정에 저장됩니다. 개인 iCloud 데이터베이스는 계정 소유자만 접근할 수 있습니다.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("설치") {
                    Text("Xcode에서 본인 Apple 계정으로 서명해 iPhone에 설치합니다. iCloud 동기화를 위해 동일한 Apple 계정과 iCloud Drive가 필요합니다.")
                    Text("실제 설치 전 Xcode Signing & Capabilities에서 본인의 Team을 선택하고 CloudKit 컨테이너를 연결해야 합니다.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("설정")
        }
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
