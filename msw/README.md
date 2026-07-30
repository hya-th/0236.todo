# 설정 패널 (MSW) — 구현물과 연결 방법

양피지 스타일 좌측 설정 패널의 **기능 구현**입니다. 프로젝트의 기존 스크립트(`RhythmGameManager`,
`PlayerData`, `BattleInput`)와 같은 문법·관례에 맞춰 작성했습니다.

레이아웃 참조용 목업: `../mockup/settings-panel.html` (브라우저로 열면 1920×1080 기준으로 렌더됩니다)
기존 스크립트에 넣을 변경점: `integration.md`

## 파일

| 파일 | 종류 | 역할 |
|---|---|---|
| `SettingsManager.lua` | Logic | 저장/임시 상태, JSON 직렬화, 기본값 병합, 키 이름↔코드 변환, 중복 키 복구 |
| `SoundManager.lua` | Logic | BGM·효과음 2채널 볼륨, 0% 완전 무음, 미리듣기, 재생 중 볼륨 변경 |
| `SettingsPanel.lua` | Component | 패널 위젯 바인딩, 키 재설정 대기 상태, 되돌리기, 싱크 조절, 적용하기/닫기 |

**Logic 2개는 엔티티에 붙이지 않습니다.** 전역이라 `_SettingsManager`, `_SoundManager`로 접근합니다.
`RhythmGameManager`와 `BattleInput`이 드래그 연결 없이 설정값을 읽어야 하므로 Logic으로 두었습니다.

**`SettingsPanel`은 Component이므로 엔티티에 붙입니다.** 단 **패널 본체가 아니라 항상 켜져 있는 UI 루트**에
붙이고, `panelRoot` 슬롯에 그 자식(패널 본체)을 연결하세요. 컴포넌트가 붙은 엔티티가 꺼져 있으면
`OnBeginPlay`가 돌지 않아 버튼 연결이 되지 않습니다.

## UI 하이어라키와 슬롯 매핑

```
SettingsUIRoot                      ★ SettingsPanel 컴포넌트를 여기에 붙임 (항상 Enable)
└─ SettingsPanel                    ▶ panelRoot            (Entity)
   ├─ Parchment                     배경 스프라이트 (슬롯 없음)
   ├─ Title            "설정"
   ├─ SoundSection
   │  ├─ SectionLabel  "사운드"
   │  ├─ Row_Bgm
   │  │  ├─ Label      "BGM"
   │  │  ├─ Slider                  ▶ sliderBgm            (SliderComponent)
   │  │  └─ ValueBox / Text         ▶ valueBgm             (TextGUIRendererComponent)
   │  └─ Row_Sfx
   │     ├─ Label      "효과음"
   │     ├─ Slider                  ▶ sliderSfx            (SliderComponent)
   │     │                          ▶ sliderSfxTouch       (UITouchReceiveComponent) ※ 같은 엔티티
   │     └─ ValueBox / Text         ▶ valueSfx             (TextGUIRendererComponent)
   ├─ KeySection
   │  ├─ SectionLabel  "키 설정"
   │  ├─ Row_Input1
   │  │  ├─ Label      "1번 입력"
   │  │  ├─ WaitIcon                ▶ waitIcon1            (Entity)
   │  │  ├─ KeyBox / Text           ▶ keyText1             (TextGUIRendererComponent)
   │  │  └─ BtnChange  "변경"       ▶ btnChange1           (ButtonComponent)
   │  ├─ Row_Input2  (동일 구성)    ▶ waitIcon2 / keyText2 / btnChange2
   │  ├─ Row_Confirm (동일 구성)    ▶ waitIconConfirm / keyTextConfirm / btnChangeConfirm
   │  ├─ BtnRevert     "되돌리기"   ▶ btnRevertKeys        (ButtonComponent)
   │  └─ NoticeLabel                ▶ noticeLabel          (Entity)
   │     └─ Text                    ▶ noticeText           (TextGUIRendererComponent)
   ├─ SyncSection
   │  ├─ SectionLabel  "싱크 조절"
   │  └─ Row_Sync
   │     ├─ Label      "현재 싱크"
   │     ├─ ValueBox / Text         ▶ syncValueText        (TextGUIRendererComponent)
   │     └─ BtnAdjust  "조절하기"   ▶ btnSyncAdjust        (ButtonComponent)
   └─ Footer
      ├─ BtnApply      "적용하기"   ▶ btnApply             (ButtonComponent)
      └─ BtnClose      "닫기"       ▶ btnClose             (ButtonComponent)
```

`NoticeLabel`은 원본 화면에 없는 **추가 요소**입니다. 중복 키 거부·저장 완료·키 변경 안내를 보여줄 곳이
없으면 사용자가 왜 변경이 안 됐는지 알 수 없어 넣었습니다. 필요 없으면 빈 엔티티를 연결하면
텍스트만 갱신되고 화면에는 나타나지 않습니다.

### 반드시 챙겨야 하는 컴포넌트 설정

- **슬라이더 2개**: `SliderComponent`의 **Min = 0, Max = 100**. 기본값 0~1이면 50이 1로 잘려 항상 100처럼 보입니다.
- **효과음 슬라이더**: `UITouchReceiveComponent`를 추가해야 손을 놓는 순간 미리듣기가 됩니다.
- **값 박스·키 박스**: 배경 스프라이트 + 자식 텍스트. 슬롯에는 **텍스트 컴포넌트**를 넣습니다.
- **`SoundManager`의 `previewSfxRUID`**: 미리듣기용 샘플 사운드를 지정하세요. 비어 있으면 미리듣기를 건너뜁니다.

## 치수·색상 (1920×1080 기준)

| 요소 | 값 |
|---|---|
| 패널 | 좌측 정렬, 폭 795px, 높이 1080px, 패딩 상 44 / 좌 44 / 우 56 |
| 타이틀 "설정" | 46pt, 자간 2px |
| 섹션 라벨 | 32pt, 아래 2px 구분선, 섹션 간격 46px |
| 행 라벨 | 폭 150px, 우측 정렬, 26pt |
| 슬라이더 트랙 / 핸들 | 470×30 (라운드 15) / 22×22 마름모 |
| 값 박스 / 키 박스 | 104×46 / 152×46, 테두리 3px |
| 변경 버튼 / 되돌리기·조절하기 | 96×42 / 118×44 |
| 하단 버튼 | 258×88, 좌 44 · 하 56, 간격 24 |

| 용도 | HEX |
|---|---|
| 양피지 (위→아래) | `#F3E6C6` → `#E6D3AC`, 우측 테두리 `#C9AE7C` |
| 기본 텍스트 / 섹션 라벨 | `#4A3A22` / `#7A6540` |
| 슬라이더 트랙 | `#8A4038` → `#5E2C29`, 외곽선 `#4A211F` |
| 슬라이더 핸들 | `#F5CE4A`, 외곽선 `#8A6A14` |
| 값 박스 | 배경 `#F8F0DA`, 테두리 `#B49468` |
| 키 박스 / 입력 대기 | `#3E4654` / `#9AA0A8` |
| 파란 버튼 | `#46A0DC` → `#2F86C2`, 그림자 `#24698F` |
| 닫기 버튼 | `#BFAE7E` → `#A8976A`, 텍스트 `#4A3A22` |
| 안내 문구 | `#8A5A2A` |

## 구현된 동작

- **슬라이더**: 0~100 정수 스냅, 값 박스는 숫자만. 드래그 중 볼륨이 즉시 들리고, 효과음은 손을 놓을 때 샘플 1회 재생.
- **적용하기**: 임시 값을 확정해 JSON으로 저장. 변경이 없으면 "변경된 내용이 없습니다"만 안내.
- **닫기 / ESC**: 저장하지 않고 닫으면서 **볼륨 미리듣기까지 마지막 저장값으로 롤백**.
- **변경**: 해당 행이 "입력 대기"로 바뀌고 다음에 누른 키를 할당. 한 번에 한 행만 대기.
  이미 다른 액션이 쓰는 키는 "이미 사용 중인 키입니다"로 거부, ESC로 취소.
- **되돌리기**: 키 3개만 기본값(Left / Right / Space)으로. 볼륨·싱크는 유지하고 확정은 적용하기에서.
- **조절하기**: 임시 동작으로 클릭당 +10ms, +100ms를 넘으면 -100ms로 순환. 보정 화면이 생기면 교체하세요.
- **저장 형식**: `{"version":1,"volume":{"bgm":50,"sfx":50},"keys":{...},"syncOffsetMs":0}`.
  기본값에서 시작해 저장된 항목만 덮어쓰므로, 나중에 항목이 추가돼도 예전 저장값이 안전하게 병합됩니다.
  모르는 키 이름이나 중복 키가 들어 있으면 해당 항목만 기본값으로 복구합니다.
- **게임플레이 조회**: `_SettingsManager:GetKeyCode("Input1")`, `GetSyncOffsetMs()`,
  `GetBgmVolume01()`, `GetSfxVolume01()`.

## 확인 순서

1. 실행 후 로그에 `[SettingsPanel] OnBeginPlay wired`와 `[SettingsManager] 로드 완료: ...`가 찍히는지.
   앞의 것이 없으면 슬롯이 비어 있고, 뒤의 것이 없으면 Logic이 프로젝트에 안 올라간 상태입니다.
2. `KeyboardKey.XXX not found -- skipped` 로그가 있으면 그 키 이름만 `BuildKeyTables`에서 고치세요.
3. `SettingsPanel:Open()`으로 패널이 열리고 50/50, ←/→/Space로 채워지는지.
4. 슬라이더를 끝까지 끌어 값이 0~100으로 움직이는지(1로 잘리면 Slider Min/Max 문제).
5. 1번 입력에 2번 입력이 쓰는 키를 넣어보고 거부되는지.
6. 값을 바꾸고 닫기 → 다시 열면 이전 값으로 돌아와 있는지. 적용하기 → 로그에 `저장: {...}`이 찍히는지.
7. `integration.md`의 1번을 적용한 뒤, 게임을 다시 켜도 값이 유지되는지.

## 검증하지 못한 것

이 환경에서는 MSW를 실행할 수 없어 **문법·논리만 프로젝트 관례에 맞춰 작성했고 런타임 검증은 하지 못했습니다.**
특히 아래 세 가지는 Maker에서 한 번 확인해주세요.

- `KeyboardKey` 열거형 멤버 이름(`LeftArrow` 등) — 틀리면 해당 키만 건너뛰고 로그를 남기게 방어해 두었습니다.
- `_HttpService:JSONEncode` — `JSONDecode`는 기존 코드에서 확인됐고, Encode는 `pcall`로 감싸 실패 시 저장만 건너뜁니다.
- 재생 중 BGM 핸들의 볼륨 변경 — 불가하면 로그를 남기고 다음 재생부터 적용됩니다.
