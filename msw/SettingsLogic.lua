@Logic
script SettingsLogic extends Logic

-- ================================================================
-- 양피지 설정 패널의 UI 바인딩.
-- 기존 SettingsManager / PlayerInputBridge / SettingsBootstrap을
-- 수정하지 않고 그대로 쓰도록 맞춘 버전이다.
--
--  · 탭 없음        — 사운드/키/싱크가 한 화면에 모두 보인다
--  · 음성 채널 없음 — voice는 건드리지 않으므로 저장값이 그대로 유지된다
--  · 확인 다이얼로그 없음 — 닫기는 변경을 되돌리고 바로 닫는다
--  · 키 박스와 "변경" 버튼이 분리된 구조를 지원한다
--
-- 볼륨을 실제 소리에 반영하는 것은 _SoundChannels의 몫이다.
-- SettingsManager가 SettingsChangedEvent("volume")를 발행하므로
-- 이 파일에서 볼륨을 직접 밀어 넣지 않는다(PlayerInputBridge가 키를
-- 처리하는 것과 같은 구조).
-- ================================================================

property Entity settingsGroup = "nil -- 패널 전체. 드래그 연결"

-- 로비/메인 화면에서 이 패널을 여는 버튼. 연결하면 별도 스크립트 없이 동작한다.
property ButtonComponent openBtn = "nil -- (선택) 로비의 설정 버튼"
-- 패널이 열린 동안 숨길 화면(로비 UI 그룹 등). 비워두면 로비 위에 겹쳐서 열린다.
-- 주의: settingsGroup의 부모를 넣으면 패널까지 같이 사라진다.
property Entity hideWhileOpen = "nil -- (선택) 패널이 열린 동안 숨길 그룹"

-- 사운드
property SliderComponent sliderBgm = "nil -- BGM 슬라이더. Min=0 Max=100"
property TextGUIRendererComponent valueBgm = "nil -- BGM 값 박스의 텍스트"
property SliderComponent sliderSfx = "nil -- 효과음 슬라이더. Min=0 Max=100"
property TextGUIRendererComponent valueSfx = "nil -- 효과음 값 박스의 텍스트"
property UITouchReceiveComponent sliderSfxTouch = "nil -- 효과음 슬라이더와 같은 엔티티"

-- 키 설정 (키 박스의 텍스트 + 그 옆의 "변경" 버튼)
property TextGUIRendererComponent keyText1 = "nil -- 1번 입력 키 박스의 텍스트"
property ButtonComponent btnChange1 = "nil -- 1번 입력 변경 버튼"
property Entity waitIcon1 = "nil -- (선택) 1번 입력 대기 아이콘"
property TextGUIRendererComponent keyText2 = "nil -- 2번 입력 키 박스의 텍스트"
property ButtonComponent btnChange2 = "nil -- 2번 입력 변경 버튼"
property Entity waitIcon2 = "nil -- (선택) 2번 입력 대기 아이콘"
property TextGUIRendererComponent keyText3 = "nil -- 확인 키 박스의 텍스트"
property ButtonComponent btnChange3 = "nil -- 확인 변경 버튼"
property Entity waitIcon3 = "nil -- (선택) 확인 입력 대기 아이콘"
property ButtonComponent btnRevertKeys = "nil -- 되돌리기 버튼"

-- 싱크 조절
property TextGUIRendererComponent syncValueText = "nil -- 현재 싱크 값 텍스트"
property ButtonComponent btnSyncAdjust = "nil -- 조절하기 버튼"

-- 하단 / 안내
property ButtonComponent btnApply = "nil -- 적용하기 버튼"
property ButtonComponent btnClose = "nil -- 닫기 버튼"
property Entity noticeLabel = "nil -- (선택) 안내 문구 엔티티"
property TextGUIRendererComponent noticeText = "nil -- (선택) 안내 문구 텍스트"

-- 화면의 세 행이 어떤 액션에 대응하는지. SettingsManager의 actionNames에
-- 있는 이름을 써야 한다. 나중에 액션 이름을 Input1/Input2/Confirm 등으로
-- 바꾸면 코드 대신 여기 값만 고치면 된다.
property string action1 = "MoveLeft" -- 1번 입력
property string action2 = "MoveRight" -- 2번 입력
property string action3 = "Jump" -- 확인

property string waitingLabel = "입력 대기" -- 대기 중 키 박스에 표시할 문구
property number noticeDurationSeconds = 1.6 -- 안내 문구 표시 시간

-- 싱크 조절. SettingsManager에 syncOffsetMs가 없으면 이 값이 세션 동안만
-- 유지된다(저장 안 됨). 영속 저장하려면 SettingsManager의 defaults /
-- CloneSettings / MergeWithDefaults 세 곳에 syncOffsetMs를 추가하면
-- 이 파일은 수정 없이 그대로 저장까지 동작한다.
property integer localSyncOffsetMs = 0
property integer syncStepMs = 10
property integer syncMinMs = -100
property integer syncMaxMs = 100

property boolean isOpen = false
property string waitingAction = "" -- 입력 대기 중인 액션("" = 없음)
property integer noticeTimerId = 0

property any sliderBgmHandler = nil
property any sliderSfxHandler = nil
property any sliderSfxTouchHandler = nil
property any btnRevertKeysHandler = nil
property any btnSyncAdjustHandler = nil
property any btnApplyHandler = nil
property any btnCloseHandler = nil
property any openBtnHandler = nil
property any keyDownHandler = nil
property any settingsHandler = nil

@ExecSpace("ClientOnly")
method void OnBeginPlay()
self.settingsGroup.Enable = false

self._T.slots = {
	{ action = self.action1, btn = self.btnChange1, text = self.keyText1, icon = self.waitIcon1 },
	{ action = self.action2, btn = self.btnChange2, text = self.keyText2, icon = self.waitIcon2 },
	{ action = self.action3, btn = self.btnChange3, text = self.keyText3, icon = self.waitIcon3 },
}

self:BuildDisplayNames()

for _, slot in ipairs(self._T.slots) do
	if isvalid(slot.icon) then slot.icon.Enable = false end
	slot.clickHandler = slot.btn.Entity:ConnectEvent(ButtonClickEvent, function()
		self:OnKeyButtonClick(slot)
	end)
end

self.sliderBgmHandler = self.sliderBgm.Entity:ConnectEvent(SliderValueChangedEvent, self.OnBgmChanged)
self.sliderSfxHandler = self.sliderSfx.Entity:ConnectEvent(SliderValueChangedEvent, self.OnSfxChanged)
self.sliderSfxTouchHandler = self.sliderSfxTouch.Entity:ConnectEvent(UITouchEndDragEvent, self.OnSfxReleased)
self.btnRevertKeysHandler = self.btnRevertKeys.Entity:ConnectEvent(ButtonClickEvent, self.OnRevertKeysClick)
self.btnSyncAdjustHandler = self.btnSyncAdjust.Entity:ConnectEvent(ButtonClickEvent, self.OnSyncAdjustClick)
self.btnApplyHandler = self.btnApply.Entity:ConnectEvent(ButtonClickEvent, self.OnApplyClick)
self.btnCloseHandler = self.btnClose.Entity:ConnectEvent(ButtonClickEvent, self.OnCloseClick)

if self.openBtn ~= nil then
	self.openBtnHandler = self.openBtn.Entity:ConnectEvent(ButtonClickEvent, self.OnOpenBtnClick)
else
	log("[SettingsLogic] openBtn 미연결 — 다른 스크립트에서 _SettingsLogic:Toggle()로 열어야 한다")
end

self.keyDownHandler = _InputService:ConnectEvent(KeyDownEvent, self.OnGlobalKeyDown)
self.settingsHandler = _SettingsManager:ConnectEvent(SettingsChangedEvent, self.OnSettingsChanged)

self:HideNotice()
log("[SettingsLogic] OnBeginPlay wired")
end

@ExecSpace("ClientOnly")
method void OnEndPlay()
for _, slot in ipairs(self._T.slots) do
	if slot.clickHandler then slot.btn.Entity:DisconnectEvent(ButtonClickEvent, slot.clickHandler) end
end
if self.sliderBgmHandler then self.sliderBgm.Entity:DisconnectEvent(SliderValueChangedEvent, self.sliderBgmHandler) end
if self.sliderSfxHandler then self.sliderSfx.Entity:DisconnectEvent(SliderValueChangedEvent, self.sliderSfxHandler) end
if self.sliderSfxTouchHandler then self.sliderSfxTouch.Entity:DisconnectEvent(UITouchEndDragEvent, self.sliderSfxTouchHandler) end
if self.btnRevertKeysHandler then self.btnRevertKeys.Entity:DisconnectEvent(ButtonClickEvent, self.btnRevertKeysHandler) end
if self.btnSyncAdjustHandler then self.btnSyncAdjust.Entity:DisconnectEvent(ButtonClickEvent, self.btnSyncAdjustHandler) end
if self.btnApplyHandler then self.btnApply.Entity:DisconnectEvent(ButtonClickEvent, self.btnApplyHandler) end
if self.btnCloseHandler then self.btnClose.Entity:DisconnectEvent(ButtonClickEvent, self.btnCloseHandler) end
if self.openBtnHandler then self.openBtn.Entity:DisconnectEvent(ButtonClickEvent, self.openBtnHandler) end
if self.keyDownHandler then _InputService:DisconnectEvent(KeyDownEvent, self.keyDownHandler) end
if self.settingsHandler then _SettingsManager:DisconnectEvent(SettingsChangedEvent, self.settingsHandler) end
if self.noticeTimerId ~= 0 then _TimerService:ClearTimer(self.noticeTimerId) end
end

@ExecSpace("ClientOnly")
method void BuildDisplayNames()
-- SettingsManager는 "LeftArrow", "Alpha1", "Return" 같은 내부 이름을 준다.
-- 화면에는 화살표와 짧은 표기로 보여준다.
self._T.displayByName = {
	LeftArrow = "←", RightArrow = "→", UpArrow = "↑", DownArrow = "↓",
	Return = "Enter", Escape = "Esc", Space = "Space", Tab = "Tab",
	LeftShift = "Shift", RightShift = "R-Shift",
	LeftControl = "Ctrl", RightControl = "R-Ctrl",
	LeftAlt = "Alt", RightAlt = "R-Alt",
}
end

@ExecSpace("ClientOnly")
method string DisplayOf(string keyName)
if keyName == nil or keyName == "" then return "-" end
local mapped = self._T.displayByName[keyName]
if mapped ~= nil then return mapped end
-- "Alpha7" → "7"
local digit = string.match(keyName, "^Alpha(%d)$")
if digit ~= nil then return digit end
return keyName
end

@ExecSpace("ClientOnly")
method table SlotByAction(string action)
for _, slot in ipairs(self._T.slots) do
	if slot.action == action then return slot end
end
return nil
end

@ExecSpace("ClientOnly")
method void OnOpenBtnClick()
-- 로비의 설정 버튼. 한 번 더 누르면 닫힌다.
self:Toggle()
end

@ExecSpace("ClientOnly")
method void Toggle()
if self.isOpen then
	self:OnCloseClick()
else
	self:OpenSettings()
end
end

@ExecSpace("ClientOnly")
method void OpenSettings()
if self.isOpen then return end
self.isOpen = true
self.waitingAction = ""
self.settingsGroup.Enable = true
if isvalid(self.hideWhileOpen) then
	self.hideWhileOpen.Enable = false
end
self:RefreshFromDraft()
-- PlayerInputBridge가 이 알림을 받아 캐릭터 입력을 막는다.
_SettingsManager:NotifyUIOpened()
log("[SettingsLogic] Opened")
end

@ExecSpace("ClientOnly")
method void CloseImmediate()
self.settingsGroup.Enable = false
if isvalid(self.hideWhileOpen) then
	self.hideWhileOpen.Enable = true
end
self.isOpen = false
self.waitingAction = ""
self:HideNotice()
_SettingsManager:NotifyUIClosed()
log("[SettingsLogic] Closed")
end

@ExecSpace("ClientOnly")
method void RefreshFromDraft()
local draft = _SettingsManager:GetDraft()
self.sliderBgm.Value = draft.volume.bgm
self.valueBgm.Text = tostring(draft.volume.bgm)
self.sliderSfx.Value = draft.volume.sfx
self.valueSfx.Text = tostring(draft.volume.sfx)

for _, slot in ipairs(self._T.slots) do
	if slot.text ~= nil then
		slot.text.Text = self:DisplayOf(draft.keys[slot.action])
	end
	if isvalid(slot.icon) then slot.icon.Enable = false end
end

self.syncValueText.Text = self:FormatSync(self:GetSyncOffsetMs())
end

@ExecSpace("ClientOnly")
method void OnBgmChanged(SliderValueChangedEvent event)
-- 값 반영은 SettingsManager가, 실제 볼륨은 _SoundChannels가 이벤트를 받아 처리한다.
_SettingsManager:SetDraftVolume("bgm", math.floor(event.Value + 0.5))
end

@ExecSpace("ClientOnly")
method void OnSfxChanged(SliderValueChangedEvent event)
_SettingsManager:SetDraftVolume("sfx", math.floor(event.Value + 0.5))
end

@ExecSpace("ClientOnly")
method void OnSfxReleased(UITouchEndDragEvent event)
-- 값 변경 이벤트에 미리듣기를 걸면 드래그 중 초당 수십 번 재생되므로
-- 손을 놓는 순간에만 1회 재생한다.
_SoundChannels:PreviewSfx()
end

@ExecSpace("ClientOnly")
method void OnKeyButtonClick(table slot)
-- 한 번에 하나의 행만 입력 대기 상태일 수 있다.
if self.waitingAction ~= "" then
	return
end
self.waitingAction = slot.action
if slot.text ~= nil then
	slot.text.Text = self.waitingLabel
end
if isvalid(slot.icon) then
	slot.icon.Enable = true
end
self:ShowNotice("변경할 키를 누르세요. (ESC: 취소)")
end

@ExecSpace("ClientOnly")
method void CancelWaiting()
-- ESC / 금지 키 / 중복 거절: 원래 키 표시로 되돌린다.
if self.waitingAction == "" then return end
local slot = self:SlotByAction(self.waitingAction)
self.waitingAction = ""
if slot == nil then return end
if slot.text ~= nil then
	slot.text.Text = self:DisplayOf(_SettingsManager:GetDraft().keys[slot.action])
end
if isvalid(slot.icon) then
	slot.icon.Enable = false
end
end

@ExecSpace("ClientOnly")
method void OnGlobalKeyDown(KeyDownEvent event)
if self.waitingAction ~= "" then
	self:HandleRebindKeyDown(event)
	return
end
if self.isOpen and _SettingsManager:KeyNameFromCode(event.key) == "Escape" then
	self:OnCloseClick()
end
end

@ExecSpace("ClientOnly")
method void HandleRebindKeyDown(KeyDownEvent event)
local action = self.waitingAction
local newName = _SettingsManager:KeyNameFromCode(event.key)

if newName == "Escape" then
	self:CancelWaiting()
	self:ShowNotice("키 변경을 취소했습니다")
	return
end

if _SettingsManager:IsKeyAllowed(newName) == false then
	self:ShowNotice("이 키는 사용할 수 없습니다")
	self:CancelWaiting()
	return
end

if _SettingsManager:FindActionUsingKey(newName, action) ~= "" then
	self:ShowNotice("이미 사용 중인 키입니다")
	self:CancelWaiting()
	return
end

local slot = self:SlotByAction(action)
if isvalid(slot.icon) then
	slot.icon.Enable = false
end
self.waitingAction = ""
-- SetDraftKey가 "keys" 이벤트를 발행하고, OnSettingsChanged가 표시를 갱신한다.
_SettingsManager:SetDraftKey(action, newName)
self:ShowNotice("변경되었습니다. 적용하기를 눌러 저장하세요")
end

@ExecSpace("ClientOnly")
method void OnRevertKeysClick()
-- "되돌리기"는 키 설정 섹션의 버튼이므로 키만 기본값으로 돌린다.
-- SettingsManager에는 키 전용 초기화가 없어, 볼륨을 먼저 기억해 두고
-- 전체 초기화 후 볼륨만 되돌려 놓는다(SettingsManager 수정 없이 처리).
self:CancelWaiting()

local draft = _SettingsManager:GetDraft()
local bgm = draft.volume.bgm
local sfx = draft.volume.sfx
local voice = draft.volume.voice

_SettingsManager:RestoreDraftDefaults()
_SettingsManager:SetDraftVolume("bgm", bgm)
_SettingsManager:SetDraftVolume("sfx", sfx)
_SettingsManager:SetDraftVolume("voice", voice)

self:RefreshFromDraft()
self:ShowNotice("키 설정을 기본값으로 되돌렸습니다")
end

@ExecSpace("ClientOnly")
method integer GetSyncOffsetMs()
-- SettingsManager가 syncOffsetMs를 지원하면 그 값을, 아니면 로컬 값을 쓴다.
local draft = _SettingsManager:GetDraft()
if draft.syncOffsetMs ~= nil then
	return draft.syncOffsetMs
end
return self.localSyncOffsetMs
end

@ExecSpace("ClientOnly")
method void SetSyncOffsetMs(integer ms)
local clamped = math.max(self.syncMinMs, math.min(self.syncMaxMs, ms))
self.localSyncOffsetMs = clamped
-- SettingsManager가 이 항목을 지원하게 되면 저장까지 함께 따라간다.
local draft = _SettingsManager:GetDraft()
if draft.syncOffsetMs ~= nil then
	draft.syncOffsetMs = clamped
end
end

@ExecSpace("ClientOnly")
method string FormatSync(integer ms)
if ms > 0 then
	return "+" .. tostring(ms) .. "ms"
end
return tostring(ms) .. "ms"
end

@ExecSpace("ClientOnly")
method void OnSyncAdjustClick()
-- TODO: 원래 "조절하기"는 비트에 맞춰 입력을 받아 오프셋을 계산하는
-- 보정 화면을 여는 버튼이다. 그 화면이 아직 없어서, 값을 직접 확인할 수
-- 있도록 클릭마다 syncStepMs 만큼 올리고 상한을 넘으면 하한으로 돌아가는
-- 임시 동작을 넣어 두었다.
local nextValue = self:GetSyncOffsetMs() + self.syncStepMs
if nextValue > self.syncMaxMs then
	nextValue = self.syncMinMs
end
self:SetSyncOffsetMs(nextValue)
self.syncValueText.Text = self:FormatSync(self:GetSyncOffsetMs())
end

@ExecSpace("ClientOnly")
method void OnApplyClick()
self:CancelWaiting()
if _SettingsManager:HasUnsavedChanges() == false then
	self:ShowNotice("변경된 내용이 없습니다")
	return
end
-- 결과는 "applied" / "applyFailed" 이벤트로 돌아온다(OnSettingsChanged).
_SettingsManager:Apply()
end

@ExecSpace("ClientOnly")
method void OnCloseClick()
-- 이 화면에는 확인 다이얼로그가 없으므로, 저장하지 않은 변경은 되돌리고 닫는다.
-- RevertDraftToSaved가 "reverted" 이벤트를 발행하고 PlayerInputBridge가
-- 그것을 받아 실제 키 배치까지 원래대로 복구한다.
self:CancelWaiting()
if _SettingsManager:HasUnsavedChanges() then
	_SettingsManager:RevertDraftToSaved()
end
self.localSyncOffsetMs = self:GetSyncOffsetMs()
self:CloseImmediate()
end

@ExecSpace("ClientOnly")
method void OnSettingsChanged(SettingsChangedEvent event)
if event.kind == "volume" then
	local draft = _SettingsManager:GetDraft()
	if event.name == "bgm" then
		self.valueBgm.Text = tostring(draft.volume.bgm)
	elseif event.name == "sfx" then
		self.valueSfx.Text = tostring(draft.volume.sfx)
	end
	-- voice는 이 화면에 없으므로 무시(저장값은 그대로 유지된다)

elseif event.kind == "keys" then
	local slot = self:SlotByAction(event.name)
	if slot ~= nil and slot.text ~= nil then
		slot.text.Text = self:DisplayOf(_SettingsManager:GetDraft().keys[slot.action])
	end

elseif event.kind == "loaded" or event.kind == "restored" or event.kind == "reverted" then
	self:RefreshFromDraft()

elseif event.kind == "applied" then
	-- 이 화면은 "적용하기"와 "닫기"가 따로 있으므로 저장 후에도 닫지 않는다.
	self:RefreshFromDraft()
	self:ShowNotice("설정을 저장했습니다")

elseif event.kind == "applyFailed" then
	self:ShowNotice("저장에 실패했습니다. 다시 시도해 주세요")
end
end

@ExecSpace("ClientOnly")
method void ShowNotice(string message)
-- 안내 문구 슬롯은 선택이다. 연결하지 않았으면 로그만 남긴다.
if isvalid(self.noticeLabel) == false then
	log("[SettingsLogic] " .. message)
	return
end
if self.noticeText ~= nil then
	self.noticeText.Text = message
end
self.noticeLabel.Enable = true

if self.noticeTimerId ~= 0 then
	_TimerService:ClearTimer(self.noticeTimerId)
	self.noticeTimerId = 0
end
self.noticeTimerId = _TimerService:SetTimerOnce(function()
	self.noticeTimerId = 0
	self:HideNotice()
end, self.noticeDurationSeconds)
end

@ExecSpace("ClientOnly")
method void HideNotice()
if isvalid(self.noticeLabel) then
	self.noticeLabel.Enable = false
end
end

end
