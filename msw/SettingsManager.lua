@Logic
script SettingsManager extends Logic

-- ================================================================
-- 기존 SettingsManager + 이번 작업분. 원본과 달라진 곳은 네 군데뿐이다.
--   (1) OnBeginPlay  : actionNames에 BeatLeft / BeatRight / BeatConfirm 추가
--   (2) OnBeginPlay  : defaults.keys에 위 3개의 기본 키 추가
--   (3) CloneSettings: keys에 위 3개 필드 추가 (여기 빠뜨리면 값이 사라진다)
--   (4) GetSaved 아래: GetVolume / GetVolume01 / GetKeyName 3개 추가
-- 저장 경로(_DataStorageService)와 나머지 로직은 원본 그대로다.
-- ================================================================

property integer CURRENT_VERSION = 1
property boolean isLoaded = false

method void OnBeginPlay()
-- No @ExecSpace on purpose: this static data must exist on BOTH the
-- server instance (RequestLoad/RequestSave) and every client instance
-- (UI, PlayerInputBridge) -- ClientOnly here would leave the server's
-- self._T nil and crash the first RequestLoad with AttemptToIndex.
-- (Using OnBeginPlay rather than OnInitialize: empirically, OnInitialize
-- did not run on the server-side Logic instance in this project.)
-- Action names this build understands; add an entry here (and to
-- DEFAULTS.keys AND CloneSettings) to introduce a new rebindable action --
-- MergeWithDefaults() automatically backfills old saves.
-- Beat* 3개는 리듬 커맨드 입력(BattleInput)용이다.
self._T.actionNames = { "MoveLeft", "MoveRight", "Jump", "Attack", "Dash",
	"BeatLeft", "BeatRight", "BeatConfirm" }

-- Keys not eligible for assignment: Escape is wait-cancel-only, the
-- rest are common UI/system shortcuts (chat submit, focus cycling,
-- function-key row). Not an MSW-mandated list -- MSW does not publish
-- one -- just a conservative default; adjust to taste.
self._T.forbiddenKeyNames = {
	Escape = true, Return = true, Tab = true,
	F1 = true, F2 = true, F3 = true, F4 = true, F5 = true, F6 = true,
	F7 = true, F8 = true, F9 = true, F10 = true, F11 = true, F12 = true,
}

self._T.keyNameByCode = {
	[97] = "A", [98] = "B", [99] = "C", [100] = "D", [101] = "E", [102] = "F", [103] = "G",
	[104] = "H", [105] = "I", [106] = "J", [107] = "K", [108] = "L", [109] = "M", [110] = "N",
	[111] = "O", [112] = "P", [113] = "Q", [114] = "R", [115] = "S", [116] = "T", [117] = "U",
	[118] = "V", [119] = "W", [120] = "X", [121] = "Y", [122] = "Z",
	[48] = "Alpha0", [49] = "Alpha1", [50] = "Alpha2", [51] = "Alpha3", [52] = "Alpha4",
	[53] = "Alpha5", [54] = "Alpha6", [55] = "Alpha7", [56] = "Alpha8", [57] = "Alpha9",
	[32] = "Space", [27] = "Escape", [13] = "Return", [9] = "Tab",
	[273] = "UpArrow", [274] = "DownArrow", [275] = "RightArrow", [276] = "LeftArrow",
	[304] = "LeftShift", [303] = "RightShift", [306] = "LeftControl", [305] = "RightControl",
	[308] = "LeftAlt", [307] = "RightAlt",
}
self._T.keyCodeByName = {}
for code, name in pairs(self._T.keyNameByCode) do
	self._T.keyCodeByName[name] = code
end

self._T.defaults = {
	version = self.CURRENT_VERSION,
	volume = { bgm = 70, sfx = 80, voice = 60 },
	keys = {
		MoveLeft = "A", MoveRight = "D", Jump = "Space", Attack = "J", Dash = "K",
		BeatLeft = "LeftArrow", BeatRight = "RightArrow", BeatConfirm = "DownArrow",
	},
}

self._T.saved = self:CloneSettings(self._T.defaults)
self._T.draft = self:CloneSettings(self._T.defaults)
end

method table GetDraft()
return self._T.draft
end

method table GetSaved()
return self._T.saved
end

-- ================================================================
-- [추가] 사운드·입력이 쓰는 조회 3개.
-- draft를 읽는 이유: 설정 화면에서 바꾸는 즉시 게임에 반영되고,
-- 저장 없이 닫으면 RevertDraftToSaved가 draft를 되돌리므로 함께 복구된다.
-- ================================================================
@ExecSpace("ClientOnly")
method integer GetVolume(string channel)
if self._T == nil or self._T.draft == nil then return 100 end
local v = self._T.draft.volume[channel]
if v == nil then return 100 end
return v
end

@ExecSpace("ClientOnly")
method number GetVolume01(string channel)
-- 0~100 정수를 실제 재생 볼륨 0.0~1.0으로. 0이면 완전 무음.
return self:GetVolume(channel) / 100
end

@ExecSpace("ClientOnly")
method string GetKeyName(string action)
-- 게임플레이 코드가 쓰는 키 조회. 하드코딩된 KeyboardKey 비교 대신 이걸 쓴다.
-- 예) BattleInput에서 _SettingsManager:GetKeyName("BeatLeft")
if self._T == nil or self._T.draft == nil then return "" end
local v = self._T.draft.keys[action]
if v == nil then return "" end
return v
end

method table GetActionNames()
return self._T.actionNames
end

method boolean IsKeyAllowed(string keyName)
if self._T.keyCodeByName[keyName] == nil then return false end
return self._T.forbiddenKeyNames[keyName] ~= true
end

method string FindActionUsingKey(string keyName, string excludingAction)
for _, action in ipairs(self._T.actionNames) do
	if action ~= excludingAction and self._T.draft.keys[action] == keyName then
		return action
	end
end
return ""
end

method boolean HasUnsavedChanges()
local a, b = self._T.draft, self._T.saved
if a.volume.bgm ~= b.volume.bgm or a.volume.sfx ~= b.volume.sfx or a.volume.voice ~= b.volume.voice then
	return true
end
for _, action in ipairs(self._T.actionNames) do
	if a.keys[action] ~= b.keys[action] then return true end
end
return false
end

method string KeyNameFromCode(any code)
return self._T.keyNameByCode[code] or tostring(code)
end

method any KeyCodeFromName(string name)
return KeyboardKey.CastFrom(name)
end

@ExecSpace("ClientOnly")
method void SetDraftVolume(string channel, integer value)
-- Clamp to 0-100 integers; 0 must mean fully silent (handled by the
-- caller applying value/100 == 0.0 to SetBGMVolume/PlaySound).
local clamped = math.max(0, math.min(100, value))
self._T.draft.volume[channel] = clamped
self:Emit("volume", channel, "")
end

@ExecSpace("ClientOnly")
method void SetDraftKey(string action, string keyName)
self._T.draft.keys[action] = keyName
self:Emit("keys", action, "")
end

@ExecSpace("ClientOnly")
method void RestoreDraftDefaults()
self._T.draft = self:CloneSettings(self._T.defaults)
self:Emit("restored", "", "")
end

@ExecSpace("ClientOnly")
method void RevertDraftToSaved()
self._T.draft = self:CloneSettings(self._T.saved)
self:Emit("reverted", "", "")
end

@ExecSpace("ClientOnly")
method void NotifyUIOpened()
self:Emit("uiOpened", "", "")
end

@ExecSpace("ClientOnly")
method void NotifyUIClosed()
self:Emit("uiClosed", "", "")
end

@ExecSpace("ClientOnly")
method void Apply()
self:RequestSave(self:CloneSettings(self._T.draft))
end

@ExecSpace("ClientOnly")
method void LoadForCurrentPlayer()
self:RequestLoad()
end

@ExecSpace("Server")
method void RequestLoad()
local playerEntity = _UserService:GetUserEntityByUserId(senderUserId)
if not isvalid(playerEntity) then
	return
end
local profileCode = playerEntity.PlayerComponent.ProfileCode
local storage = _DataStorageService:GetUserDataStorage(profileCode)
local errorCode, raw = storage:GetAndWait("Settings")

local loaded = nil
if errorCode == 0 and not _UtilLogic:IsNilorEmptyString(raw) then
	local ok, decoded = pcall(function() return _HttpService:JSONDecode(raw) end)
	if ok then loaded = decoded end
elseif errorCode ~= 0 and errorCode ~= 1000002 then
	log_error("[SettingsManager] Settings load failed. ErrorCode: " .. tostring(errorCode))
end

local merged = self:MergeWithDefaults(loaded)
self:ReceiveLoadedSettings(merged, senderUserId)
end

@ExecSpace("Server")
method void RequestSave(table draftData)
local playerEntity = _UserService:GetUserEntityByUserId(senderUserId)
if not isvalid(playerEntity) then
	self:ReceiveSaveResult(false, "player entity not found", senderUserId)
	return
end
local profileCode = playerEntity.PlayerComponent.ProfileCode
local storage = _DataStorageService:GetUserDataStorage(profileCode)

local merged = self:MergeWithDefaults(draftData)
local json = _HttpService:JSONEncode(merged)
local errorCode = storage:SetAndWait("Settings", json)

if errorCode == 0 then
	self:ReceiveSaveResult(true, "", senderUserId)
else
	log_error("[SettingsManager] Settings save failed. ErrorCode: " .. tostring(errorCode))
	self:ReceiveSaveResult(false, "ErrorCode " .. tostring(errorCode), senderUserId)
end
end

@ExecSpace("Client")
method void ReceiveLoadedSettings(table merged)
self._T.saved = merged
self._T.draft = self:CloneSettings(merged)
self.isLoaded = true
self:Emit("loaded", "", "")
log("[SettingsManager] Loaded settings bgm=" .. tostring(merged.volume.bgm)
	.. " sfx=" .. tostring(merged.volume.sfx) .. " voice=" .. tostring(merged.volume.voice))
end

@ExecSpace("Client")
method void ReceiveSaveResult(boolean success, string message)
if success then
	self._T.saved = self:CloneSettings(self._T.draft)
	self:Emit("applied", "", "")
	log("[SettingsManager] Apply saved successfully")
else
	self:Emit("applyFailed", "", message)
	log_warning("[SettingsManager] Apply failed: " .. message)
end
end

method table CloneSettings(table src)
-- 여기 나열된 필드만 복사된다. 액션을 추가하면 반드시 여기에도 넣을 것.
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
end

method table MergeWithDefaults(table loaded)
local merged = self:CloneSettings(self._T.defaults)
if type(loaded) ~= "table" then
	return merged
end

if type(loaded.volume) == "table" then
	for _, channel in ipairs({ "bgm", "sfx", "voice" }) do
		local v = loaded.volume[channel]
		if type(v) == "number" then
			merged.volume[channel] = math.floor(math.max(0, math.min(100, v)) + 0.5)
		end
	end
end

if type(loaded.keys) == "table" then
	for _, action in ipairs(self._T.actionNames) do
		local keyName = loaded.keys[action]
		if type(keyName) == "string" and self._T.keyCodeByName[keyName] ~= nil then
			merged.keys[action] = keyName
		end
	end
end

return merged
end

method void Emit(string kind, string name, string message)
local event = SettingsChangedEvent()
event.kind = kind
event.name = name
event.message = message
self:SendEvent(event)
end

end
