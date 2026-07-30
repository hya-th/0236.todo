# 설정 스크립트 (MSW)

기존 프로젝트 스택(`SettingsManager` / `SettingsBootstrap` / `PlayerInputBridge` /
`SettingsChangedEvent` / `PauseManager` / `StageController`)에 맞춰 작성한 파일들입니다.
Maker 코드 에디터에 그대로 붙여넣는 문법입니다.

레이아웃 참조용 목업: `../mockup/settings-panel.html`

## 파일

| 파일 | 종류 | 역할 |
|---|---|---|
| `SettingsManager.lua` | Logic | 기존 파일 + **볼륨 조회 2개 추가**(`GetVolume`, `GetVolume01`) |
| `SoundChannels.lua` | Logic | **신규.** 사운드 볼륨 게이트웨이. 모든 재생이 여기를 거쳐야 설정이 반영됨 |
| `SettingsLogic.lua` | Logic | 양피지 설정 패널 UI 바인딩 (탭/음성 없음, 키 박스+변경 버튼 분리 구조) |
| `InGameSettingLogic.lua` | Logic | 인게임 일시정지 팝업 (빈 슬롯 허용, 음성 채널 선택) |
| `ConfirmDialogController.lua` | Logic | 확인 다이얼로그 (확인창 미제작 시 바로 실행) |

## 볼륨이 실제로 반영되는 경로

```
슬라이더 조작
  → SettingsLogic:OnBgmChanged / OnSfxChanged
      → _SettingsManager:SetDraftVolume(channel, v)   -- draft 갱신 + "volume" 이벤트
          → _SoundChannels:OnSettingsChanged           -- 재생 중인 BGM에 즉시 반영
"적용하기"
  → _SettingsManager:Apply() → 서버 저장(_DataStorageService) → "applied"

로그인 / 맵 진입
  → SettingsBootstrap:LoadForCurrentPlayer() → 서버 로드 → "loaded"
      → draft/saved 갱신 → _SoundChannels가 다시 반영

재생 시점
  → _SoundChannels:PlaySfx(ruid, 기본볼륨)  =  PlaySound(ruid, 기본볼륨 × sfx/100)
  → _SoundChannels:PlayBgm(ruid, 기본볼륨)  =  PlaySound(ruid, 기본볼륨 × bgm/100)
```

볼륨은 `saved`가 아니라 **`draft`를 읽습니다.** 슬라이더를 움직이는 즉시 소리가 바뀌고,
저장하지 않고 닫으면 `RevertDraftToSaved`가 draft를 되돌리므로 소리도 함께 복구됩니다.
`PlayerInputBridge`가 키를 draft로 읽는 것과 같은 규칙입니다.

## 기존 스크립트에서 바꿔야 하는 곳

`_SoundService:PlaySound`를 직접 호출하는 자리를 전부 `_SoundChannels`로 바꿔야 설정이 먹습니다.

| 스크립트 | 위치 | 변경 |
|---|---|---|
| `RhythmGameManager` | `PlayBGM` | `_SoundService:PlaySound(ruid, self.bgmVolume)` → `_SoundChannels:PlayBgm(ruid, self.bgmVolume)` |
| `RhythmGameManager` | `StopBGM` | `_SoundChannels:StopBgm()` |
| `BeatTrigger` | `OnHit` | `_SoundService:PlaySound(self.soundRUID, self.volume)` → `_SoundChannels:PlaySfx(...)` |
| `BattleInput` | `PlayHitSound` | `_SoundService:PlaySound(self.hitSound, self.hitSoundVolume)` → `_SoundChannels:PlaySfx(...)` |
| `GachaResultPopup` | `PlayRareSound` | `_SoundService:PlaySound(ruid, self.rareEffectSoundVolume)` → `_SoundChannels:PlaySfx(...)` |
| `GachaResultPopup` | `PlayCardAppearSound` | `cloneSc.Volume = self.cardAppearSoundVolume` → `_SoundChannels:ScaleSfx(self.cardAppearSoundVolume)` |
| `GachaResultPopup` | `PlayFlipSound` | `cloneSc.Volume = self.flipSoundVolume` → `_SoundChannels:ScaleSfx(self.flipSoundVolume)` |
| `GameMapManager` | `OnBeginPlay` | `_SettingsManager:LoadForCurrentPlayer()` 한 줄 추가(전투 맵 진입 시 최신값 보장) |

각 스크립트의 볼륨 프로퍼티(`bgmVolume`, `hitSoundVolume` 등)는 지우지 말고 **그 소리의 기본 크기**로
남겨 두세요. 설정 볼륨은 거기에 곱해집니다.

## 슬롯 연결

`SettingsLogic` — `settingsGroup` / `sliderBgm`·`valueBgm` / `sliderSfx`·`valueSfx`·`sliderSfxTouch` /
`keyText1~3`·`btnChange1~3`·`waitIcon1~3`(선택) / `btnRevertKeys` /
`syncValueText`·`btnSyncAdjust` / `btnApply`·`btnClose` / `noticeLabel`·`noticeText`(선택) /
`openBtn`(로비 설정 버튼) / `hideWhileOpen`(선택).

`action1~3`은 화면 세 행이 대응할 액션 이름입니다. 기본값은 `MoveLeft` / `MoveRight` / `Jump`.

`SoundChannels` — `previewSfxRUID`, `previewVoiceRUID`에 미리듣기 샘플 사운드를 지정하세요.

## 치수·색상 (1920×1080 기준)

| 요소 | 값 |
|---|---|
| 패널 | 좌측 정렬, 폭 795px, 패딩 상 44 / 좌 44 / 우 56 |
| 타이틀 46pt / 섹션 라벨 32pt / 행 라벨 폭 150px 우측 정렬 26pt |
| 슬라이더 트랙 470×30(라운드 15), 핸들 22×22 마름모 |
| 값 박스 104×46, 키 박스 152×46 |
| 변경 버튼 96×42, 되돌리기·조절하기 118×44, 하단 버튼 258×88 |

| 용도 | HEX |
|---|---|
| 양피지 | `#F3E6C6` → `#E6D3AC`, 테두리 `#C9AE7C` |
| 텍스트 / 섹션 라벨 | `#4A3A22` / `#7A6540` |
| 슬라이더 트랙 / 핸들 | `#8A4038`→`#5E2C29` / `#F5CE4A` |
| 값 박스 / 키 박스 / 입력 대기 | `#F8F0DA` / `#3E4654` / `#9AA0A8` |
| 파란 버튼 / 닫기 버튼 | `#46A0DC`→`#2F86C2` / `#BFAE7E` |

## 확인 순서

1. 설정에서 BGM을 0으로 내리고 적용 → 로비 BGM이 무음인지.
2. 전투 진입 → 전투 BGM도 무음인지(전투 맵에서 새로 재생되는 경로).
3. 효과음을 0으로 → 비트 쿵 소리, 커맨드 성공음, 가챠 사운드가 모두 멈추는지.
4. 게임을 껐다 켜서 값이 유지되는지(`_DataStorageService` 저장 확인).
5. 슬라이더를 움직이는 동안 실시간으로 변하고, 저장 없이 닫으면 원래 볼륨으로 돌아오는지.

## 검증하지 못한 것

MSW를 실행할 수 없어 문법과 논리만 맞췄습니다. 특히 **재생 중 BGM 핸들의 볼륨 변경**
(`handle.Volume`)은 지원 여부가 불확실해 `pcall`로 감쌌고, 실패하면 로그를 남기고
다음 재생부터 적용됩니다. 즉시 반영이 안 되면 BGM을 한 번 껐다 켜는 방식으로 바꾸면 됩니다.
