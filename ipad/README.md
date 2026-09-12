# iPad 앱

기존 토끼 그림과 공통 웹 플래너를 로컬 WKWebView에서 실행하는 iPad용 SwiftUI 앱입니다. iPadOS 16 이상, 세로·가로 방향과 Split View를 지원합니다. 데이터는 해당 기기의 앱 저장소에 저장합니다. 앱 삭제 시 기록도 함께 지워질 수 있습니다.

```sh
python3 scripts/prepare-web-assets.py
open ipad/MoonRabbitPlanner.xcodeproj
```

Xcode에서 `MoonRabbitPlanner` 스킴과 iPad 시뮬레이터를 선택해 실행합니다. 실물 iPad 설치 시 개발 팀과 서명을 설정해야 합니다. 이 프로젝트와 시뮬레이터 `.app`은 App Store/TestFlight 배포용 IPA가 아닙니다.

```sh
xcodebuild test -project ipad/MoonRabbitPlanner.xcodeproj -scheme MoonRabbitPlanner \
  -destination 'platform=iOS Simulator,name=iPad (A16)' CODE_SIGNING_ALLOWED=NO
```

기기 이름은 `xcrun simctl list devices available` 결과에 맞춰 바꿉니다. UI 테스트는 실제 WKWebView 로딩과 세로·가로 화면을 검사하고 스크린샷을 저장합니다. GitHub Actions에도 같은 검증이 구성되어 있습니다.

iPadOS는 다른 앱 위에서 자유롭게 돌아다니는 데스크톱 펫 창을 제공하지 않으므로 토끼는 플래너 안에서 움직입니다. 앱을 닫은 상태의 알람과 백그라운드 동작은 지원하지 않습니다. 인터넷은 사용자가 날씨를 조회할 때만 필요합니다.
