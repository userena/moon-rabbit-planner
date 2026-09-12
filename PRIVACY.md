# Privacy / 개인정보

일정, 월간 목표·메모, 담당자, 알람, 타이머, 플래너 이름·색상과 선택한 날씨 지역은
Mac은 UserDefaults, Windows는 앱 전용 로컬 JSON 파일, iPad는 앱 내부 WebKit 로컬 저장소에 저장됩니다. 메뉴 룰렛 후보·로고·배율·알림 중복 방지 기록도 이 기기에만 저장합니다. 서버 동기화·분석 SDK·광고 SDK·계정 가입이 없습니다.
이 저장소와 배포 ZIP에는 사용자가 작성한 일정 및 환경설정 파일을 포함하지 않습니다.
로컬 설정은 암호화된 비밀 저장소가 아니므로 민감한 비밀번호를 적지 마세요.

날씨를 조회할 때 선택 지역의 위도·경도가 Open-Meteo로 전송됩니다.
지역을 검색하면 검색어가 Photon으로, 결과가 없으면 Open-Meteo 지명 검색으로 전송됩니다.
각 제공자는 요청을 처리하면서 IP 주소를 볼 수 있습니다. 목표·일정·메모는 전송하지 않습니다.
시스템 GPS 위치 권한은 요구하지 않습니다. 앱 내 날씨는 사용자 요청으로 조회합니다.
제공자 정책은 THIRD-PARTY-NOTICES.md를 참고하세요.

Plans, goals, notes, owners, alarms, clocks, appearance and chosen weather place
are stored locally: UserDefaults on Mac, an app-specific JSON file on Windows, and WebKit local storage on iPad. Meal candidates, logo and zoom preferences also remain on the device. No account, analytics, advertising or cloud
sync is included. Weather lookup sends chosen coordinates to Open-Meteo; place
search sends the query to Photon, with an Open-Meteo fallback. Providers see
request IP addresses. Your planner content is not sent. System GPS permission
is not requested. Local preferences are not encrypted secret storage.

## Optional personal API connection

No publisher API key or shared account is included. Mac/iPad use device-only Keychain items; Windows uses Electron safeStorage encryption under the Windows account. Keys are excluded from planner records and never returned through the renderer API. The user selects OpenAI, Gemini, or Claude, saves their own key, enters a supported model ID, reviews a prompt, and explicitly confirms each billable request. Requests go only to fixed official HTTPS endpoints, without redirects or retries. No tool execution or automatic agent loops are implemented. Responses are displayed as text and not automatically persisted. Provider retention and billing terms apply. The normal planner and copy/open workflow work without this optional feature.
