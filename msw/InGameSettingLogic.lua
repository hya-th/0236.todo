@Logic
script InGameSettingLogic extends Logic

-- ================================================================
-- 인게임 일시정지 설정 팝업.
--
-- 고친 것
--  1. 비어 있는 슬롯에서 OnBeginPlay가 멈춰 이후 연결이 전부 무산되던 문제
--     (countdownLabel / processingOverlay / 음성 슬라이더 등)
--  2. 음성(voice) 채널이 없는 화면도 지원 — 연결된 슬라이더만 갱신한다
--  3. card에 CanvasGroupComponent가 없으면 열기 애니메이션을 건너뛴다
--  4. 저장·미리듣기 호출을 프로젝트에 실제로 있는 쪽으로 찾아 쓴다
-- ================================================================

property string pauseReasonId = "InGameSettingPopup"

property ButtonComponent pauseBtn = "87561368-a703-426e-a7f8-fc86af2d2ed6"
property Entity popupContent = "b2d4a8e8-a73f-49cb-8397-2ca3c220e973"
property Entity card = "b76ac32a-1fbc-48b9-b04b-2a5c7abd25b5"
property ButtonComponent closeBtn = "125b9d87-41a6-4c68-ac4e-bf1bf0af0d39"

property SliderComponent sliderBgm = "bd4762f7-032f-428e-9e1e-8d1fb435c8cc"
property TextGUIRendererComponent percentBgm = "f636a281-3125-45f1-8055-6a5649fadf2b"
property SliderComponent sliderSfx = "d49ba844-830c-453d-925b-6e4ceb0e7852"
property TextGUIRendererComponent percentSfx = "f8be721c-f784-4c29-a42f-1dbd023b48ca"
property UITouchReceiveComponent sliderSfxTouch = "d49ba844-830c-453d-925b-6e4ceb0e7852"
-- 음성 채널이 없는 화면이면 아래 셋은 비워 두면 된다.
property SliderComponent sliderVoice = "ce68974d-e224-411f-8229-9243b7bd37ec"
property TextGUIRendererComponent percentVoice = "d862fa67-83e1-4d72-b3ef-2935f6e30896"
property UITouchReceiveComponent sliderVoiceTouch = "ce68974d-e224-411f-8229-9243b7bd37ec"

property ButtonComponent btnHome = "9e555800-eff8-4e78-96eb-4bd8622a6040"
property ButtonComponent btnRetry = "8ab73397-9181-4993-ae37-4647604065d8"
property ButtonComponent btnClose = "b72f0896-a10b-42c0-89c9-b796d275e7a9"

-- 아래 셋은 선택. 만들지 않았으면 비워 두면 된다.
property Entity processingOverlay = "2b7fbe27-7735-4bab-8025-963ca4409505"
property Entity countdownLabel = "bc3847ef-5e96-437d-b512-c981bb0541b4"
property TextGUIRendererComponent countdownText = "bc3847ef-5e96-437d-b512-c981bb0541b4"

property string percentSuffix = "%" -- 값 뒤에 붙일 문자. 숫자만 쓰려면 ""

property boolean isOpen = false
property boolean processing = false
property number openAnimDuration = 0.15
property integer openAnimTimerId = 0

property any pauseBtnHandler = nil
property any closeBtnHandler = nil
property any sliderBgmHandler = nil
property any sliderSfxHandler = nil
property any sliderVoiceHandler = nil
property any sliderSfxTouchHandler = nil
property any sliderVoiceTouchHandler = nil
property any btnHomeHandler = nil
property any btnRetryHandler = nil
property any btnCloseHandler = nil
property any pauseStateHandler = nil
property any keyDownHandler = nil

@ExecSpace("ClientOnly")
method void OnBeginPlay()
-- 슬롯이 비어 있어도 멈추지 않는다. 건너뛴 항목은 로그로 알려준다.
self:SetEnableIfValid(self.popupContent, false, "popupContent")
self:SetEnableIfValid(self.countdownLabel, false, "countdownLabel")
self:SetEnableIfValid(self.processingOverlay, false, "processingOverlay")

self.pauseBtnHandler = self:ConnectIfSet(self.pauseBtn, ButtonClickEvent, self.OnPauseBtnClick, "pauseBtn")
self.closeBtnHandler = self:ConnectIfSet(self.closeBtn, ButtonClickEvent, self.OnCloseBtnClick, "closeBtn")
self.btnCloseHandler = self:ConnectIfSet(self.btnClose, ButtonClickEvent, self.OnCloseBtnClick, "btnClose")
self.btnHomeHandler = self:ConnectIfSet(self.btnHome, ButtonClickEvent, self.OnHomeClick, "btnHome")
self.btnRetryHandler = self:ConnectIfSet(self.btnRetry, ButtonClickEvent, self.OnRetryClick, "btnRetry")

self.sliderBgmHandler = self:ConnectIfSet(self.sliderBgm, SliderValueChangedEvent, self.OnBgmChanged, "sliderBgm")
self.sliderSfxHandler = self:ConnectIfSet(self.sliderSfx, SliderValueChangedEvent, self.OnSfxChanged, "sliderSfx")
self.sliderVoiceHandler = self:ConnectIfSet(self.sliderVoice, SliderValueChangedEvent, self.OnVoiceChanged, "sliderVoice")
self.sliderSfxTouchHandler = self:ConnectIfSet(self.sliderSfxTouch, UITouchEndDragEvent, self.OnSfxReleased, "sliderSfxTouch")
self.sliderVoiceTouchHandler = self:ConnectIfSet(self.sliderVoiceTouch, UITouchEndDragEvent, self.OnVoiceReleased, "sliderVoiceTouch")

self.pauseStateHandler = _PauseManager:ConnectEvent(PauseStateChangedEvent, self.OnPauseStateChanged)
self.keyDownHandler = _InputService:ConnectEvent(KeyDownEvent, self.OnGlobalKeyDown)

log("[InGameSettingLogic] OnBeginPlay wired")
end

@ExecSpace("ClientOnly")
method void OnEndPlay()
if self.pauseBtnHandler then self.pauseBtn.Entity:DisconnectEvent(ButtonClickEvent, self.pauseBtnHandler) end
if self.closeBtnHandler then self.closeBtn.Entity:DisconnectEvent(ButtonClickEvent, self.closeBtnHandler) end
if self.btnCloseHandler then self.btnClose.Entity:DisconnectEvent(ButtonClickEvent, self.btnCloseHandler) end
if self.btnHomeHandler then self.btnHome.Entity:DisconnectEvent(ButtonClickEvent, self.btnHomeHandler) end
if self.btnRetryHandler then self.btnRetry.Entity:DisconnectEvent(ButtonClickEvent, self.btnRetryHandler) end
if self.sliderBgmHandler then self.sliderBgm.Entity:DisconnectEvent(SliderValueChangedEvent, self.sliderBgmHandler) end
if self.sliderSfxHandler then self.sliderSfx.Entity:DisconnectEvent(SliderValueChangedEvent, self.sliderSfxHandler) end
if self.sliderVoiceHandler then self.sliderVoice.Entity:DisconnectEvent(SliderValueChangedEvent, self.sliderVoiceHandler) end
if self.sliderSfxTouchHandler then self.sliderSfxTouch.Entity:DisconnectEvent(UITouchEndDragEvent, self.sliderSfxTouchHandler) end
if self.sliderVoiceTouchHandler then self.sliderVoiceTouch.Entity:DisconnectEvent(UITouchEndDragEvent, self.sliderVoiceTouchHandler) end
if self.pauseStateHandler then _PauseManager:DisconnectEvent(PauseStateChangedEvent, self.pauseStateHandler) end
if self.keyDownHandler then _InputService:DisconnectEvent(KeyDownEvent, self.keyDownHandler) end
if self.openAnimTimerId ~= 0 then _TimerService:ClearTimer(self.openAnimTimerId) end
end

@ExecSpace("ClientOnly")
method void SetEnableIfValid(Entity target, boolean value, string slotName)
if isvalid(target) then
	target.Enable = value
else
	log("[InGameSettingLogic] " .. slotName .. " 미연결 — 해당 요소 비활성")
end
end

@ExecSpace("ClientOnly")
method any ConnectIfSet(any component, any eventType, any callback, string slotName)
-- 슬롯이 비어 있으면 연결을 건너뛰고 무엇이 빠졌는지 알린다.
if component == nil then
	log("[InGameSettingLogic] " .. slotName .. " 미연결 — 해당 기능 비활성")
	return nil
end
return component.Entity:ConnectEvent(eventType, callback)
end

@ExecSpace("ClientOnly")
method void OnPauseBtnClick()
self:OpenPopup()
end

@ExecSpace("ClientOnly")
method void OnGlobalKeyDown(KeyDownEvent event)
-- NOTE: 모바일 뒤로가기가 같은 KeyDownEvent(Escape)로 오는지는 확인되지 않았다.
-- PC의 ESC는 확인됨. 모바일은 실기에서 확인 필요.
if _SettingsManager:KeyNameFromCode(event.key) == "Escape" then
	if self.isOpen then
		self:OnCloseBtnClick()
	else
		self:OpenPopup()
	end
end
end

@ExecSpace("ClientOnly")
method void OpenPopup()
-- 중복 열기 방지.
if self.isOpen then
	return
end
if isvalid(self.popupContent) == false then
	log("[InGameSettingLogic] popupContent 미연결 — 열 수 없다")
	return
end
self.isOpen = true
if self.pauseBtn ~= nil then
	self.pauseBtn.Enable = false
end
_PauseManager:RequestPause(self.pauseReasonId)
self:RefreshFromDraft()
self:ShowPopup()
end

@ExecSpace("ClientOnly")
method void OnCloseBtnClick()
-- "닫기(이어하기)"와 "X"는 동일: 저장 없이 재개(볼륨은 변경 시점에 이미 저장됨).
if not self.isOpen then
	return
end
self.isOpen = false
-- PauseManager가 재개 전 카운트다운을 넣을 수 있으므로, 실제 isPaused=false가
-- 올 때 OnPauseStateChanged가 팝업을 감춘다.
_PauseManager:RequestResume(self.pauseReasonId)
end

@ExecSpace("ClientOnly")
method void OnPauseStateChanged(PauseStateChangedEvent event)
if event.isPaused and event.countdownSecondsLeft > 0 then
	if isvalid(self.countdownLabel) then
		self.countdownLabel.Enable = true
	end
	if self.countdownText ~= nil then
		self.countdownText.Text = tostring(event.countdownSecondsLeft)
	end
	return
end

if isvalid(self.countdownLabel) then
	self.countdownLabel.Enable = false
end

if not event.isPaused then
	if self.pauseBtn ~= nil then
		self.pauseBtn.Enable = true
	end
	if isvalid(self.popupContent) then
		self.popupContent.Enable = false
	end
end
end

@ExecSpace("ClientOnly")
method void ShowPopup()
self.popupContent.Enable = true

-- card나 CanvasGroupComponent가 없으면 연출만 건너뛰고 그대로 표시한다.
local canvasGroup = nil
local uiTransform = nil
if isvalid(self.card) then
	canvasGroup = self.card.CanvasGroupComponent
	uiTransform = self.card.UITransformComponent
end
if canvasGroup == nil or uiTransform == nil then
	log("[InGameSettingLogic] card/CanvasGroupComponent 없음 — 열기 연출 생략")
	return
end

canvasGroup.GroupAlpha = 0
uiTransform.UIScale = Vector3(0.92, 0.92, 1)

if self.openAnimTimerId ~= 0 then
	_TimerService:ClearTimer(self.openAnimTimerId)
end
local time = 0
local preTime = _UtilLogic.ElapsedSeconds
self.openAnimTimerId = _TimerService:SetTimerRepeat(function()
	local delta = _UtilLogic.ElapsedSeconds - preTime
	preTime = _UtilLogic.ElapsedSeconds
	time = time + delta
	local t = math.min(1, time / self.openAnimDuration)
	canvasGroup.GroupAlpha = t
	local scale = _TweenLogic:Ease(0.92, 1.0, self.openAnimDuration, EaseType.SineEaseOut, time)
	uiTransform.UIScale = Vector3(scale, scale, 1)
	if t >= 1 then
		_TimerService:ClearTimer(self.openAnimTimerId)
		self.openAnimTimerId = 0
	end
end, 1 / 60)
end

@ExecSpace("ClientOnly")
method void RefreshFromDraft()
-- 연결된 채널만 갱신한다(음성 슬라이더가 없는 화면도 지원).
local draft = _SettingsManager:GetDraft()
if self.sliderBgm ~= nil then self.sliderBgm.Value = draft.volume.bgm end
if self.percentBgm ~= nil then self.percentBgm.Text = tostring(draft.volume.bgm) .. self.percentSuffix end
if self.sliderSfx ~= nil then self.sliderSfx.Value = draft.volume.sfx end
if self.percentSfx ~= nil then self.percentSfx.Text = tostring(draft.volume.sfx) .. self.percentSuffix end
if draft.volume.voice ~= nil then
	if self.sliderVoice ~= nil then self.sliderVoice.Value = draft.volume.voice end
	if self.percentVoice ~= nil then self.percentVoice.Text = tostring(draft.volume.voice) .. self.percentSuffix end
end
end

@ExecSpace("ClientOnly")
method void ApplyVolumeChange(string channel, integer value, any label)
-- 값 반영 + 표시 + 저장 요청을 한곳에 모았다.
_SettingsManager:SetDraftVolume(channel, value)
if label ~= nil then
	label.Text = tostring(value) .. self.percentSuffix
end
self:RequestSaveVolume()
end

@ExecSpace("ClientOnly")
method void RequestSaveVolume()
-- SettingsManager 버전에 따라 저장 진입점이 다르다. 있는 쪽을 골라 쓴다.
if _SettingsManager.RequestDebouncedSave ~= nil then
	_SettingsManager:RequestDebouncedSave()
elseif _SettingsManager.Apply ~= nil then
	_SettingsManager:Apply()
else
	log("[InGameSettingLogic] SettingsManager에 저장 메서드가 없다 — 저장 생략")
end
end

@ExecSpace("ClientOnly")
method void OnBgmChanged(SliderValueChangedEvent event)
self:ApplyVolumeChange("bgm", math.floor(event.Value + 0.5), self.percentBgm)
end

@ExecSpace("ClientOnly")
method void OnSfxChanged(SliderValueChangedEvent event)
self:ApplyVolumeChange("sfx", math.floor(event.Value + 0.5), self.percentSfx)
end

@ExecSpace("ClientOnly")
method void OnVoiceChanged(SliderValueChangedEvent event)
self:ApplyVolumeChange("voice", math.floor(event.Value + 0.5), self.percentVoice)
end

@ExecSpace("ClientOnly")
method void OnSfxReleased(UITouchEndDragEvent event)
self:PreviewChannel("sfx")
end

@ExecSpace("ClientOnly")
method void OnVoiceReleased(UITouchEndDragEvent event)
self:PreviewChannel("voice")
end

@ExecSpace("ClientOnly")
method void PreviewChannel(string channel)
-- 사운드 로직 이름이 프로젝트마다 다르다(_SoundManager / _SoundChannels).
-- 존재하는 쪽을 찾아 호출하고, 없으면 미리듣기만 건너뛴다.
local sound = nil
if _SoundManager ~= nil then
	sound = _SoundManager
elseif _SoundChannels ~= nil then
	sound = _SoundChannels
end
if sound == nil then
	log("[InGameSettingLogic] 사운드 로직 없음 — 미리듣기 생략")
	return
end

if channel == "voice" then
	if sound.PreviewVoice ~= nil then sound:PreviewVoice() end
	return
end
if sound.PreviewSfx ~= nil then sound:PreviewSfx() end
end

@ExecSpace("ClientOnly")
method void OnHomeClick()
if self.processing then return end
_ConfirmDialogController:Show(
	"홈으로 이동",
	"진행 중인 스테이지가 초기화됩니다. 홈으로 나갈까요?",
	self.ExecuteHome,
	nil
)
end

@ExecSpace("ClientOnly")
method void OnRetryClick()
if self.processing then return end
_ConfirmDialogController:Show(
	"스테이지 재도전",
	"현재 스테이지를 처음부터 다시 시작할까요?",
	self.ExecuteRetry,
	nil
)
end

@ExecSpace("ClientOnly")
method void ExecuteHome()
if self.processing then return end
self:SetProcessing(true)
-- StageController가 먼저 재개하고 정리까지 수행한다(그쪽 순서 계약).
_StageController:RequestReturnHome()
self.isOpen = false
if isvalid(self.popupContent) then
	self.popupContent.Enable = false
end
self:SetProcessing(false)
end

@ExecSpace("ClientOnly")
method void ExecuteRetry()
if self.processing then return end
self:SetProcessing(true)
-- 정지 상태를 유지한 채 리셋·정리를 마친 뒤에 팝업을 닫고 재개한다.
_StageController:RequestRetryStage()
self.isOpen = false
if isvalid(self.popupContent) then
	self.popupContent.Enable = false
end
_PauseManager:RequestResume(self.pauseReasonId)
self:SetProcessing(false)
end

@ExecSpace("ClientOnly")
method void SetProcessing(boolean value)
self.processing = value
if isvalid(self.processingOverlay) then
	self.processingOverlay.Enable = value
end
if self.btnHome ~= nil then
	self.btnHome.Enable = not value
end
if self.btnRetry ~= nil then
	self.btnRetry.Enable = not value
end
end

end
