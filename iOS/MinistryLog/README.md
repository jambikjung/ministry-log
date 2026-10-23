# 개인용 iPhone 앱

이 앱은 SwiftData와 CloudKit의 **비공개 데이터베이스**를 사용합니다. 기록은 앱을 실행한 사람의 iCloud 계정에 귀속됩니다. 앱 코드는 현재 저장소에 보관되며, 개인 기록이나 연락처를 코드에 포함하지 않습니다.

## Xcode에서 본인 iPhone에 설치하기

1. Mac에 Xcode를 설치하고 `iOS/MinistryLog/MinistryLog.xcodeproj`를 엽니다.
2. Signing & Capabilities에서 본인의 Apple 계정을 Team으로 선택합니다.
3. iCloud capability의 CloudKit을 켜고 컨테이너 `iCloud.com.jambikjung.MinistryLog`를 본인 개발자 팀에 연결합니다. 컨테이너 ID를 바꾸면 `MinistryLogApp.swift`와 `MinistryLog.entitlements`의 값도 동일하게 바꿉니다.
4. Bundle Identifier가 본인 팀에서 쓸 수 있는 고유 값인지 확인합니다.
5. 본인 iPhone을 연결 대상으로 선택하고 Run을 누릅니다. iPhone과 다른 Apple 기기에서 같은 iCloud 계정으로 로그인해야 동기화됩니다.

CloudKit 개인 데이터베이스를 쓰므로 앱을 공개 배포하지 않아도 본인 기기에서 실행할 수 있습니다. 기기 간 자동 동기화는 iCloud 로그인과 네트워크 연결을 요구하며, 처음 동기화될 때까지 시간이 걸릴 수 있습니다.

## 현재 단계

Xcode 프로젝트와 비공개 CloudKit 저장소 설정을 담은 초기 네이티브 버전입니다. 이 실행 환경에는 Xcode가 없어 iOS 빌드와 실제 iCloud 동기화 검증은 진행하지 못했습니다. 또한 기존 웹앱의 JSON 백업을 네이티브 앱으로 가져오는 기능은 아직 포함하지 않았습니다. 기존 데이터를 옮길 때까지 웹앱의 백업 파일을 별도로 보관하세요.
