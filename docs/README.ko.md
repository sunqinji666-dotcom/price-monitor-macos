# 가격 모니터

> 지정한 상점의 가격과 재고, WOYAO API 잔액과 최근 사용량을 macOS 메뉴 막대에서 확인하는 로컬 도구입니다.

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · **한국어**

![price-monitor-macos project visual](assets/price-monitor-macos-hero.png)

| 릴리스 | 플랫폼 | 아키텍처 | 라이선스 |
| --- | --- | --- | --- |
| v1.4 | macOS 14+ | Apple Silicon | MIT License |

[최신 릴리스 다운로드](../../releases/latest) · [빠른 시작](#빠른-시작) · [프로젝트에 Star](../../stargazers)

## 하는 일

가격 모니터는 자주 확인하는 두 종류의 정보를 하나의 로컬 앱에 모읍니다. 지정 상점의 상품 가격과 재고, 그리고 WOYAO API 잔액과 사용량입니다. macOS 로그인 시 실행할 수 있으며 메뉴 막대에는 현재 WOYAO 잔액만 표시합니다.

주문이나 결제를 대신하지 않습니다. 상품을 선택하면 기본 브라우저에서 해당 구매 페이지를 열기만 합니다.

## 주요 기능

- 비교 가능한 상품을 그룹으로 묶고 각 그룹을 낮은 가격순으로 정렬합니다.
- 상점을 매분 확인하고 새 재고가 나타나면 macOS 음성으로 알립니다.
- 현재 WOYAO 잔액을 메뉴 막대에 바로 표시합니다.
- WOYAO 사용량을 매시간 새로고침하고 잔액, 사용량, 오늘의 비용을 음성으로 안내합니다.
- 최근 10건의 호출에 대한 모델, 비용, 토큰, 시각을 표시합니다.
- 사용량 API의 숫자, 문자열, null 값 차이를 허용하며 호출 목록 오류가 잔액 표시를 막지 않도록 합니다.

## 빠른 시작

1. [Releases](../../releases/latest)에서 `PriceMonitor-v1.4-macOS-arm64.zip`을 내려받아 압축을 풀고 응용 프로그램 폴더로 옮깁니다.
2. 앱을 한 번 엽니다. 로그인 시 자동 실행하려면 `LaunchAgent.plist`의 사용자용 템플릿을 설치합니다.
3. **WOYAO 사용량**을 열고 API Key를 붙여 넣은 뒤 **문서에 저장하고 읽기**를 선택합니다.
4. Key는 `Documents/价格监控/woyao-api-key.txt`에만 저장됩니다. 상점 모니터링에는 로그인이 필요하지 않습니다.

## 동작 방식

공개 상점 API는 가격 비교, 새 재고 음성 알림, 상품 링크에 사용됩니다. WOYAO 사용량 API는 메뉴 막대 잔액, 매시간 음성 요약, 최근 호출 목록에 사용됩니다. 대표 이미지는 실제 계정이나 화면이 아닌 콘셉트 일러스트입니다.

## 개인정보와 범위

- 상점 정보는 공개 API에서 읽습니다.
- WOYAO API Key는 사용자가 직접 입력하며 현재 macOS 사용자만 읽을 수 있는 Documents 파일에만 저장됩니다.
- Key는 이 저장소, 일반 로그, 브라우저 데이터에 기록되지 않습니다.
- Release 자산에는 Key, 잔액, 사용 기록, Cookie, 충돌 보고서, 로그인 정보가 포함되지 않습니다.

Documents의 Key 파일은 평문입니다. 공개 클라우드에 동기화하거나 Git에 커밋하지 마세요.

## 빌드

macOS, Xcode Command Line Tools, Swift 6가 필요합니다.

```zsh
./build_app.sh
```

스크립트는 `价格监控.app`을 생성합니다. 로컬 빌드 결과물은 Git에서 제외되며 배포에는 Release 자산을 사용합니다.

## 라이선스

이 프로젝트는 [MIT License](../LICENSE)로 공개됩니다. 저작권 및 라이선스 고지를 유지하는 한 사용, 복제, 수정, 상업적 사용, 재배포가 자유롭습니다.

## 다운로드 및 검증

각 Release에는 arm64 macOS 압축 파일과 `.sha256` 파일이 포함됩니다. 다운로드한 파일은 다음과 같이 검증할 수 있습니다.

```zsh
shasum -a 256 PriceMonitor-v1.4-macOS-arm64.zip
```

결과를 같은 Release의 SHA-256 파일과 비교하세요.

## 알려진 제한

- Apple Silicon(arm64) 버전만 빌드 및 검증되었습니다.
- 앱은 로컬 ad-hoc 서명 상태이며 Apple 공증을 거치지 않았습니다. 처음 열 때 Finder에서 Control-클릭 후 “열기”가 필요할 수 있습니다.
