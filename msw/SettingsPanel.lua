@Component
script SettingsPanel extends Component

-- ================================================================
-- 양피지 설정 패널의 UI 바인딩. 항상 켜져 있는 UI 루트 엔티티에 붙이고,
-- panelRoot에는 그 자식(패널 본체)을 연결한다.
-- (컴포넌트가 붙은 엔티티가 꺼지면 OnBeginPlay가 돌지 않으므로 분리한다)
--
-- 열기: 다른 스크립트에서  settingsEntity.SettingsPanel:Open()
-- ================================================================

property Entity panelRoot = "nil -- 패널 본체(딤+양피지). 드래그 연결"

-- 사운드
property SliderComponent sliderBgm = "nil -- BGM 슬라이더. Min=0 Max=100"
property TextGUIRendererComponent valueBgm = "nil -- BGM 값 박스의 텍스트"
property SliderComponent sliderSfx = "nil -- 효과음 슬라이더. Min=0 Max=100"
property TextGUIRendererComponent valueSfx = "nil -- 효과음 값 박스의 텍스트"
property UITouchReceiveComponent sliderSfxTouch = "nil -- 효과음 슬라이더와 같은 엔티티"

-- 키 설정
property TextGUIRendererComponent keyText1 = "nil -- 1번 입력 키 박스의 텍스트"
property TextGUIRendererComponent keyText2 = "nil -- 2번 입력 키 박스의 텍스트"
property TextGUIRendererComponent keyTextConfirm = "nil -- 확인 키 박스의 텍스트"
property ButtonComponent btnChange1 = "nil -- 1번 입력 변경 버튼"
property ButtonComponent btnChange2 = "nil -- 2번 입력 변경 버튼"
property ButtonComponent btnChangeConfirm = "nil -- 확인 변경 버튼"
property Entity waitIcon1 = "nil -- 1번 입력 대기 아이콘"
property Entity waitIcon2 = "nil -- 2번 입력 대기 아이콘"
property Entity waitIconConfirm = "nil -- 확인 입력 대기 아이콘"
property ButtonComponent btnRevertKeys = "nil -- 되돌리기 버튼"

-- 싱크 조절
property TextGUIRendererComponent syncValueText = "nil -- 현재 싱크 값 텍스트"
property ButtonComponent btnSyncAdjust = "nil -- 조절하기 버튼"

-- 하단 / 안내
property ButtonComponent btnApply = "nil -- 적용하기 버튼"
property ButtonComponent btnClose = "nil -- 닫기 버튼"
property Entity noticeLabel = "nil -- 안내 문구 엔티티(없으면 빈 엔티티 연결)"
property TextGUIRendererComponent noticeText = "nil -- 안내 문구 텍스트"

property string waitingLabel = "입력 대기" -- 대기 중 키 박스에 표시할 문구
property number noticeDurationSeconds = 1.8 -- 안내 문구 표시 시간
property integer syncStepMs = 10 -- 조절하기 1클릭당 증가폭(임시 동작)
property integer syncMinMs = -100 -- 임시 동작 하한
property integer syncMaxMs = 100 -- 임시 동작 상한

property boolean isOpen = false -- 패널 열림 여부
property string waitingAction = "" -- 입력 대기 중인 액션("" = 없음)
property integer noticeTimerId = 0 -- 안내 문구 숨김 타이머

property any sliderBgmHandler = nil
property any sliderSfxHandler = nil
property any sliderSfxTouchHandler = nil
property any btnChange1Handler = nil
property any btnChange2Handler = nil
property any btnChangeConfirmHandler = nil
property any btnRevertKeysHandler = nil
property any btnSyncAdjustHandler = nil
property any btnApplyHandler = nil
property any btnCloseHandler = nil

@ExecSpace("ClientOnly")
method void OnBeginPlay()
if isvalid(self.panelRoot) then self.panelRoot.Enable = false end
if isvalid(self.noticeLabel) then self.noticeLabel.Enable = false end
if isvalid(self.waitIcon1) then self.waitIcon1.Enable = false end
if isvalid(self.waitIcon2) then self.waitIcon2.Enable = false end
if isvalid(self.waitIconConfirm) then self.waitIconConfirm.Enable = false end

self.sliderBgmHandler = self.sliderBgm.Entity:ConnectEvent(SliderValueChangedEvent, self.OnBgmChanged)
self.sliderSfxHandler = self.sliderSfx.Entity:ConnectEvent(SliderValueChangedEvent, self.OnSfxChanged)
self.sliderSfxTouchHandler = self.sliderSfxTouch.Entity:ConnectEvent(UITouchEndDragEvent, self.OnSfxReleased)
self.btnChange1Handler = self.btnChange1.Entity:ConnectEvent(ButtonClickEvent, self.OnChange1Click)
self.btnChange2Handler = self.btnChange2.Entity:ConnectEvent(ButtonClickEvent, self.OnChange2Click)
self.btnChangeConfirmHandler = self.btnChangeConfirm.Entity:ConnectEvent(ButtonClickEvent, self.OnChangeConfirmClick)
self.btnRevertKeysHandler = self.btnRevertKeys.Entity:ConnectEvent(ButtonClickEvent, self.OnRevertKeysClick)
self.btnSyncAdjustHandler = self.btnSyncAdjust.Entity:ConnectEvent(ButtonClickEvent, self.OnSyncAdjustClick)
self.btnApplyHandler = self.btnApply.Entity:ConnectEvent(ButtonClickEvent, self.OnApplyClick)
self.btnCloseHandler = self.btnClose.Entity:ConnectEvent(ButtonClickEvent, self.OnCloseClick)

log("[SettingsPanel] OnBeginPlay wired")
end

@ExecSpace("ClientOnly")
method void OnEndPlay()
if self.sliderBgmHandler then self.sliderBgm.Entity:DisconnectEvent(SliderValueChangedEvent, self.sliderBgmHandler) end
if self.sliderSfxHandler then self.sliderSfx.Entity:DisconnectEvent(SliderValueChangedEvent, self.sliderSfxHandler) end
if self.sliderSfxTouchHandler then self.sliderSfxTouch.Entity:DisconnectEvent(UITouchEndDragEvent, self.sliderSfxTouchHandler) end
if self.btnChange1Handler then self.btnChange1.Entity:DisconnectEvent(ButtonClickEvent, self.btnChange1Handler) end
if self.btnChange2Handler then self.btnChange2.Entity:DisconnectEvent(ButtonClickEvent, self.btnChange2Handler) end
if self.btnChangeConfirmHandler then self.btnChangeConfirm.Entity:DisconnectEvent(ButtonClickEvent, self.btnChangeConfirmHandler) end
if self.btnRevertKeysHandler then self.btnRevertKeys.Entity:DisconnectEvent(ButtonClickEvent, self.btnRevertKeysHandler) end
if self.btnSyncAdjustHandler then self.btnSyncAdjust.Entity:DisconnectEvent(ButtonClickEvent, self.btnSyncAdjustHandler) end
if self.btnApplyHandler then self.btnApply.Entity:DisconnectEvent(ButtonClickEvent, self.btnApplyHandler) end
if self.btnCloseHandler then self.btnClose.Entity:DisconnectEvent(ButtonClickEvent, self.btnCloseHandler) end
if self.noticeTimerId ~= 0 then _TimerService:ClearTimer(self.noticeTimerId) end
end

@ExecSpace("ClientOnly")
method void Open()
if self.isOpen then return end
self.isOpen = true
-- RhythmGameManager의 ESC(전투 종료)와 겹치지 않게 전역 플래그를 세운다.
_SettingsManager:SetPanelOpen(true)
self:RefreshFromDraft()
if isvalid(self.panelRoot) then self.panelRoot.Enable = true end
end

@ExecSpace("ClientOnly")
method void Close()
if self.isOpen == false then return end
self:CancelRebind()
-- 저장 없이 닫으므로 볼륨 미리듣기까지 마지막 저장값으로 롤백한다.
_SettingsManager:DiscardDraft()
self.isOpen = false
_SettingsManager:SetPanelOpen(false)
self:HideNotice()
if isvalid(self.panelRoot) then self.panelRoot.Enable = false end
end

@ExecSpace("ClientOnly")
method void Toggle()
if self.isOpen then
	self:Close()
else
	self:Open()
end
end

@ExecSpace("ClientOnly")
method void RefreshFromDraft()
local draft = _SettingsManager:GetDraft()
self.sliderBgm.Value = draft.volume.bgm
self.valueBgm.Text = tostring(draft.volume.bgm)
self.sliderSfx.Value = draft.volume.sfx
self.valueSfx.Text = tostring(draft.volume.sfx)
self.keyText1.Text = _SettingsManager:DisplayOf(draft.keys.Input1)
self.keyText2.Text = _SettingsManager:DisplayOf(draft.keys.Input2)
self.keyTextConfirm.Text = _SettingsManager:DisplayOf(draft.keys.Confirm)
self.syncValueText.Text = self:FormatSync(draft.syncOffsetMs)
end

@ExecSpace("ClientOnly")
method string FormatSync(integer ms)
if ms > 0 then
	return "+" .. tostring(ms) .. "ms"
end
return tostring(ms) .. "ms"
end

@ExecSpace("ClientOnly")
method void OnBgmChanged(SliderValueChangedEvent event)
-- 드래그 중 바로 들리게 하되, 확정은 "적용하기"에서 한다.
local v = math.floor(event.Value + 0.5)
_SettingsManager:SetDraftVolume("bgm", v)
self.valueBgm.Text = tostring(v)
_SoundManager:SetBgmVolume(v)
end

@ExecSpace("ClientOnly")
method void OnSfxChanged(SliderValueChangedEvent event)
local v = math.floor(event.Value + 0.5)
_SettingsManager:SetDraftVolume("sfx", v)
self.valueSfx.Text = tostring(v)
_SoundManager:SetSfxVolume(v)
end

@ExecSpace("ClientOnly")
method void OnSfxReleased(UITouchEndDragEvent event)
-- 값 변경 이벤트에 미리듣기를 걸면 드래그 중 초당 수십 번 재생되므로
-- 손을 놓는 순간에만 1회 재생한다.
_SoundManager:PreviewSfx()
end

@ExecSpace("ClientOnly")
method void OnChange1Click()
self:BeginRebind("Input1")
end

@ExecSpace("ClientOnly")
method void OnChange2Click()
self:BeginRebind("Input2")
end

@ExecSpace("ClientOnly")
method void OnChangeConfirmClick()
self:BeginRebind("Confirm")
end

@ExecSpace("ClientOnly")
method TextGUIRendererComponent KeyTextOf(string action)
if action == "Input1" then return self.keyText1 end
if action == "Input2" then return self.keyText2 end
if action == "Confirm" then return self.keyTextConfirm end
return nil
end

@ExecSpace("ClientOnly")
method Entity WaitIconOf(string action)
if action == "Input1" then return self.waitIcon1 end
if action == "Input2" then return self.waitIcon2 end
if action == "Confirm" then return self.waitIconConfirm end
return nil
end

@ExecSpace("ClientOnly")
method void BeginRebind(string action)
-- 한 번에 하나의 행만 입력 대기 상태일 수 있다.
if self.waitingAction ~= "" then
	self:CancelRebind()
end
self.waitingAction = action

local textComponent = self:KeyTextOf(action)
if textComponent ~= nil then
	textComponent.Text = self.waitingLabel
end
local icon = self:WaitIconOf(action)
if isvalid(icon) then
	icon.Enable = true
end
self:ShowNotice("변경할 키를 누르세요. (ESC: 취소)")
end

@ExecSpace("ClientOnly")
method void CancelRebind()
if self.waitingAction == "" then return end
local icon = self:WaitIconOf(self.waitingAction)
if isvalid(icon) then
	icon.Enable = false
end
self.waitingAction = ""
-- draft 값으로 다시 그려 "입력 대기" 표시를 원래 키로 되돌린다.
self:RefreshFromDraft()
end

@ExecSpace("ClientOnly")
method void OnRevertKeysClick()
self:CancelRebind()
_SettingsManager:ResetDraftKeys()
self:RefreshFromDraft()
self:ShowNotice("키 설정을 기본값으로 되돌렸습니다.")
end

@ExecSpace("ClientOnly")
method void OnSyncAdjustClick()
-- TODO: 원래 "조절하기"는 비트에 맞춰 입력을 받아 오프셋을 계산하는
-- 별도의 보정 화면을 여는 버튼이다. 그 화면이 아직 없어서, 값을 직접
-- 확인할 수 있도록 클릭마다 syncStepMs 만큼 올리고 상한을 넘으면
-- 하한으로 돌아가는 임시 동작을 넣어 두었다.
local draft = _SettingsManager:GetDraft()
local nextValue = draft.syncOffsetMs + self.syncStepMs
if nextValue > self.syncMaxMs then
	nextValue = self.syncMinMs
end
_SettingsManager:SetDraftSyncOffset(nextValue)
self:RefreshFromDraft()
end

@ExecSpace("ClientOnly")
method void OnApplyClick()
self:CancelRebind()
if _SettingsManager:IsDirty() == false then
	self:ShowNotice("변경된 내용이 없습니다.")
	return
end
_SettingsManager:ApplyDraft()
self:ShowNotice("설정을 저장했습니다.")
end

@ExecSpace("ClientOnly")
method void OnCloseClick()
self:Close()
end

@ExecSpace("ClientOnly")
method void ShowNotice(string message)
if isvalid(self.noticeLabel) == false then return end
if self.noticeText ~= nil then
	self.noticeText.Text = message
end
self.noticeLabel.Enable = true

if self.noticeTimerId ~= 0 then
	_TimerService:ClearTimer(self.noticeTimerId)
	self.noticeTimerId = 0
end
-- 한 번만 실행되면 되므로 첫 발화에서 스스로 타이머를 정리한다.
self.noticeTimerId = _TimerService:SetTimerRepeat(function()
	if self.noticeTimerId ~= 0 then
		_TimerService:ClearTimer(self.noticeTimerId)
		self.noticeTimerId = 0
	end
	self:HideNotice()
end, self.noticeDurationSeconds)
end

@ExecSpace("ClientOnly")
method void HideNotice()
if isvalid(self.noticeLabel) then
	self.noticeLabel.Enable = false
end
end

@ExecSpace("ClientOnly")
@EventSender("Service", "InputService")
handler HandleKeyDownEvent(KeyDownEvent event)
-- 입력 대기 중이면 그 키를 할당하고, 아니면 ESC로 패널을 닫는다.
local keyName = _SettingsManager:KeyNameFromCode(event.key)

if self.waitingAction ~= "" then
	if keyName == "Escape" then
		self:CancelRebind()
		self:ShowNotice("키 변경을 취소했습니다.")
		return
	end
	if keyName == "" then
		self:ShowNotice("인식할 수 없는 키입니다.")
		return
	end
	if _SettingsManager:IsForbiddenKey(keyName) then
		self:ShowNotice("이 키는 사용할 수 없습니다.")
		return
	end

	local owner = _SettingsManager:FindDraftActionByKey(keyName)
	if owner ~= "" and owner ~= self.waitingAction then
		self:ShowNotice("이미 사용 중인 키입니다.")
		self:CancelRebind()
		return
	end

	local action = self.waitingAction
	_SettingsManager:SetDraftKey(action, keyName)
	local icon = self:WaitIconOf(action)
	if isvalid(icon) then
		icon.Enable = false
	end
	self.waitingAction = ""
	self:RefreshFromDraft()
	self:ShowNotice("변경되었습니다. 적용하기를 눌러 저장하세요.")
	return
end

if keyName == "Escape" and self.isOpen then
	self:Close()
end
end

end
