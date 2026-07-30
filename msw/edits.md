# 기존 스크립트 수정 — 메서드 전체 형태

손으로 한 줄만 바꾸다 보면 `end`가 어긋나기 쉬워서, **바뀐 메서드 전체**를 적어 둡니다.
각 메서드를 통째로 교체하세요. **메서드 선언 줄과 그 위의 데코레이터는 원본 그대로 두고**
본문만 바꾸는 것이 안전합니다(파일마다 ExecSpace가 다릅니다).

---

## 1. RhythmGameManager — `PlayBGM`

```lua
-- 볼륨은 설정(_SoundChannels)이 관리한다.
-- self.bgmVolume은 "이 BGM의 기본 크기"로 남고, 거기에 설정 비율이 곱해진다.
self.bgmHandle = {}
_SoundChannels:PlayBgm(self.bgmRUID, self.bgmVolume)
```

## 2. RhythmGameManager — `StopBGM`

```lua
self.bgmHandle = {}
_SoundChannels:StopBgm()
```

## 3. BeatTrigger — `OnHit`

```lua
if self.soundRUID ~= "" then
	_SoundChannels:PlaySfx(self.soundRUID, self.volume)
end
if self.flashObject ~= nil then
	self.flashObject.Enable = true
	self.flashTimeLeft = self.flashDuration
end
```

## 4. BattleInput — `PlayHitSound`

```lua
-- 성공 시 사운드 재생(RUID 있으면). 설정 볼륨이 곱해진다.
if self.hitSound == nil or self.hitSound == "" then return end
_SoundChannels:PlaySfx(self.hitSound, self.hitSoundVolume)
```

## 5. GachaResultPopup — `PlayRareSound`

```lua
if not isvalid(self.rareEffectSoundRefEntity) then return end
local sc = self.rareEffectSoundRefEntity.SoundComponent
if sc == nil then return end
local ruid = sc.AudioClipRUID
if ruid == nil or ruid == "" then return end
_SoundChannels:PlaySfx(ruid, self.rareEffectSoundVolume)
```

## 6. GachaResultPopup — `PlayCardAppearSound` (한 줄만)

```lua
cloneSc.Volume = _SoundChannels:ScaleSfx(self.cardAppearSoundVolume)
```

`cloneSc.Pitch = self.cardAppearSoundPitch` 줄은 그대로 둡니다.

## 7. GachaResultPopup — `PlayFlipSound` (한 줄만)

```lua
cloneSc.Volume = _SoundChannels:ScaleSfx(self.flipSoundVolume)
```

## 8. GameMapManager — `OnBeginPlay` (한 줄 추가)

```lua
-- 전투 맵 진입 시 최신 설정을 다시 불러온다(늦게 도착해도 SoundChannels가 반영).
_SettingsManager:LoadForCurrentPlayer()

if _UIManager ~= nil then
	_UIManager:ShowOnly(self.gameGroupName)
	log("[GameMapManager] Game 맵 진입 → " .. self.gameGroupName .. "UIGroup만 켜기")
else
	log("[GameMapManager] _UIManager 없음 — UIManager 임포트 확인")
end
```

---

## 문법 오류가 계속 날 때 위치 찾기

로그의 개수는 실행할 때마다 **누적**됩니다. 2 → 4 → 6이면 매 실행 2개라는 뜻이지
오류가 늘어나는 것이 아닙니다.

찾는 순서:

1. **`SoundChannels`를 통째로 삭제하고 실행.** 오류가 0이면 그 파일, 여전히 2개면 다른 곳입니다.
   (삭제해도 미리듣기와 볼륨 반영만 멈추고 게임은 돕니다)
2. 여전히 2개면 위 8곳을 고친 5개 파일을 **하나씩 원래대로 되돌리며** 실행합니다.
   되돌린 순간 오류가 사라지는 파일이 범인입니다.
3. 범인 파일을 찾으면 그 메서드를 위 내용으로 통째로 교체하세요.

편집기에서 해당 스크립트를 열면 문제 줄에 표시가 뜨는 경우가 많으니, 먼저 새로 건드린
스크립트들을 열어서 확인해 보는 것도 빠릅니다.
