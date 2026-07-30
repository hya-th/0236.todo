# 설정 패널 (MSW) — 구현물과 연결 방법

양피지 스타일 좌측 설정 패널의 **로직 구현**입니다. UI 레이아웃은 Maker의 UI 편집기에서 직접 만들어야 하므로,
아래에 하이어라키·슬롯 매핑·치수·색상을 그대로 따라 만들 수 있게 적어 두었습니다.

레이아웃 참조용 목업: `../mockup/settings-panel.html` (브라우저로 열면 1920×1080 기준으로 렌더됩니다)

## 파일

| 파일 | Type | 역할 |
|---|---|---|
| `SettingsChangedEvent.xml` | Event | 설정이 확정될 때 뿌리는 알림 (`bgm`, `sfx`, `syncOffsetMs`, `keysChanged`) |
| `SettingsManager.xml` | Logic | 저장/임시 상태, 직렬화·저장·로드, 키 이름↔코드 변환, 중복 키 검사, 기본값 병합 |
| `SoundManager.xml` | Logic | BGM·효과음 2채널 볼륨, 0% 완전 무음, 미리듣기, 효과음 재생 공통 함수 |
| `SettingsPanelLogic.xml` | Logic | 패널의 모든 위젯 바인딩, 키 재설정 대기 상태, 되돌리기, 싱크 조절, 적용하기/닫기 |

Logic·Event 타입이라 **엔티티에 붙이지 않습니다.** Maker에 임포트한 뒤 `SettingsPanelLogic`을 선택해
프로퍼티 슬롯에 UI 엔티티/컴포넌트를 지정하면 됩니다.

## UI 하이어라키와 슬롯 매핑

```
SettingsPanel                       ▶ panelRoot            (Entity)   ※ 시작 시 자동으로 Enable=false
├─ Parchment                        배경 (스프라이트만, 슬롯 없음)
├─ Title            "설정"
├─ SoundSection
│  ├─ SectionLabel  "사운드"
│  ├─ Row_Bgm
│  │  ├─ Label      "BGM"
│  │  ├─ Slider                     ▶ sliderBgm            (SliderComponent)
│  │  └─ ValueBox / Text            ▶ valueBgm             (TextGUIRendererComponent)
│  └─ Row_Sfx
│     ├─ Label      "효과음"
│     ├─ Slider                     ▶ sliderSfx            (SliderComponent)
│     │                             ▶ sliderSfxTouch       (UITouchReceiveComponent) ※ 같은 엔티티
│     └─ ValueBox / Text            ▶ valueSfx             (TextGUIRendererComponent)
├─ KeySection
│  ├─ SectionLabel  "키 설정"
│  ├─ Row_Input1
│  │  ├─ Label      "1번 입력"
│  │  ├─ WaitIcon                   ▶ waitIcon1            (Entity)
│  │  ├─ KeyBox / Text              ▶ keyText1             (TextGUIRendererComponent)
│  │  └─ BtnChange  "변경"          ▶ btnChange1           (ButtonComponent)
│  ├─ Row_Input2   (동일 구성)      ▶ waitIcon2 / keyText2 / btnChange2
│  ├─ Row_Confirm  (동일 구성)      ▶ waitIconConfirm / keyTextConfirm / btnChangeConfirm
│  ├─ BtnRevert     "되돌리기"      ▶ btnRevertKeys        (ButtonComponent)
│  └─ NoticeLabel                   ▶ noticeLabel          (Entity)
│     └─ Text                       ▶ noticeText           (TextGUIRendererComponent)
├─ SyncSection
│  ├─ SectionLabel  "싱크 조절"
│  └─ Row_Sync
│     ├─ Label      "현재 싱크"
│     ├─ ValueBox / Text            ▶ syncValueText        (TextGUIRendererComponent)
│     └─ BtnAdjust   "조절하기"     ▶ btnSyncAdjust        (ButtonComponent)
└─ Footer
   ├─ BtnApply       "적용하기"     ▶ btnApply             (ButtonComponent)
   └─ BtnClose       "닫기"         ▶ btnClose             (ButtonComponent)
```

`NoticeLabel`은 원본 화면에 없는 **추가 요소**입니다. 중복 키 거부, 저장 완료, 키 변경 안내를 알려줄 곳이
없으면 사용자가 왜 변경이 안 됐는지 알 수 없어 넣었습니다. 필요 없으면 빈 엔티티를 지정해두면
텍스트만 갱신되고 화면에는 아무것도 보이지 않습니다.

### 반드시 추가해야 하는 컴포넌트

- **효과음 슬라이더**: `SliderComponent` + `UITouchReceiveComponent` (손을 놓는 순간 미리듣기용)
- **슬라이더 3개 공통**: `SliderComponent`의 **Min = 0, Max = 100**. 기본값 0~1로 두면 50이 1로 잘려 항상 100처럼 보입니다.
- **값 박스·키 박스**: 배경 스프라이트 + 자식 `TextGUIRendererComponent`. 슬롯에는 **텍스트 컴포넌트**를 넣습니다.
- **WaitIcon**: 입력 대기 중임을 알리는 작은 파란 삼각형/커서. 스크립트가 Enable을 켜고 끕니다.

## 치수·색상 (1920×1080 기준)

| 요소 | 값 |
|---|---|
| 패널 | 좌측 정렬, 폭 795px, 높이 1080px, 내부 패딩 상 44 / 좌 44 / 우 56 |
| 타이틀 "설정" | 46pt, 자간 2px |
| 섹션 라벨 | 32pt, 아래 2px 구분선, 섹션 간격 46px |
| 행 라벨 | 폭 150px, 우측 정렬, 26pt |
| 슬라이더 트랙 | 470×30, 라운드 15, 내부 그림자 |
| 슬라이더 핸들 | 22×22 마름모(45° 회전) |
| 값 박스 | 104×46, 테두리 3px |
| 키 박스 | 152×46, 테두리 3px |
| 변경 버튼 | 96×42 / 되돌리기·조절하기 118×44 |
| 하단 버튼 | 258×88, 좌측 하단에서 좌 44 · 하 56, 간격 24 |

| 용도 | HEX |
|---|---|
| 양피지 (위→아래 그라데이션) | `#F3E6C6` → `#E6D3AC` |
| 양피지 우측 테두리 | `#C9AE7C` |
| 기본 텍스트 | `#4A3A22` |
| 섹션 라벨 | `#7A6540` |
| 슬라이더 트랙 | `#8A4038` → `#5E2C29`, 외곽선 `#4A211F` |
| 슬라이더 핸들 | `#F5CE4A`, 외곽선 `#8A6A14` |
| 값 박스 | 배경 `#F8F0DA`, 테두리 `#B49468` |
| 키 박스 | 배경 `#3E4654`, 테두리 `#2A303B`, 텍스트 흰색 |
| 키 박스(입력 대기) | 배경 `#9AA0A8`, 테두리 `#78808A` |
| 파란 버튼 | `#46A0DC` → `#2F86C2`, 아래 그림자 `#24698F` |
| 닫기 버튼 | `#BFAE7E` → `#A8976A`, 텍스트 `#4A3A22` |
| 안내 문구 | `#8A5A2A` |

## 동작 명세 (구현된 내용)

- **슬라이더**: 0~100 정수로 스냅, 값 박스는 숫자만 표시. 드래그 중 볼륨이 즉시 들리고, 효과음은 손을 놓을 때 샘플 1회 재생.
- **적용하기**: 임시 상태를 확정해 저장하고 `SettingsChangedEvent`를 발행. 변경이 없으면 "변경된 내용이 없습니다" 안내만.
- **닫기 / ESC**: 저장하지 않고 닫으면서 **볼륨 프리뷰까지 마지막 저장값으로 롤백**.
- **변경**: 해당 행이 "입력 대기"로 바뀌고 다음에 누른 키를 할당. 한 번에 한 행만 대기.
  - 이미 다른 액션이 쓰는 키 → "이미 사용 중인 키입니다" 후 취소
  - ESC → 취소, 인식 못 하는 키 → 안내만
- **되돌리기**: 키 3개만 기본값(Left / Right / Space)으로. 볼륨·싱크는 유지하고, 확정은 적용하기에서.
- **조절하기**: 임시 동작으로 클릭당 +10ms, 상한(+100ms) 초과 시 -100ms로 순환. 아래 TODO 참고.
- **저장 데이터**: `v=1;bgm=50;sfx=50;k1=Left;k2=Right;kc=Space;sync=0` 한 줄 형식.
  기본값에서 시작해 저장된 항목만 덮어쓰므로 나중에 항목이 추가돼도 예전 저장값이 안전하게 병합됩니다.
  저장값이 깨져 두 액션이 같은 키를 갖고 있으면 뒤쪽을 기본값으로 자동 복구합니다.
- **게임플레이 연동**: 하드코딩된 키 비교 대신 `_SettingsManager:GetKeyName("Input1")` 또는
  `GetKeyCode("Input1")`으로 조회하세요. 싱크는 `GetSyncOffsetMs()`입니다.

## 남은 TODO — 이 환경에서 MSW API를 검증할 수 없어 비워 둔 3곳

각각 **한 줄만 채우면** 되도록 한 메서드에 모아 두었습니다.

1. `SettingsManager.LoadRawText` / `SaveRawText` — PlayerData 접근 호출.
   현재는 메모리 폴백이라 **게임을 다시 켜면 값이 사라집니다.** 여기만 바꾸면 영속 저장이 됩니다.
2. `SoundManager.PushBgmVolume` — BGM 볼륨 반영 호출. 현재는 로그만 남깁니다.
3. `SoundManager.PlaySfx` — 효과음 재생 호출. 0% 무음 처리와 볼륨 계산은 이미 되어 있고 재생 한 줄만 남았습니다.

또한 `SettingsManager.BuildKeyTables`의 왼쪽 인자는 `KeyboardKey` 열거형 멤버 이름입니다.
이름이 다르면 해당 키만 조용히 건너뛰고 `KeyboardKey.XXX not found -- skipped` 로그를 남기니,
실행 후 로그를 보고 어긋난 이름만 고치면 됩니다.

`SettingsPanelLogic.OnSyncAdjustClick`은 원래 별도의 싱크 보정 화면(비트에 맞춰 입력)을 여는 버튼입니다.
그 화면이 없어 값 확인용 임시 동작을 넣어 두었으니, 보정 화면이 생기면 그 호출로 교체하세요.

## 연결 후 확인 순서

1. 실행 직후 로그에 `[SettingsPanelLogic] OnBeginPlay wired`가 찍히는지 → 안 찍히면 슬롯이 비어 있습니다.
2. `_SettingsPanelLogic:Open()`으로 패널이 열리고 값이 50/50, ←/→/Space로 채워지는지.
3. 슬라이더를 끝까지 끌었을 때 값 박스가 0~100 범위로 움직이는지(1로 잘리면 Slider Min/Max 문제).
4. 1번 입력에 이미 2번 입력이 쓰는 키를 넣어보고 거부되는지.
5. 값을 바꾸고 닫기 → 다시 열었을 때 이전 값으로 돌아와 있는지.
6. 값을 바꾸고 적용하기 → 로그에 `saved raw: v=1;...`이 찍히는지.

## 참고: 기존 스크립트와의 관계

- `pauseWhileOpen`이 true면 `_PauseManager:RequestPause("SettingsPanel")`로 정지를 겁니다.
  이 프로젝트의 `PauseManager`는 정지 이유를 참조 카운팅하므로 인게임 팝업과 이유 문자열이 달라도 안전합니다.
  `PauseManager`를 쓰지 않는다면 `pauseWhileOpen`을 false로 두세요.
- `PauseManager`가 호출하는 `PauseAllSfxAndVoice` / `ResumeAllSfxAndVoice`를 이름 그대로 유지했습니다.
  단 이 `SoundManager`는 전체가 ClientOnly이므로, `ExecSpace="All"`인 `PauseManager`에서 호출될 때는
  클라이언트 경로에서만 불려야 합니다.
