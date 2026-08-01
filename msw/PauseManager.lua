@Logic
script PauseManager extends Logic

-- ================================================================
-- 원본에서 달라진 곳은 두 군데뿐이다.
--   (1) EngageFreeze  : 없어진 _SoundManager:PauseAllSfxAndVoice() 자리에
--                       _SoundChannels:SetPaused(true)
--   (2) EngageUnfreeze: 없어진 _SoundManager:ResumeAllSfxAndVoice() 자리에
--                       _SoundChannels:SetPaused(false)
-- 나머지는 원본 그대로다.
--
-- 정지되는 것:
--   캐릭터 조작  PlayerControllerComponent.Enable = false   (원래 있던 것)
--   물리         PhysicsSimulatorComponent.Paused = true     (원래 있던 것)
--   사운드       _SoundChannels:SetPaused(true)              [추가]
--   전투 진행    Emit(true) → RhythmGameManager / BattleInput가 구독
-- ================================================================

property boolean resumeCountdownEnabled = false
property integer countdownTimerId = 0
property number pauseStartedAt = 0
property number totalPausedSeconds = 0

method void OnBeginPlay()
-- No @ExecSpace: reason bookkeeping and the paused-time clock must be
-- usable from both client (UI, input) and, later, server-side
-- gameplay scripts that want a pause-aware timer.
self._T.pauseReasons = {}
end

method void RequestPause(string reason)
local wasPaused = self:IsPaused()
self._T.pauseReasons[reason] = true
if not wasPaused then
	self:EngageFreeze()
end
end

method void RequestResume(string reason)
self._T.pauseReasons[reason] = nil
if not self:IsPaused() then
	if self.resumeCountdownEnabled then
		self:StartResumeCountdown()
	else
		self:EngageUnfreeze()
	end
end
end

method boolean IsPaused()
return next(self._T.pauseReasons) ~= nil
end

method number GetPauseAwareElapsedSeconds()
local paused = self.totalPausedSeconds
if self:IsPaused() then
	paused = paused + (_UtilLogic.ElapsedSeconds - self.pauseStartedAt)
end
return _UtilLogic.ElapsedSeconds - paused
end

method number SafeDelta(number rawDelta)
if self:IsPaused() then
	return 0
end
return rawDelta
end

@ExecSpace("ClientOnly")
method void OnApplicationPause(boolean appIsPaused)
log("[PauseManager] OnApplicationPause(" .. tostring(appIsPaused) .. ") -- stub, not wired to a real event yet")
end

method void EngageFreeze()
self.pauseStartedAt = _UtilLogic.ElapsedSeconds

local player = _UserService.LocalPlayer
if isvalid(player) and isvalid(player.PlayerControllerComponent) then
	player.PlayerControllerComponent.Enable = false
end

-- [변경] BGM을 끄고 새 효과음도 막는다.
-- 사운드 하나 때문에 정지 자체가 실패하면 안 되므로 pcall로 감싼다.
pcall(function()
	_SoundChannels:SetPaused(true)
end)

self:RequestSetPhysicsPaused(true)

self:Emit(true, 0)
log("[PauseManager] Freeze engaged")
end

method void StartResumeCountdown()
local remaining = 3
self:EmitCountdown(remaining)
self.countdownTimerId = _TimerService:SetTimerRepeat(function()
	remaining = remaining - 1
	if remaining <= 0 then
		_TimerService:ClearTimer(self.countdownTimerId)
		self.countdownTimerId = 0
		self:EngageUnfreeze()
	else
		self:EmitCountdown(remaining)
	end
end, 1.0)
end

method void EngageUnfreeze()
self.totalPausedSeconds = self.totalPausedSeconds + (_UtilLogic.ElapsedSeconds - self.pauseStartedAt)

local player = _UserService.LocalPlayer
if isvalid(player) and isvalid(player.PlayerControllerComponent) then
	player.PlayerControllerComponent.Enable = true
end

-- [변경] 사운드 재개. Emit(false)보다 먼저 풀어야
-- RhythmGameManager가 BGM을 다시 트는 것이 막히지 않는다.
pcall(function()
	_SoundChannels:SetPaused(false)
end)

self:RequestSetPhysicsPaused(false)

self:Emit(false, 0)
log("[PauseManager] Freeze released")
end

@ExecSpace("Server")
method void RequestSetPhysicsPaused(boolean paused)
local playerEntity = _UserService:GetUserEntityByUserId(senderUserId)
if not isvalid(playerEntity) then
	return
end
local map = playerEntity.CurrentMap
if isvalid(map) and isvalid(map.PhysicsSimulatorComponent) then
	map.PhysicsSimulatorComponent.Paused = paused
end
end

method void EmitCountdown(integer secondsLeft)
self:Emit(true, secondsLeft)
end

method void Emit(boolean paused, integer countdownSecondsLeft)
local event = PauseStateChangedEvent()
event.isPaused = paused
event.countdownSecondsLeft = countdownSecondsLeft
self:SendEvent(event)
end

end
