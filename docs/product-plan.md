# BarBop 제품 기획서

## 1. 문서 목적

이 문서는 BarBop의 제품 방향을 새로 정의하고, 이후 개발 작업의 기준을 제공한다. 이전 방향이었던 "메뉴바 앱 아이콘을 클릭했을 때 열리는 다른 앱의 메뉴 또는 팝오버를 꾸미는 앱"은 macOS 공개 API 제약상 안정적인 제품으로 구현하기 어렵다고 판단했다.

BarBop은 앞으로 다음 제품으로 개발한다.

> 메뉴바를 클릭하면 메뉴바 전체에 짧은 색상 클릭 효과를 보여주는 macOS 유틸리티

핵심은 다른 앱의 UI를 수정하는 것이 아니라, 메뉴바 영역 위에 입력을 통과시키는 짧은 시각 효과를 덧씌우는 것이다.

## 2. 제품 정의

BarBop은 사용자가 macOS 상단 메뉴바를 클릭할 때, 클릭한 디스플레이의 메뉴바 전체에 사용자가 설정한 색상 효과를 짧게 표시하는 앱이다.

BarBop은 다음을 하지 않는다.

- 기존 메뉴를 열거나 닫는 흐름을 변경하지 않는다.
- 시스템 메뉴, Control Center, Wi-Fi, 배터리, 시계 메뉴를 수정하지 않는다.
- 타사 메뉴바 앱의 메뉴 또는 팝오버를 꾸미지 않는다.
- 클릭 이벤트를 가로채 원래 앱에 전달하지 않는 방식으로 동작하지 않는다.
- 비공개 프레임워크, 코드 인젝션, SIMBL류 접근을 사용하지 않는다.

BarBop은 다음만 수행한다.

1. 전역 마우스 클릭을 관찰한다.
2. 클릭 좌표가 메뉴바 영역인지 판단한다.
3. 메뉴바 영역이면 해당 디스플레이의 메뉴바 프레임 위에 투명 오버레이를 표시한다.
4. 설정된 색상/투명도/지속시간/효과 스타일로 짧은 애니메이션을 재생한다.
5. 재생이 끝나면 오버레이를 즉시 숨긴다.

## 3. 제품 가치

BarBop의 가치는 기능적 생산성보다 작고 명확한 사용자 경험 개선에 있다.

- 메뉴바 클릭이 시각적으로 더 분명해진다.
- 화면 공유, 데모, 강의, UX 리뷰에서 메뉴바 조작을 보기 쉬워진다.
- macOS 메뉴바에 약한 촉각적 피드백을 추가하는 느낌을 준다.
- 사용자가 원하는 색상으로 개인화할 수 있다.

이 제품은 복잡한 생산성 도구가 아니라, 작고 안전한 UI 피드백 유틸리티다.

## 4. 핵심 원칙

- 원래 메뉴 동작을 방해하지 않는다.
- 오버레이는 모든 마우스 입력을 통과시킨다.
- 앱이 포커스를 훔치지 않는다.
- 메뉴바가 아닌 클릭에는 반응하지 않는다.
- 다중 모니터에서는 클릭이 발생한 디스플레이에만 효과를 표시한다.
- 모든 설정은 로컬에 저장한다.
- 네트워크, 계정, 분석 SDK를 사용하지 않는다.
- Reduce Motion 설정을 존중한다.
- 공개 API만 사용한다.
- 일반 사용자 배포는 Developer ID 서명과 Apple 공증을 기준으로 한다.
- Homebrew Cask 배포를 목표로 하되, 공식 저장소 승인 가능성을 보장하지 않는다.

## 5. 사용자 흐름

### 최초 실행

1. 앱이 메뉴바 유틸리티로 실행된다.
2. 설정 창이 열리고 BarBop의 동작을 설명한다.
3. 사용자는 효과 사용 여부, 색상, 투명도, 지속시간, 효과 스타일을 선택한다.
4. 전역 클릭 관찰에 권한이 필요한 경우, 권한이 필요한 이유와 처리 범위를 설명한다.
5. 권한이 없더라도 설정 창은 사용할 수 있어야 한다.

### 평상시 동작

1. 사용자가 메뉴바의 시스템 항목, 앱 메뉴, 또는 타사 상태 아이콘을 클릭한다.
2. macOS는 원래 메뉴 또는 팝오버를 정상적으로 연다.
3. BarBop은 같은 클릭을 관찰한다.
4. 클릭 위치가 메뉴바 영역이면 메뉴바 전체에 효과를 표시한다.
5. 효과는 짧게 표시되고 사라진다.

### 설정 변경

1. 사용자는 BarBop의 자체 메뉴바 아이콘에서 설정을 연다.
2. 색상, 투명도, 지속시간, 스타일을 변경한다.
3. 설정은 즉시 저장된다.
4. 다음 메뉴바 클릭부터 변경된 설정이 적용된다.

## 6. MVP 범위

MVP에 포함한다.

- 메뉴바 클릭 감지
- 메뉴바 외 클릭 무시
- 다중 모니터 메뉴바 영역 판정
- 클릭한 디스플레이의 메뉴바 전체에 효과 표시
- 입력을 통과시키는 비활성 투명 `NSPanel`
- 효과 켜기/끄기
- 색상 선택
- 투명도 설정
- 지속시간 설정
- 기본 효과 스타일 `Flash`
- 설정 저장 및 손상 데이터 복구
- Reduce Motion일 때 단순 페이드 효과
- 수동 검증 체크리스트

MVP에서 제외한다.

- 다른 앱 메뉴/팝오버 외형 변경
- 메뉴바 항목별 다른 효과
- 메뉴 내용 분석
- 화면 녹화 또는 픽셀 분석
- 사운드
- 로그인 시 자동 실행
- Homebrew 배포
- 앱 서명/공증 자동화

## 7. 효과 스타일

### Flash

메뉴바 전체가 설정 색상으로 빠르게 나타났다가 사라진다.

MVP의 기본 스타일이다.

### Pulse

메뉴바 전체가 설정 색상으로 나타난 뒤 한 번 더 약하게 맥동한다.

MVP 이후 추가한다.

### Sweep

클릭 위치 또는 메뉴바 왼쪽에서 시작해 색상 레이어가 수평으로 지나간다.

MVP 이후 추가한다.

### Aurora

설정 색상을 중심으로 여러 보조 색상을 만든 뒤, 메뉴바 전체에 부드러운 그라디언트가 짧게 흐르는 효과다.

특정 브랜드의 고유 시각 표현을 참조하지 않고 BarBop 고유의 추상적인 빛 효과로 구현한다.

MVP 이후 추가한다.

### Reduce Motion

시스템 Reduce Motion이 활성화되어 있으면 이동 애니메이션을 사용하지 않고 짧은 페이드만 사용한다.

## 8. 설정 항목

| 항목 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| 효과 사용 | Bool | true | 메뉴바 클릭 효과를 켜거나 끈다. |
| 색상 | CodableColor | systemAccentColor | 효과 색상 |
| 투명도 | Double | 0.35 | 0.05~1.0 범위 |
| 지속시간 | Double | 0.28 | 초 단위, 0.1~1.0 범위 |
| 스타일 | EffectStyle | flash | Flash, Pulse, Sweep, Aurora |

색상 저장은 `NSColor`를 직접 Codable로 저장하지 않고, 별도 `CodableColor` 값을 둔다.

## 9. 내부 아키텍처

### AppLifecycle

- 앱 시작과 종료를 관리한다.
- 자체 메뉴바 아이콘을 제공한다.
- 설정 창을 연다.
- 이벤트 모니터와 효과 컨트롤러를 연결한다.

### MenuBarEventMonitor

- 전역 마우스 클릭을 관찰한다.
- 이벤트를 변경하거나 차단하지 않는다.
- 클릭 위치만 앱 내부로 전달한다.

### MenuBarGeometry

- 클릭이 어느 화면에서 발생했는지 판단한다.
- 클릭 위치가 메뉴바 영역인지 계산한다.
- 메뉴바 자동 숨김 상황을 위한 fallback 높이를 제공한다.
- 순수 로직으로 유지해 단위 테스트 가능하게 한다.

### MenuBarEffectController

- 클릭한 화면의 메뉴바 프레임에 맞춘 `NSPanel`을 관리한다.
- 패널은 borderless, non-activating, transparent, click-through여야 한다.
- 효과 시작 전 기존 효과를 취소한다.
- 효과 종료 후 패널을 숨긴다.

### MenuBarEffectRenderer

- 실제 색상 효과를 그린다.
- Flash, Pulse, Sweep, Aurora 효과를 담당한다.
- Reduce Motion이면 단순 페이드만 수행한다.
- 효과 재생이 끝나면 completion을 호출한다.

### EffectSettingsStore

- `EffectSettings`를 UserDefaults에 Codable 데이터로 저장한다.
- 스키마 버전을 포함한다.
- 손상된 데이터나 알 수 없는 버전은 기본값으로 복구한다.

### SettingsView

- SwiftUI 설정 화면이다.
- 효과 사용 여부, 색상, 투명도, 지속시간, 스타일을 제공한다.
- 추후 권한 상태와 앱 정보도 포함한다.

## 10. 데이터 모델 초안

```swift
struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
}

struct EffectSettings: Codable, Equatable {
    enum Style: String, Codable, CaseIterable, Identifiable {
        case flash
        case pulse
        case sweep
        case aurora

        var id: String { rawValue }
    }

    var isEnabled: Bool
    var color: CodableColor
    var opacity: Double
    var duration: Double
    var style: Style
}
```

## 11. 현재 코드 재활용 계획

유지한다.

- `MenuBarEventMonitor`
- `MenuBarGeometry`
- `ContentView`의 설정 UI 기반
- 좌표 계산 테스트
- `OverlayWindowController`의 패널 생성 방식 일부
- `ReactionCoordinator`의 클릭 처리 흐름 일부

제거하거나 대체한다.

- `StatusItemResolver`
- `DetectedStatusItem`
- `Character`
- `CharacterAssignment`
- `CharacterStore`
- `CharacterRenderer`
- `AssignmentStore`
- `ReactionSettings`
- 프로그램별 캐릭터 매핑
- 최근 감지 항목 목록

새로 만든다.

- `CodableColor`
- `EffectSettings`
- `EffectSettingsStore`
- `MenuBarEffectController`
- `MenuBarEffectRenderer`
- `EffectCoordinator`

## 12. 개발 방식

현재 피벗 단계에서는 feature 브랜치를 만들지 않고 `develop`에서 직접 작업한다.

커밋 메시지는 기존 규칙을 유지한다.

- 기능 추가: `feat:`
- 수정: `fix:`
- 리팩터링: `refactor:`
- 배포 관련: `deploy:`
- 그 외: `chore:`

작업 단위는 작게 유지한다.

## 13. 개발 단계

### 단계 1: 피벗 정리

목표는 캐릭터/프로그램별 매핑 중심 구조를 제거하고, 메뉴바 클릭 효과 앱에 맞는 최소 구조로 바꾸는 것이다.

작업:

- 캐릭터 관련 모델 제거
- 상태 아이템 식별 로직 제거
- 최근 감지 항목 저장 제거
- 새 설정 모델 추가
- 기존 좌표 계산 테스트 유지

완료 조건:

- 빌드 성공
- 캐릭터/감지 항목 관련 UI가 남지 않음
- 메뉴바 클릭 감지 구조는 유지됨

### 단계 2: Flash 효과 MVP

작업:

- 메뉴바 전체 프레임에 색상 오버레이 표시
- 효과 지속시간 후 자동 숨김
- 기존 효과 재생 중 새 클릭이 들어오면 이전 효과 취소
- 메뉴바 외 클릭 무시

완료 조건:

- 메뉴바 클릭 시 색상 효과가 표시됨
- 원래 메뉴가 정상적으로 열림
- 오버레이가 입력을 가로채지 않음
- 다중 모니터에서 클릭한 화면에만 표시됨

### 단계 3: 설정 UI

작업:

- 효과 사용 토글
- 색상 선택
- 투명도 조절
- 지속시간 조절
- 스타일 선택
- 설정 저장 및 복구 테스트

완료 조건:

- 설정 변경이 즉시 반영됨
- 앱 재시작 후 설정 유지
- 손상된 저장 데이터는 기본값으로 복구됨

### 단계 4: 효과 스타일 확장

작업:

- Pulse 구현
- Sweep 구현
- Aurora 구현
- Reduce Motion 대응 정리

완료 조건:

- Flash, Pulse, Sweep, Aurora 모두 동작
- Reduce Motion에서는 이동 효과 없이 단순 페이드만 표시

### 단계 5: 품질 정리

작업:

- 수동 검증 문서 작성
- README 업데이트
- 개인정보/권한 설명 문서 작성
- Release 빌드 검증

완료 조건:

- 주요 수동 검증 통과
- 알려진 제한사항 문서화
- 배포 준비 브랜치로 이동 가능한 상태

### 단계 6: 서명, 공증, GitHub Release 준비

목표는 일반 사용자가 안전하게 다운로드할 수 있는 배포 산출물을 만드는 것이다.

작업:

- Release 빌드 스크립트 작성
- 앱 버전 및 빌드 번호 정리
- Developer ID 서명 절차 문서화
- Apple 공증 및 stapling 절차 문서화
- DMG 또는 zip 배포 형식 결정
- SHA-256 체크섬 생성
- GitHub Release 작성 절차 정리
- 인증 정보는 저장소에 기록하지 않고 환경 변수 또는 Keychain profile로만 사용

완료 조건:

- Release 빌드 생성 가능
- 서명/공증 확인 명령 문서화
- GitHub Release에 올릴 산출물과 체크섬을 생성할 수 있음
- 비밀 값이 Git에 포함되지 않음

### 단계 7: Homebrew Cask 준비

목표는 GitHub Release 산출물을 Homebrew Cask로 설치할 수 있게 만드는 것이다.

작업:

- 공식 Homebrew Cask 문서 기준 확인
- `barbop` Cask 파일 작성
- `version`, `sha256`, `url`, `name`, `desc`, `homepage`, `app`, `zap` 정의
- 지원 macOS 버전 조건 정리
- 로컬 설치/삭제 검증 절차 작성
- `brew audit --cask barbop` 검증
- `brew style --cask barbop` 검증
- 공식 `homebrew-cask` 제출용 PR 설명 초안 작성

완료 조건:

- GitHub Release URL과 SHA-256이 정확함
- Cask로 설치 및 제거 가능
- audit/style 검증을 통과하거나 남은 이슈가 문서화됨
- 공식 Homebrew 승인 가능성을 보장한다고 표현하지 않음

## 14. 수동 검증 기준

- 메뉴바 클릭 시 효과가 표시된다.
- 앱 메뉴, 시스템 상태 아이콘, 타사 상태 아이콘 클릭에서 원래 메뉴가 열린다.
- 메뉴바 외 클릭에는 효과가 표시되지 않는다.
- 오버레이가 클릭이나 키보드 포커스를 가로채지 않는다.
- 외부 모니터에서 클릭한 모니터에만 효과가 표시된다.
- 메뉴바 자동 숨김 환경에서 오동작하지 않는다.
- 빠른 연속 클릭에서 패널이 누적되지 않는다.
- Reduce Motion 설정을 켰을 때 효과가 단순화된다.

## 15. 개인정보 및 권한 정책

BarBop은 클릭 위치가 메뉴바 영역인지 판단하기 위해 전역 클릭을 관찰할 수 있다. 저장하는 데이터는 사용자 설정뿐이다.

저장하지 않는다.

- 클릭한 일반 화면 위치 기록
- 메뉴 내용
- 앱 사용 기록
- 키보드 입력
- 화면 이미지
- 원격 로그

네트워크 요청은 사용하지 않는다.

## 16. 릴리스 전략

1. `develop`에서 MVP 구현
2. 수동 검증과 Release 빌드 확인
3. `release` 브랜치에서 버전, 서명, 공증, 릴리스 문서 정리
4. GitHub Release에 서명/공증된 산출물 게시
5. Release URL과 SHA-256을 기준으로 Homebrew Cask 작성
6. 로컬 Cask 설치/삭제/audit/style 검증
7. 공식 `homebrew-cask` 제출 PR 준비
8. 최종 안정 릴리스를 `main`에 반영

Homebrew Cask는 앱의 신뢰를 대신 제공하지 않는다. 일반 사용자용 산출물은 Homebrew 배포 여부와 관계없이 서명과 공증을 기본으로 한다.

## 17. 최종 결정

BarBop은 기존의 캐릭터 반응 앱 또는 다른 앱 메뉴 꾸미기 앱 방향을 중단한다.

앞으로의 BarBop은 단순하고 안전한 메뉴바 클릭 효과 앱으로 개발한다.
