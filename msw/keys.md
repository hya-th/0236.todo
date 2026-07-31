# 키 설정을 인게임에 반영하기

설정 화면의 `1번 입력 / 2번 입력 / 확인`은 **리듬 커맨드 입력**(`BattleInput`)에 대응합니다.
지금 `BattleInput`은 화살표 키를 하드코딩하고 있어서, 설정에서 키를 바꿔도 조작에는 반영되지 않습니다.

바꿔야 할 곳은 **4군데**입니다.

```
설정에서 키 변경
  → SettingsLogic이 draft.keys.BeatLeft 등을 갱신 → "적용하기"로 저장
전투 중 키 입력
  → BattleInput이 _SettingsManager:GetKeyName("BeatLeft")와 비교 → 판정
```

---

## 1. SettingsManager — 액션 3개 추가 (3곳)

**세 곳을 모두 고쳐야 합니다.** 특히 `CloneSettings`를 빠뜨리면 새 액션이 복사 과정에서
사라져서 저장도 안 되고 값도 유지되지 않습니다.

### (1) `OnBeginPlay` — `actionNames`

```lua
self._T.actionNames = { "MoveLeft", "MoveRight", "Jump", "Attack", "Dash",
	"BeatLeft", "BeatRight", "BeatConfirm" }
```

### (2) `OnBeginPlay` — `defaults.keys`

```lua
self._T.defaults = {
	version = self.CURRENT_VERSION,
	volume = { bgm = 70, sfx = 80, voice = 60 },
	keys = {
		MoveLeft = "A", MoveRight = "D", Jump = "Space", Attack = "J", Dash = "K",
		BeatLeft = "LeftArrow", BeatRight = "RightArrow", BeatConfirm = "DownArrow",
	},
}
```

### (3) `CloneSettings` — 필드 3개 추가

```lua
return {
	version = self.CURRENT_VERSION,
	volume = { bgm = src.volume.bgm, sfx = src.volume.sfx, voice = src.volume.voice },
	keys = {
		MoveLeft = src.keys.MoveLeft, MoveRight = src.keys.MoveRight,
		Jump = src.keys.Jump, Attack = src.keys.Attack, Dash = src.keys.Dash,
		BeatLeft = src.keys.BeatLeft, BeatRight = src.keys.BeatRight,
		BeatConfirm = src.keys.BeatConfirm,
	},
}
```

`MergeWithDefaults`는 `actionNames`를 순회하므로 **고칠 필요가 없습니다.** 예전에 저장된
설정에 새 항목이 없어도 기본값으로 자동으로 채워집니다.

### (4) `GetKeyName` 메서드 추가

`SettingsManager_add.lua`에 있는 세 메서드(`GetVolume`, `GetVolume01`, `GetKeyName`)를
기존 `SettingsManager`에 붙여넣으세요.

---

## 2. BattleInput — 입력 핸들러 교체

파일 맨 아래 `HandleKeyDownEvent` 핸들러의 **본문 전체**를 아래로 바꿉니다.
(`handler` 선언 줄과 그 위 데코레이터는 그대로 두세요)

```lua
		-- 설정에서 지정한 키로 판정한다.
		--   BeatLeft = 키1(왼쪽), BeatRight = 키2(오른쪽), BeatConfirm = 키4(확인)
		--   키1과 키2를 simultaneousWindow 안에 같이 누르면 키3(동시)
		local keyName = _SettingsManager:KeyNameFromCode(event.key)
		if keyName == _SettingsManager:GetKeyName("BeatLeft") then
			self:PressKey(1)
		elseif keyName == _SettingsManager:GetKeyName("BeatRight") then
			self:PressKey(2)
		elseif keyName == _SettingsManager:GetKeyName("BeatConfirm") then
			self:ConfirmInput(4)
		end
```

`GetKeyName`은 **저장된 값이 아니라 draft**를 읽으므로, 설정 창에서 키를 바꾼 순간부터
바로 그 키로 조작됩니다. 저장 없이 닫으면 `RevertDraftToSaved`가 draft를 되돌려서
조작 키도 함께 복구됩니다(볼륨과 같은 규칙).

---

## 3. SettingsLogic — 액션 이름

파일의 기본값은 이미 바꿔 두었습니다.

```lua
property string action1 = "BeatLeft"     -- 1번 입력
property string action2 = "BeatRight"    -- 2번 입력
property string action3 = "BeatConfirm"  -- 확인
```

**에디터의 프로퍼티 패널에서도 이 세 값을 확인해 주세요.** 프로퍼티 값은 프로젝트에
저장되어 있어서, 예전에 `MoveLeft` 등으로 들어가 있으면 파일을 바꿔도 그 값이 계속 쓰입니다.

---

## 4. PlayerInputBridge — 수정 불필요

`ApplyActionKeys`가 `{ MoveLeft, MoveRight, Jump, Attack }`만 순회하고 대시는 `keys.Dash`를
읽으므로, 액션을 3개 추가해도 영향을 받지 않습니다. 캐릭터 조작 키를 설정 화면에서
바꾸고 싶어지면 그때 `SettingsLogic`에 행을 더 만들고 `action4~`를 늘리면 됩니다.

---

## 알아둘 점

**중복 키 검사는 8개 액션 전체를 대상으로 합니다.** `FindActionUsingKey`가 `actionNames`를
모두 훑기 때문에, 배틀 키에 `A`(= MoveLeft 기본값)를 넣으려 하면 "이미 사용 중인 키입니다"로
거절됩니다. 캐릭터 조작과 리듬 조작이 쓰이는 상황이 달라 굳이 막을 필요가 없다면,
`SettingsLogic`에서 `FindActionUsingKey` 대신 자기 세 행만 비교하도록 바꾸면 됩니다.

**할당 가능한 키**는 `SettingsManager`의 `keyNameByCode` 표에 있는 것뿐입니다.
알파벳·숫자·화살표·Space·Shift·Ctrl·Alt 등이며, `Escape` / `Return` / `Tab` / `F1~F12`는
`forbiddenKeyNames`로 막혀 있습니다. 표에 없는 키를 누르면 "이 키는 사용할 수 없습니다"가 뜹니다.

---

## 확인 순서

1. 설정에서 `1번 입력`을 `A`로 바꾸고 **적용하기** → 전투 진입 → `A`로 왼쪽 커맨드가 들어가는지.
2. 원래 `←`로는 더 이상 반응하지 않는지.
3. 게임을 껐다 켜도 `A`가 유지되는지(`_DataStorageService` 저장 확인).
4. 키를 바꾸고 **저장 없이 닫기** → 이전 키로 돌아오는지.
5. `되돌리기` → `←` `→` `↓`로 복구되는지.
6. 이미 쓰는 키를 넣으면 거절되는지.
