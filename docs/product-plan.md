# BarBop 제품 기획서

Date: 2026-07-15

Status: Current product definition

## 1. 제품 정의

BarBop은 메뉴바 클릭과 macOS에 실제로 표시된 알림 배너에 짧은 시각
효과를 재생하는 macOS 메뉴바 유틸리티다. 시스템 메뉴나 타사 팝오버를
변경하지 않으며, 입력을 가로채지 않는 임시 패널에 효과를 표시한다.

클릭 효과와 알림 효과는 독립적으로 켜고 끌 수 있다. 색상, Aurora 팔레트,
투명도, 지속 시간, 스타일은 두 효과가 공유한다.

## 2. 제품 원칙

- macOS와 타사 앱의 원래 메뉴 동작을 방해하지 않는다.
- 화면에 실제로 표시된 알림 배너에만 반응한다.
- 알림 제목, 본문, 앱 이름, 버튼 레이블을 읽거나 저장하지 않는다.
- 키보드 이벤트, 화면 이미지, 픽셀, OCR, 시스템 로그를 수집하지 않는다.
- 사용자 설정 외의 데이터를 영구 저장하지 않으며 네트워크를 사용하지 않는다.
- 공개 API만 사용하고 Reduce Motion 설정을 존중한다.
- 현재 알림 감지 방식은 Developer ID 직접 배포를 전제로 한다.

## 3. 사용자 흐름

### 최초 실행

1. BarBop이 메뉴바 유틸리티로 실행된다.
2. 메뉴바 아이콘에 붙은 설정 팝오버가 최초 한 번 자동으로 열린다.
3. 사용자는 Effects 탭에서 클릭 효과와 공용 시각 설정을 조정한다.
4. 알림 효과는 사용자가 Notifications 탭에서 명시적으로 켤 때만 권한
   안내를 시작한다.

### 클릭 효과

1. 사용자가 macOS 메뉴바를 클릭한다.
2. 원래 메뉴나 팝오버가 정상적으로 열린다.
3. 클릭이 발생한 디스플레이의 메뉴바에 선택한 효과가 재생된다.

### 알림 효과

1. 사용자가 Notification Effects를 켠다.
2. BarBop은 데이터 접근 범위를 먼저 설명하고 Accessibility 승인을 요청한다.
3. Notification Center가 화면에 배너를 표시하면 구조와 프레임만 관찰한다.
4. 사용자가 선택한 디스플레이 정책에 따라 메뉴바 효과를 재생한다.
5. Accessibility가 해제되면 observer를 중지하고 알림 효과를 자동으로 끈다.

## 4. 기능 범위

### 포함

- 메뉴바 클릭 감지와 클릭한 디스플레이 판정
- 표시된 알림 배너의 공개 Accessibility 구조 감지
- Click Effects와 Notification Effects 독립 토글
- Flash, Pulse, Sweep, Aurora 스타일
- 일반 효과의 단일 색상과 Aurora의 독립적인 3색 팔레트
- 투명도와 지속 시간 설정
- Reduce Motion 페이드 대체
- 알림 대상 화면 선택
- 설정 저장, 이전 스키마 마이그레이션, 손상 데이터 복구
- 로컬 테스트 알림과 권한 문제 해결 안내

### 제외

- macOS에 도착했지만 화면에 표시되지 않은 알림 감지
- 알림 내용이나 발신 앱 식별
- 시스템 메뉴 및 타사 팝오버 외형 변경
- 화면 캡처, OCR, Notification Center 데이터베이스 또는 비공개 API
- 사운드, 계정, 분석 SDK, 네트워크 기능
- Mac App Store 배포

## 5. 효과 설정

| 항목 | 기본값 | 동작 |
|---|---|---|
| Click Effects | 켜짐 | 메뉴바 클릭 효과를 제어한다. |
| Notification Effects | 꺼짐 | 표시 알림 배너 효과와 AX observer를 제어한다. |
| Style | Flash | Flash, Pulse, Sweep, Aurora 중 선택한다. |
| Color | System Blue | Aurora 외 스타일의 단일 색상이다. |
| Aurora Palette | 파랑·보라·청록 | 세 색을 그라디언트에 직접 사용한다. |
| Opacity | 0.35 | 0.05~1.0 범위다. |
| Duration | 0.28초 | 0.1~1.0초 범위다. |
| Notification Display | Follow Notification | 알림 효과의 화면 정책이다. |

색상 패널의 알파 편집은 사용하지 않으며 투명도는 Opacity에서만 조절한다.
설정은 `EffectSettings` 스키마 v3으로 저장한다. v1과 v2 데이터는 사용자
값을 보존하면서 새 필드를 기본값으로 보충한다.

## 6. 알림 디스플레이 정책

- `Follow Notification`: 배너가 감지된 화면, 찾지 못하면 현재 메인 화면
- `Main Display`: 현재 macOS 메인 화면
- 특정 모니터: 저장된 디스플레이 UUID가 일치하는 화면
- `All Displays`: 연결된 모든 화면에 동시에 재생

특정 모니터가 연결 해제되면 선택은 유지하고 메인 화면을 임시로 사용한다.
같은 UUID의 모니터가 다시 연결되면 자동으로 원래 선택을 복구한다. 이
정책은 알림 효과에만 적용되며 클릭 효과는 항상 클릭한 화면을 따른다.

## 7. 인터페이스

설정은 별도 앱 창이 아닌 약 520×520 크기의 메뉴바 팝오버로 제공한다.

- Effects 탭: Click Effects, Style, Color/Aurora Colors, Opacity, Duration
- Notifications 탭: Notification Effects, 상태·권한 안내, Display
- Troubleshooting: 로컬 알림 상태와 테스트 알림 전송
- 고정 하단: 자동 저장 안내와 Quit BarBop

정상적인 클릭 모니터 상태는 표시하지 않는다. 전역 마우스 모니터 설치가
실패했을 때만 Effects 탭에 오류 안내를 표시한다.

## 8. 아키텍처

| 컴포넌트 | 책임 |
|---|---|
| `AppDelegate` / `AppEnvironment` | 앱 수명주기, 상태 아이템, 팝오버, 서비스 연결 |
| `EffectSettingsStore` | 스키마 v3 저장, v1/v2 마이그레이션, 복구 |
| `MenuBarEventMonitor` | 전역·로컬 마우스 클릭 관찰 |
| `NotificationBannerDetector` | AX 연결, 구조 필터, 중복 제거, 재연결 |
| `NotificationEffectController` | 권한, 상태, 화면 라우팅, 효과 실행 |
| `NotificationDisplayResolver` | 알림 디스플레이 정책의 순수 해석 |
| `MenuBarEffectController` | 단일·다중 click-through 패널 재생 |
| `LocalTestNotificationController` | 로컬 알림 권한·표시 가능 여부와 테스트 전송 |
| `NotificationObserverSpike` | 개발 전용 AX 진단 및 신뢰성 검증 |

새 클릭이나 알림 이벤트가 들어오면 기존의 모든 효과 패널을 취소하고 가장
최근 이벤트를 재생한다. Spike와 BarBop은 동일한 detector core를 사용하지만
Spike 앱은 릴리스 ZIP에 포함하지 않는다.

## 9. 권한과 배포

클릭 효과는 Accessibility를 선제 요청하지 않는다. 알림 효과를 켤 때만
Accessibility 승인을 요청하며, 로컬 테스트 알림 권한과 명확히 구분한다.

검증한 App Sandbox 구성은 Accessibility 클라이언트로 등록되지 않아 BarBop은
Sandbox를 끄고 Hardened Runtime을 유지한다. 배포 순서는 다음과 같다.

1. `develop`에서 자동·수동 신뢰성 검증
2. `release`에서 버전 `0.1.0`과 빌드 `1` 확정
3. Developer ID Application 서명, 공증, stapling
4. 검증된 release 커밋을 `main`에 반영
5. 변경 불가능한 GitHub Release와 SHA-256 게시
6. 별도 `hsc03/homebrew-tap` 저장소의 개인 Cask 게시

공식 `Homebrew/homebrew-cask` 제출과 Mac App Store 배포는 현재 범위가 아니다.

## 10. 완료 기준

- Debug/Release 및 진단 타깃 빌드 성공
- 전체 단위 테스트 통과
- 세 디스플레이에서 클릭·알림 화면 정책 통과
- 표시 배너 20건 중 최소 19건 감지, 알림당 효과 한 번
- 유휴·Notification Center 조작 중 오탐 0건
- 표시되지 않은 알림에 효과 0회
- 최대 감지 지연 500ms 이하
- Developer ID 서명, 공증, stapling, Gatekeeper 검증 통과

세부 수동 항목과 결과는 `phase-5-quality-checklist.md`,
`phase-5-validation-report.md`, `notification-trigger-spike-report.md`를 기준으로
판정한다.
