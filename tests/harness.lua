-- 메이플스토리 월드 런타임을 흉내낸 최소 하네스.
-- SettingsLogic의 메서드를 그대로 실행해 "바꾼 값이 UI에 남는가 / 데이터에 저장되는가"를 확인한다.

ButtonClickEvent        = "ButtonClickEvent"
SliderValueChangedEvent = "SliderValueChangedEvent"
UITouchEndDragEvent     = "UITouchEndDragEvent"
KeyDownEvent            = "KeyDownEvent"
SettingsChangedEvent    = "SettingsChangedEvent"

function isvalid(o) return o ~= nil end
local logs = {}
function log(msg) table.insert(logs, msg) end
function getLogs() return logs end

local function copy(t)
	local r = {}
	for k, v in pairs(t) do
		if type(v) == "table" then r[k] = copy(v) else r[k] = v end
	end
	return r
end
local function sameKeys(a, b)
	for k, v in pairs(a) do if b[k] ~= v then return false end end
	for k, v in pairs(b) do if a[k] ~= v then return false end end
	return true
end

-- 엔티티/컴포넌트 -------------------------------------------------------
local function newEntity()
	local e = { Enable = true, _conns = {} }
	function e:ConnectEvent(ev, fn)
		self._conns[ev] = self._conns[ev] or {}
		table.insert(self._conns[ev], fn)
		return fn
	end
	function e:DisconnectEvent(ev, fn) end
	function e:Fire(ev, arg, owner)
		for _, fn in ipairs(self._conns[ev] or {}) do fn(owner, arg) end
	end
	return e
end
local function newText() return { Text = "" } end
local function newButton() return { Entity = newEntity() } end
local function newSlider() local s = { Value = 0, Entity = newEntity() } return s end

-- 서비스 ---------------------------------------------------------------
_TimerService = { SetTimerOnce = function(self, fn, sec) return 1 end, ClearTimer = function(self, id) end }
_SoundChannels = { PreviewSfx = function(self) end }

_InputService = nil
function newInputService() return newEntity() end

-- 설정 매니저 ----------------------------------------------------------
-- keyTable로 "이 프로젝트에 실제로 존재하는 액션"을 정한다.
function newSettingsManager(keyTable, opts)
	opts = opts or {}
	local mgr = newEntity()
	mgr.saved = { volume = { bgm = 50, sfx = 50 }, keys = copy(keyTable) }
	mgr.draft = copy(mgr.saved)
	mgr.owner = nil
	mgr.pendingApply = false
	function mgr:GetDraft() return self.draft end
	function mgr:GetKeyName(a) return self.saved.keys[a] end           -- 저장이 끝난 값
	function mgr:KeyNameFromCode(c) return c end
	function mgr:IsKeyAllowed(n) return n ~= "F12" end
	function mgr:SetDraftKey(a, name)
		if self.draft.keys[a] == nil then return end                    -- 없는 액션은 거절
		self.draft.keys[a] = name
		self:Emit({ kind = "keys", name = a })
	end
	function mgr:SetDraftVolume(n, v)
		assert(v ~= nil, "SetDraftVolume에 nil이 들어왔다: " .. tostring(n))
		self.draft.volume[n] = v
		self:Emit({ kind = "volume", name = n })
	end
	function mgr:HasUnsavedChanges()
		return not (sameKeys(self.draft.keys, self.saved.keys)
			and sameKeys(self.draft.volume, self.saved.volume))
	end
	function mgr:Apply()
		-- 실제 엔진처럼 서버 왕복이 있다. CompleteApply()가 불릴 때까지 saved는 옛 값.
		self.pendingApply = true
		if opts.instantApply then self:CompleteApply() end
	end
	function mgr:CompleteApply()
		if not self.pendingApply then return end
		self.pendingApply = false
		self.saved = copy(self.draft)
		self:Emit({ kind = "applied" })
	end
	function mgr:RestoreDraftDefaults()
		self.draft = copy(self.defaults or mgr.saved)
		self:Emit({ kind = "restored" })
	end
	function mgr:NotifyUIOpened() end
	function mgr:NotifyUIClosed() end
	function mgr:Emit(ev) self:Fire(SettingsChangedEvent, ev, self.owner) end
	return mgr
end

-- SettingsLogic 인스턴스 ------------------------------------------------
function newLogic(methodsFile)
	local M = assert(loadfile(methodsFile))()
	local self = {
		_T = {},
		settingsGroup = newEntity(), hideWhileOpen = newEntity(),
		openBtn = newButton(),
		sliderBgm = newSlider(), valueBgm = newText(), sliderBgmTouch = newButton(),
		sliderSfx = newSlider(), valueSfx = newText(), sliderSfxTouch = newButton(),
		keyText1 = newText(), btnChange1 = newButton(), waitIcon1 = newEntity(),
		keyText2 = newText(), btnChange2 = newButton(), waitIcon2 = newEntity(),
		keyText3 = newText(), btnChange3 = newButton(), waitIcon3 = newEntity(),
		btnRevertKeys = newButton(), syncValueText = newText(), btnSyncAdjust = newButton(),
		btnApply = newButton(), btnClose = newButton(),
		noticeLabel = nil, noticeText = nil,
		action1 = "MoveLeft", action2 = "MoveRight", action3 = "Jump",
		waitingLabel = "입력 대기", noticeDurationSeconds = 1.6,
		localSyncOffsetMs = 0, syncStepMs = 10, syncMinMs = -100, syncMaxMs = 100,
		isOpen = false, waitingAction = "", noticeTimerId = 0,
	}
	return setmetatable(self, { __index = M })
end

function clickBtn(logic, btn) btn.Entity:Fire(ButtonClickEvent, nil, logic) end
function pressKey(logic, key) _InputService:Fire(KeyDownEvent, { key = key }, logic) end

function resetLogs() logs = {} end
function lastNoticeContains(sub)
	for i = #logs, 1, -1 do
		if logs[i]:find(sub, 1, true) then return true end
	end
	return false
end
