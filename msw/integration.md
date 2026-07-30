# 기존 스크립트에 넣어야 하는 변경점

설정 패널만 붙여도 화면은 동작하지만, **설정값이 실제 게임에 반영되려면** 아래 4곳을 손봐야 합니다.
각 항목은 붙여넣기 가능한 최소 변경만 담았습니다.

---

## 1. `PlayerData` — 설정 영속 저장 (필수)

`SettingsManager`는 `PlayerData:GetSettingsStr()` / `SaveSettingsStr(text)`를 호출합니다.
이 두 메서드가 없으면 `pcall`이 실패를 잡아 **메모리 폴백으로 동작**하므로 패널은 정상 작동하지만
게임을 다시 켜면 설정이 사라집니다.

`PlayerData` 스크립트에 아래를 추가하세요.

```lua
property string settingsStr = "" -- 설정 JSON. Sync로 두면 클라에서 바로 읽힌다

@ExecSpace("ClientOnly")
method string GetSettingsStr()
return self.settingsStr
end

@ExecSpace("ClientOnly")
method void SaveSettingsStr(string text)
self.settingsStr = text          -- 즉시 반영(같은 세션)
self:RequestSaveSettings(text)   -- 영속 저장 요청
end

@ExecSpace("Server")
method void RequestSaveSettings(string text)
self.settingsStr = text
-- TODO: battleSkillsStr / LoadBattleData가 쓰는 것과 같은 저장 방식으로 맞춰주세요.
--       (공유 메모리든 스토리지든 이 프로젝트가 이미 쓰는 경로 하나만 재사용)
end
```

`settingsStr`을 Sync 프로퍼티로 선언해두면 `battleStageId`처럼 서버에서 로드한 값이 클라이언트로 내려옵니다.
`LoadBattleData`가 하는 것과 같은 자리에서 `settingsStr`도 함께 채워주면 로그인 직후부터 설정이 적용됩니다.

---

## 2. `RhythmGameManager.PlayBGM` — BGM 볼륨을 설정에서 읽기 (필수)

지금은 `self.bgmVolume`(프로퍼티, 항상 1)을 씁니다. 설정의 BGM 슬라이더가 반영되도록 두 줄만 바꿉니다.

```lua
	self.bgmHandle = {}
	local ruid = self.bgmRUID
	local vol = _SettingsManager:GetBgmVolume01()   -- ← self.bgmVolume 대신
	local ok, handle = pcall(function()
		return _SoundService:PlaySound(ruid, vol)
	end)
	if ok then
		if handle ~= nil then self.bgmHandle = { h = handle } end
		_SoundManager:RegisterBgmHandle(handle)      -- ← 추가: 재생 중 볼륨 변경용
		log("[RhythmGameManager] BGM 재생 (" .. ruid .. ")")
```

`StopBGM`의 끝에도 한 줄 추가하면 핸들이 남지 않습니다.

```lua
	_SoundManager:ClearBgmHandle()
```

핸들에 볼륨 필드가 없어 재생 중 변경이 안 되는 경우에도, 다음 전투에서 `PlaySound`가 새 볼륨으로 시작하므로
설정은 유효합니다(그때는 `SoundManager`가 로그를 남깁니다).

---

## 3. `RhythmGameManager`의 ESC 충돌 (필수)

전투 중에 설정 패널을 열면 ESC가 **패널 닫기와 전투 종료 양쪽**에서 잡힙니다.
`HandleKeyDownEvent`에 한 줄을 넣어 패널이 열려 있을 때는 전투를 끝내지 않게 하세요.

```lua
handler HandleKeyDownEvent(KeyDownEvent event)
if _SettingsManager.panelOpen then return end   -- ← 추가
if event.key == KeyboardKey.Escape then
	self:ExitBattle()
end
end
```

`panelOpen`은 `SettingsPanel:Open()` / `Close()`가 관리합니다.

> 참고로 현재 `ExitBattle`은 첫 줄에서 `if not self.hasStarted then return end`로 빠지기 때문에,
> 승리·패배 후에는 ESC로 메인 화면에 돌아갈 수 없습니다. 이 설정 작업과는 별개의 건이라 손대지 않았습니다.

---

## 4. `BattleInput` — 키 설정과 싱크 오프셋 반영 (필수)

키 3개가 실제 조작에 먹히려면 입력 비교를 하드코딩에서 조회로 바꿔야 합니다.

```lua
-- 변경 전 (예시)
if event.key == KeyboardKey.LeftArrow then ... end

-- 변경 후
if event.key == _SettingsManager:GetKeyCode("Input1") then
	-- 1번 입력
elseif event.key == _SettingsManager:GetKeyCode("Input2") then
	-- 2번 입력
elseif event.key == _SettingsManager:GetKeyCode("Confirm") then
	-- 확인
end
```

싱크 오프셋은 판정 시각을 비교하는 지점에서 빼주면 됩니다. 양수는 "입력이 늦게 들어온다"는 뜻이라
그만큼 입력 시각을 앞으로 당겨 판정합니다.

```lua
local offset = _SettingsManager:GetSyncOffsetMs() / 1000
local judgeTime = inputTime - offset
```

`BeatRunner`가 비트 시각의 기준이라면 그쪽에서 한 번만 보정해도 됩니다. **두 곳에 동시에 적용하면
보정이 두 번 들어가니** 한 곳만 고르세요.

---

## 5. (선택) 효과음 볼륨 일원화

효과음 볼륨 슬라이더가 전투 사운드까지 덮으려면, 효과음 재생을 `_SoundManager:PlaySfx(ruid)`로 모으면 됩니다.
`_SoundService:PlaySound`를 직접 부르는 곳은 볼륨 설정을 우회합니다.

---

## 6. 설정 패널 열기 버튼

메인 화면이나 전투 HUD의 설정 버튼에서 아래처럼 호출합니다(`settingsEntity`는 `SettingsPanel`이 붙은 엔티티).

```lua
if isvalid(self.settingsEntity) and self.settingsEntity.SettingsPanel ~= nil then
	self.settingsEntity.SettingsPanel:Open()
end
```
