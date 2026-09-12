# 무료 공개 검토 — 2026-09-12

## 결론

사용자는 원본 토끼를 다른 참고 이미지 없이 ChatGPT에 요청해 생성했다고 설명했습니다.
이 설명과 현재 서비스 약관을 기준으로, 광고·구독 없는 무료 앱과 소스를 공개하는 것은
가능한 방향입니다. 제3자 작품과의 우연한 유사성까지 조사한 법률 보증은 아닙니다.

- OpenAI와 사용자 사이에서는 법이 허용하는 범위에서 산출물 권리가 사용자에게 귀속됩니다.
  입력 자료의 권리를 확보해야 하며 산출물이 독창적이거나 비침해라고 보장되지는 않습니다.
  [OpenAI Terms](https://openai.com/policies/row-terms-of-use/)
- 코드에는 MIT, 그림에는 별도 무상 사용·수정·재배포 허락을 명시했습니다.
  순수 AI 요소의 독점 저작권을 주장하지 않습니다.
- 기존 플래너 참고 이미지·원본 포스터·외부 폰트 파일을 배포하지 않습니다.
- 날씨 데이터 출처와 비상업 API 조건을 명시했습니다. 유료·광고·상업 서비스로 바꾸면 재검토가 필요합니다.
  [Open-Meteo Terms](https://open-meteo.com/en/terms)
- 로컬 앱은 실행 시 AI 생성 API를 호출하지 않습니다. 사용자는 ChatGPT 구독이 필요 없습니다.
- GitHub 공개 저장소의 표준 Actions 실행은 무료입니다. 유료 서버·DB·도메인은 필요 없습니다.
  [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
- Apple Developer ID 서명·공증을 선택하면 개발자 멤버십은 연 US$99입니다.
  현재 앱은 ad-hoc 서명으로 다른 Mac에서 Gatekeeper 경고가 생길 수 있습니다.
  소스 빌드가 가능하며 전역 보안 설정을 끄도록 안내하지 않습니다.
  [Apple membership](https://developer.apple.com/support/compare-memberships/)

## 검증 범위와 한계

36개 테스트 중 35개 통과, 실시간 네트워크 테스트 1개는 선택 실행이라 제외했습니다.
테스트는 데이터 보존·타이머·일정·알람·이미지 투명도·이름·색상 변경 등을 포함합니다.

Codex Security 공식 검사는 시작 명령(workbench_db.py start-prompt-only-scan) 오류로
scanId를 반환하지 못했습니다. 공식 보안 스캔 완료나 취약점 없음으로 해석하면 안 됩니다.
이 문서는 배포 조건 정리이며 Codex Security 보안 보고서가 아닙니다.
