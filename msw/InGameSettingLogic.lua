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
-- ==============================================================
-- [추가] 설정값은 프로퍼티가 아니라 _T에 둔다. 이미 임포트된 스크립트에
-- 새 프로퍼티를 붙이면 프로젝트에 등록되지 않아 "no such field"가 난다.
-- ==============================================================
-- RhythmGameManager 엔티티를 찾을 태그(BattleInput의 managerTag와 같은 값)
self._T.managerTag = "rhythmmanager"
-- [스테이지로 돌아가기]가 띄울 UI 그룹 이름.
-- _UIManager가 /ui/BattleLoseUIGroup → /ui/BattleLose 순으로 찾는다.
-- 별도 그룹 없이 GameUI의 결과창만 쓰려면 ""로 비워 둔다.
self._T.battleLoseGroup = "BattleLose"

-- 슬롯이 비어 있어도 멈추지 않는다. 건너뛴 항목은 로그로 알려준다.
self:SetEnableIfValid(self.popupContent, false, "popupContent")
self:SetEnableIfValid(self.countdownLabel, false, "countdownLabel")
self:SetEnableIfValid(self.processingOverlay, false, "processingOverlay")

if self.pauseBtn ~= nil then
	self.pauseBtnHandler = self.pauseBtn.Entity:ConnectEvent(ButtonClickEvent, self.OnPauseBtnClick)
end
if self.closeBtn ~= nil then
	self.closeBtnHandler = self.closeBtn.Entity:ConnectEvent(ButtonClickEvent, self.OnCloseBtnClick)
end
if self.btnClose ~= nil then
	self.btnCloseHandler = self.btnClose.Entity:ConnectEvent(ButtonClickEvent, self.OnCloseBtnClick)
end
if self.btnHome ~= nil then
	self.btnHomeHandler = self.btnHome.Entity:ConnectEvent(ButtonClickEvent, self.OnHomeClick)
end
if self.btnRetry ~= nil then
	self.btnRetryHandler = self.btnRetry.Entity:ConnectEvent(ButtonClickEvent, self.OnRetryClick)
end

if self.sliderBgm ~= nil then
	self.sliderBgmHandler = self.sliderBgm.Entity:ConnectEvent(SliderValueChangedEvent, self.OnBgmChanged)
end
if self.sliderSfx ~= nil then
	self.sliderSfxHandler = self.sliderSfx.Entity:ConnectEvent(SliderValueChangedEvent, self.OnSfxChanged)
end
if self.sliderVoice ~= nil then
	self.sliderVoiceHandler = self.sliderVoice.Entity:ConnectEvent(SliderValueChangedEvent, self.OnVoiceChanged)
end
if self.sliderSfxTouch ~= nil then
	self.sliderSfxTouchHandler = self.sliderSfxTouch.Entity:ConnectEvent(UITouchEndDragEvent, self.OnSfxReleased)
end
if self.sliderVoiceTouch ~= nil then
	self.sliderVoiceTouchHandler = self.sliderVoiceTouch.Entity:ConnectEvent(UITouchEndDragEvent, self.OnVoiceReleased)
end

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

-- [추가] 노래를 먼저 멈춘다. 팝업이 뜬 뒤에 끄면 한 박자 늦게 끊긴다.
self:SetMusicPaused(true)

_PauseManager:RequestPause(self.pauseReasonId)
self:RefreshFromDraft()
self:ShowPopup()
end

@ExecSpace("ClientOnly")
method void SetMusicPaused(boolean on)
-- [추가] 팝업이 뜨고 지는 동안 BGM과 효과음을 멈췄다 되살린다.
-- 실제 처리는 모든 재생을 소유한 _SoundChannels가 한다.
--   on = true  → BGM을 끄고 새로 들어오는 효과음도 막는다
--   on = false → 막은 것을 푼다(전투 BGM은 RhythmGameManager가 비트와 함께
--                처음부터 다시 튼다. 음악만 먼저 살리면 비트와 어긋난다)
-- 사운드 때문에 팝업이 안 뜨는 일이 없도록 pcall로 감싼다.
-- _PauseManager도 같은 호출을 하는 구성이면 여기서는 아무 일도 하지 않는다
-- (_SoundChannels:SetPaused는 같은 상태로 다시 부르면 즉시 반환한다).
local ok = pcall(function()
	_SoundChannels:SetPaused(on)
end)
if ok == false then
	log("[InGameSettingLogic] 사운드 정지 실패(무시) — _SoundChannels 임포트 확인")
end
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
	-- [추가] 재개. 카운트다운이 끝나고 실제로 풀리는 이 시점에 노래도 되살린다.
	self:SetMusicPaused(false)

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
-- [변경] 이 버튼은 "스테이지로 돌아가기". 로비로 나가는 대신 전투를
-- 패배로 끝내고 BattleLose 화면을 띄운다. 안내 문구도 그에 맞춘다.
if self.processing then return end
_ConfirmDialogController:Show(
	"스테이지로 돌아가기",
	"지금 나가면 이번 전투는 패배로 처리됩니다. 돌아갈까요?",
	-- [수정] self.ExecuteHome을 그대로 넘기면 나중에 callback()으로 불릴 때
	-- 수신자가 없어 self가 nil이 된다. 클로저로 감싸 self를 붙들어 둔다.
	function() self:ExecuteHome() end,
	nil
)
end

@ExecSpace("ClientOnly")
method void OnRetryClick()
if self.processing then return end
_ConfirmDialogController:Show(
	"스테이지 재도전",
	"현재 스테이지를 처음부터 다시 시작할까요?",
	-- [수정] 위와 같은 이유로 클로저로 감싼다.
	function() self:ExecuteRetry() end,
	nil
)
end

@ExecSpace("ClientOnly")
method void ExecuteHome()
-- ==============================================================
-- [변경] "스테이지로 돌아가기" 확정.
-- 순서가 중요하다.
--   1) 팝업을 먼저 닫는다 — 결과 화면을 가리지 않게.
--   2) 전투를 패배로 마감한다 — RhythmGameManager가 hasStarted를 내리므로,
--      3)에서 정지가 풀릴 때 ResumeBattle이 BGM을 다시 틀지 않는다.
--      (반대 순서로 하면 노래가 잠깐 다시 나왔다가 꺼진다)
--   3) 정지를 푼다 — 안 풀면 결과 화면 뒤에서 게임이 멈춘 채 남는다.
-- ==============================================================
if self.processing then return end
self:SetProcessing(true)

self.isOpen = false
if isvalid(self.popupContent) then
	self.popupContent.Enable = false
end

self:ShowBattleLose()

_PauseManager:RequestResume(self.pauseReasonId)
self:SetMusicPaused(false)

self:SetProcessing(false)
end

@ExecSpace("ClientOnly")
method void ShowBattleLose()
-- [추가] 전투를 패배로 끝내고 BattleLose 화면을 띄운다.
-- RhythmGameManager:OnBattleLose가 러너 정지, 마크 정리, 캐릭터 조작 복구,
-- BGM 정지까지 하고 GameUI:ShowResult(false, 0, stageTime)를 부른다.
-- 이미 끝난 전투면 그쪽에서 알아서 무시한다(hasStarted 검사).
local mgrEntity = nil
local ok = pcall(function()
	mgrEntity = _EntityService:GetEntityByTag(self._T.managerTag)
end)
if ok and mgrEntity ~= nil and mgrEntity.RhythmGameManager ~= nil then
	mgrEntity.RhythmGameManager:OnBattleLose()
else
	log("[InGameSettingLogic] 태그 '" .. tostring(self._T.managerTag)
		.. "'로 RhythmGameManager를 못 찾음 — 전투 마감 없이 화면만 띄운다")
end

-- 따로 만들어 둔 BattleLose UI 그룹이 있으면 켠다.
-- 없으면 _UIManager가 "그룹 없음" 로그만 남기고 넘어간다.
if self._T.battleLoseGroup ~= "" then
	local okUI = pcall(function()
		_UIManager:ShowGroup(self._T.battleLoseGroup)
	end)
	if okUI == false then
		log("[InGameSettingLogic] BattleLose UI 그룹을 켜지 못했다")
	end
end
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
