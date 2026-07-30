@Logic
script SettingsManager extends Logic

-- ================================================================
-- 설정 값의 단일 보관소. 전역이므로 어디서든 _SettingsManager 로 접근한다.
--   saved = 확정/저장된 값 (게임플레이 코드는 이쪽을 읽는다)
--   draft = 설정 화면에서 만지는 중인 값 ("적용하기"로 saved에 확정)
-- 저장은 PlayerData 컴포넌트를 거친다(integration.md의 스니펫 필요).
-- ================================================================

property integer saveVersion = 1

property integer defaultBgm = 50 -- 기본 BGM 볼륨(0~100)
property integer defaultSfx = 50 -- 기본 효과음 볼륨(0~100)
property string defaultKeyInput1 = "Left" -- 1번 입력 기본 키
property string defaultKeyInput2 = "Right" -- 2번 입력 기본 키
property string defaultKeyConfirm = "Space" -- 확인 기본 키
property integer defaultSyncOffsetMs = 0 -- 기본 싱크 오프셋(ms)
property integer syncLimitMs = 200 -- 싱크 오프셋 허용 범위(±ms)

property table saved = {} -- 확정된 설정(런타임)
property table draft = {} -- 편집 중인 설정(런타임)
property boolean loaded = false -- 최초 로드 완료 여부

property boolean panelOpen = false -- 설정 패널이 열려 있는지(ESC 충돌 방지용)
property integer panelFlagTimerId = 0 -- panelOpen을 한 프레임 늦게 내리는 타이머

property string memoryFallback = "" -- PlayerData 저장 스니펫이 없을 때 임시 보관
property table keyCodeByName = {} -- "Left" → KeyboardKey.LeftArrow
property table keyNameByCode = {} -- KeyboardKey.LeftArrow → "Left"
property table displayByName = {} -- "Left" → "←" (화면 표시용)

@ExecSpace("ClientOnly")
method void OnBeginPlay()
-- 설정은 플레이어 개인 값이라 전체를 ClientOnly로 둔다.
self:BuildKeyTables()
self:Load()
end

@ExecSpace("ClientOnly")
method void SetPanelOpen(boolean value)
-- 설정 패널의 열림 상태를 알린다. RhythmGameManager의 ESC(전투 종료)가
-- 이 값을 보고 비켜준다(integration.md 3번).
if self.panelFlagTimerId ~= 0 then
	_TimerService:ClearTimer(self.panelFlagTimerId)
	self.panelFlagTimerId = 0
end

if value then
	self.panelOpen = true
	return
end

-- 내릴 때는 한 프레임 뒤에. ESC로 패널을 닫는 경우 같은 KeyDown 이벤트를
-- RhythmGameManager가 이어서 처리하면서 전투까지 끝내버리는 것을 막는다.
self.panelFlagTimerId = _TimerService:SetTimerRepeat(function()
	if self.panelFlagTimerId ~= 0 then
		_TimerService:ClearTimer(self.panelFlagTimerId)
		self.panelFlagTimerId = 0
	end
	self.panelOpen = false
end, 0.1)
end

@ExecSpace("ClientOnly")
method table MakeDefaults()
-- 기본 설정 한 벌을 새로 만든다.
local data = {}
data.version = self.saveVersion
data.volume = { bgm = self.defaultBgm, sfx = self.defaultSfx }
data.keys = {
	Input1 = self.defaultKeyInput1,
	Input2 = self.defaultKeyInput2,
	Confirm = self.defaultKeyConfirm,
}
data.syncOffsetMs = self.defaultSyncOffsetMs
return data
end

@ExecSpace("ClientOnly")
method table CopyData(table source)
-- 얕은 복사로는 volume/keys가 공유되므로 항목을 하나씩 옮긴다.
local data = {}
data.version = source.version
data.volume = { bgm = source.volume.bgm, sfx = source.volume.sfx }
data.keys = {
	Input1 = source.keys.Input1,
	Input2 = source.keys.Input2,
	Confirm = source.keys.Confirm,
}
data.syncOffsetMs = source.syncOffsetMs
return data
end

@ExecSpace("ClientOnly")
method void BuildKeyTables()
-- 키 이름 ↔ KeyboardKey 코드 ↔ 화면 표시 문자를 만들어 둔다.
self.keyCodeByName = {}
self.keyNameByCode = {}
self.displayByName = {}

self:RegisterKey("LeftArrow", "Left", "←")
self:RegisterKey("RightArrow", "Right", "→")
self:RegisterKey("UpArrow", "Up", "↑")
self:RegisterKey("DownArrow", "Down", "↓")
self:RegisterKey("Space", "Space", "Space")
self:RegisterKey("Enter", "Enter", "Enter")
self:RegisterKey("Escape", "Escape", "Esc")
self:RegisterKey("LeftShift", "Shift", "Shift")
self:RegisterKey("LeftControl", "Ctrl", "Ctrl")

for i = 0, 25 do
	local letter = string.char(65 + i)
	self:RegisterKey(letter, letter, letter)
end
for i = 0, 9 do
	local digit = tostring(i)
	self:RegisterKey("Alpha" .. digit, digit, digit)
end
end

@ExecSpace("ClientOnly")
method void RegisterKey(string enumMemberName, string keyName, string display)
-- KeyboardKey 열거형 멤버 이름이 다르면 그 키만 건너뛰고 로그를 남긴다.
-- (전체가 죽지 않게 하려는 것 — 로그에 not found가 보이면 그 이름만 고치면 된다)
local ok, code = pcall(function()
	return KeyboardKey[enumMemberName]
end)
if ok == false or code == nil then
	log("[SettingsManager] KeyboardKey." .. enumMemberName .. " not found -- skipped")
	return
end
self.keyCodeByName[keyName] = code
self.keyNameByCode[code] = keyName
self.displayByName[keyName] = display
end

@ExecSpace("ClientOnly")
method string KeyNameFromCode(any code)
-- KeyDownEvent.key → "Left" 같은 내부 키 이름. 모르는 키면 "".
local name = self.keyNameByCode[code]
if name == nil then return "" end
return name
end

@ExecSpace("ClientOnly")
method any KeyCodeFromName(string keyName)
return self.keyCodeByName[keyName]
end

@ExecSpace("ClientOnly")
method string DisplayOf(string keyName)
-- 화면에 보여줄 문자("Left" → "←").
local display = self.displayByName[keyName]
if display == nil then return keyName end
return display
end

@ExecSpace("ClientOnly")
method boolean IsKnownKeyName(string keyName)
return self.keyCodeByName[keyName] ~= nil
end

@ExecSpace("ClientOnly")
method boolean IsForbiddenKey(string keyName)
-- Escape는 키 변경 취소 전용이라 할당 불가.
return keyName == "" or keyName == "Escape"
end

@ExecSpace("ClientOnly")
method integer ClampVolume(any value)
local v = math.floor((tonumber(value) or 0) + 0.5)
if v < 0 then v = 0 end
if v > 100 then v = 100 end
return v
end

@ExecSpace("ClientOnly")
method integer ClampSync(any value)
local v = math.floor((tonumber(value) or 0) + 0.5)
if v < -self.syncLimitMs then v = -self.syncLimitMs end
if v > self.syncLimitMs then v = self.syncLimitMs end
return v
end

@ExecSpace("ClientOnly")
method string Encode(table data)
-- JSON으로 직렬화(프로젝트가 이미 _HttpService를 쓰고 있어 같은 방식).
local ok, text = pcall(function()
	return _HttpService:JSONEncode(data)
end)
if ok == false or text == nil then
	log("[SettingsManager] JSONEncode 실패 — 저장 생략")
	return ""
end
return text
end

@ExecSpace("ClientOnly")
method table Decode(string text)
-- 기본값에서 시작해 저장된 항목만 덮어쓴다.
-- 항목이 나중에 추가돼도 예전 저장값에서 누락된 것은 기본값으로 채워진다.
local data = self:MakeDefaults()
if text == nil or text == "" then return data end

local ok, decoded = pcall(function()
	return _HttpService:JSONDecode(text)
end)
if ok == false or type(decoded) ~= "table" then
	log("[SettingsManager] 저장값 파싱 실패 — 기본값 사용")
	return data
end

if type(decoded.volume) == "table" then
	if decoded.volume.bgm ~= nil then data.volume.bgm = self:ClampVolume(decoded.volume.bgm) end
	if decoded.volume.sfx ~= nil then data.volume.sfx = self:ClampVolume(decoded.volume.sfx) end
end
if type(decoded.keys) == "table" then
	data.keys.Input1 = self:SanitizeKeyName(decoded.keys.Input1, data.keys.Input1)
	data.keys.Input2 = self:SanitizeKeyName(decoded.keys.Input2, data.keys.Input2)
	data.keys.Confirm = self:SanitizeKeyName(decoded.keys.Confirm, data.keys.Confirm)
end
if decoded.syncOffsetMs ~= nil then
	data.syncOffsetMs = self:ClampSync(decoded.syncOffsetMs)
end

self:RepairDuplicateKeys(data)
return data
end

@ExecSpace("ClientOnly")
method string SanitizeKeyName(any value, string fallback)
-- 모르는 키 이름이 저장돼 있으면 기본값으로 되돌린다.
if type(value) ~= "string" then return fallback end
if self:IsKnownKeyName(value) == false then return fallback end
return value
end

@ExecSpace("ClientOnly")
method void RepairDuplicateKeys(table data)
-- 저장값이 손상돼 두 액션이 같은 키를 갖고 있으면 뒤쪽을 기본값으로.
local defaults = self:MakeDefaults()
local order = { "Input1", "Input2", "Confirm" }
local seen = {}
for _, action in ipairs(order) do
	local keyName = data.keys[action]
	if seen[keyName] then
		log("[SettingsManager] 중복 키 '" .. tostring(keyName) .. "' (" .. action .. ") — 기본값으로 복구")
		data.keys[action] = defaults.keys[action]
	end
	seen[data.keys[action]] = true
end
end

@ExecSpace("ClientOnly")
method string LoadRawText()
-- PlayerData 컴포넌트에서 설정 문자열을 읽는다.
-- integration.md의 스니펫을 PlayerData에 추가하지 않았으면 메모리 폴백을 쓴다
-- (이 경우 게임을 다시 켜면 값이 사라진다).
local lp = _UserService.LocalPlayer
if lp == nil or lp.PlayerData == nil then
	return self.memoryFallback
end

local ok, text = pcall(function()
	return lp.PlayerData:GetSettingsStr()
end)
if ok == false or text == nil then
	log("[SettingsManager] PlayerData:GetSettingsStr 없음 — 메모리 폴백 사용")
	return self.memoryFallback
end
return text
end

@ExecSpace("ClientOnly")
method void SaveRawText(string text)
if text == nil or text == "" then return end
self.memoryFallback = text

local lp = _UserService.LocalPlayer
if lp == nil or lp.PlayerData == nil then
	log("[SettingsManager] PlayerData 없음 — 메모리에만 보관")
	return
end

local ok = pcall(function()
	lp.PlayerData:SaveSettingsStr(text)
end)
if ok == false then
	log("[SettingsManager] PlayerData:SaveSettingsStr 없음 — 메모리에만 보관")
	return
end
log("[SettingsManager] 저장: " .. text)
end

@ExecSpace("ClientOnly")
method void Load()
-- 저장값을 읽어 saved/draft를 채우고 사운드에 즉시 반영한다.
self.saved = self:Decode(self:LoadRawText())
self.draft = self:CopyData(self.saved)
self.loaded = true
_SoundManager:ApplyVolumes(self.saved.volume.bgm, self.saved.volume.sfx)
log("[SettingsManager] 로드 완료: BGM=" .. tostring(self.saved.volume.bgm)
	.. " SFX=" .. tostring(self.saved.volume.sfx)
	.. " 키=" .. self.saved.keys.Input1 .. "/" .. self.saved.keys.Input2 .. "/" .. self.saved.keys.Confirm
	.. " 싱크=" .. tostring(self.saved.syncOffsetMs) .. "ms")
end

@ExecSpace("ClientOnly")
method void EnsureLoaded()
-- OnBeginPlay 순서에 따라 아직 로드 전일 수 있어, 조회 전에 한 번 확인한다.
if self.loaded == false then
	self:BuildKeyTables()
	self:Load()
end
end

@ExecSpace("ClientOnly")
method table GetDraft()
self:EnsureLoaded()
return self.draft
end

@ExecSpace("ClientOnly")
method table GetSaved()
self:EnsureLoaded()
return self.saved
end

@ExecSpace("ClientOnly")
method string GetKeyName(string action)
-- 게임플레이 코드용. 하드코딩된 키 비교 대신 이걸 쓴다.
self:EnsureLoaded()
local keyName = self.saved.keys[action]
if keyName == nil then return "" end
return keyName
end

@ExecSpace("ClientOnly")
method any GetKeyCode(string action)
-- BattleInput 등에서 event.key와 비교할 KeyboardKey 값.
return self.keyCodeByName[self:GetKeyName(action)]
end

@ExecSpace("ClientOnly")
method integer GetSyncOffsetMs()
-- 판정 타이밍 보정값(ms). 양수면 입력이 늦게 들어온다고 보고 그만큼 당겨준다.
self:EnsureLoaded()
return self.saved.syncOffsetMs
end

@ExecSpace("ClientOnly")
method number GetBgmVolume01()
-- RhythmGameManager의 PlayBGM에서 쓸 0.0~1.0 볼륨.
self:EnsureLoaded()
return self.saved.volume.bgm / 100
end

@ExecSpace("ClientOnly")
method number GetSfxVolume01()
self:EnsureLoaded()
return self.saved.volume.sfx / 100
end

@ExecSpace("ClientOnly")
method void SetDraftVolume(string channel, any value)
self:EnsureLoaded()
if channel == "bgm" then
	self.draft.volume.bgm = self:ClampVolume(value)
elseif channel == "sfx" then
	self.draft.volume.sfx = self:ClampVolume(value)
end
end

@ExecSpace("ClientOnly")
method void SetDraftKey(string action, string keyName)
self:EnsureLoaded()
if self.draft.keys[action] == nil then return end
self.draft.keys[action] = keyName
end

@ExecSpace("ClientOnly")
method void SetDraftSyncOffset(any ms)
self:EnsureLoaded()
self.draft.syncOffsetMs = self:ClampSync(ms)
end

@ExecSpace("ClientOnly")
method string FindDraftActionByKey(string keyName)
-- 이미 그 키를 쓰고 있는 액션 이름, 없으면 "".
self:EnsureLoaded()
local order = { "Input1", "Input2", "Confirm" }
for _, action in ipairs(order) do
	if self.draft.keys[action] == keyName then
		return action
	end
end
return ""
end

@ExecSpace("ClientOnly")
method void ResetDraftKeys()
-- "되돌리기"는 키 설정 섹션의 버튼이므로 키 3개만 기본값으로.
-- 볼륨·싱크는 그대로 두고, 확정은 "적용하기"에서 한다.
self:EnsureLoaded()
local defaults = self:MakeDefaults()
self.draft.keys.Input1 = defaults.keys.Input1
self.draft.keys.Input2 = defaults.keys.Input2
self.draft.keys.Confirm = defaults.keys.Confirm
end

@ExecSpace("ClientOnly")
method boolean IsDirty()
self:EnsureLoaded()
return self.saved.volume.bgm ~= self.draft.volume.bgm
	or self.saved.volume.sfx ~= self.draft.volume.sfx
	or self.saved.keys.Input1 ~= self.draft.keys.Input1
	or self.saved.keys.Input2 ~= self.draft.keys.Input2
	or self.saved.keys.Confirm ~= self.draft.keys.Confirm
	or self.saved.syncOffsetMs ~= self.draft.syncOffsetMs
end

@ExecSpace("ClientOnly")
method void ApplyDraft()
-- "적용하기": draft를 확정하고 저장한다.
self:EnsureLoaded()
self.saved = self:CopyData(self.draft)
self:SaveRawText(self:Encode(self.saved))
_SoundManager:ApplyVolumes(self.saved.volume.bgm, self.saved.volume.sfx)
end

@ExecSpace("ClientOnly")
method void DiscardDraft()
-- "닫기": 저장하지 않고 나가므로, 슬라이더로 미리 들려준 볼륨까지
-- 마지막 저장값으로 되돌린다.
self:EnsureLoaded()
self.draft = self:CopyData(self.saved)
_SoundManager:ApplyVolumes(self.saved.volume.bgm, self.saved.volume.sfx)
end

end
