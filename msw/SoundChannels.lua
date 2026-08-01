@Logic
script SoundChannels extends Logic

-- ================================================================
-- 사운드 볼륨 게이트웨이. 모든 재생이 여기를 거쳐야 설정 볼륨이 반영된다.
--
--   _SoundChannels:PlaySfx(ruid, 기본볼륨)   -- 효과음 재생
--   _SoundChannels:PlayBgm(ruid, 기본볼륨)   -- BGM 재생
--   _SoundChannels:StopBgm()
--   _SoundChannels:ScaleSfx(기본볼륨)        -- SoundComponent.Volume에 넣을 값
--
-- 볼륨은 SettingsManager의 draft를 읽는다(슬라이더 즉시 반영,
-- 저장 없이 닫으면 함께 복구). 0%는 완전 무음.
-- ================================================================

property string previewSfxRUID = ""
property string previewVoiceRUID = ""
property string bgmRUID = ""
property number bgmBaseVolume = 1
property boolean bgmPlaying = false
property table bgmHandle = {}
property any settingsHandler = nil
property boolean paused = false -- 일시정지 중이면 모든 소리를 막는다

@ExecSpace("ClientOnly")
method void OnBeginPlay()
self.settingsHandler = _SettingsManager:ConnectEvent(SettingsChangedEvent, self.OnSettingsChanged)
end

@ExecSpace("ClientOnly")
method void OnEndPlay()
if self.settingsHandler then
	_SettingsManager:DisconnectEvent(SettingsChangedEvent, self.settingsHandler)
end
end

@ExecSpace("ClientOnly")
method void OnSettingsChanged(SettingsChangedEvent event)
-- 설정이 바뀌거나 뒤늦게 로드되면 BGM을 새 볼륨으로 다시 재생한다.
local k = event.kind
if k == "volume" then
	self:RestartBgm()
elseif k == "loaded" then
	self:RestartBgm()
elseif k == "applied" then
	self:RestartBgm()
elseif k == "restored" then
	self:RestartBgm()
elseif k == "reverted" then
	self:RestartBgm()
end
end

@ExecSpace("ClientOnly")
method number GetBgmVolume01()
return _SettingsManager:GetVolume01("bgm")
end

@ExecSpace("ClientOnly")
method number GetSfxVolume01()
return _SettingsManager:GetVolume01("sfx")
end

@ExecSpace("ClientOnly")
method void SetPaused(boolean on)
-- PauseManager가 정지/재개할 때 호출한다. 정지 중에는 BGM을 끄고
-- 새로 들어오는 효과음도 전부 막는다.
if self.paused == on then return end
self.paused = on

if on then
	-- 어떤 곡을 틀고 있었는지는 남겨 두고 소리만 끈다
	self:StopBgmSound()
	log("[SoundChannels] 사운드 정지")
	return
end

-- 재개. 단, 전투 BGM은 RhythmGameManager가 비트와 함께 처음부터 다시 튼다.
-- (음악만 먼저 살리면 비트와 어긋난다.) 전투가 StopBgm으로 소유권을 놓은
-- 상태면 bgmPlaying이 false이므로 여기서는 아무것도 하지 않는다.
self:RestartBgm()
log("[SoundChannels] 사운드 재개")
end

@ExecSpace("ClientOnly")
method number ScaleSfx(number baseVolume)
-- SoundComponent.Volume에 직접 넣을 값(원래 볼륨 x 설정 비율).
return baseVolume * self:GetSfxVolume01()
end

@ExecSpace("ClientOnly")
method void PlaySfx(string ruid, number baseVolume)
-- 기존 _SoundService:PlaySound(ruid, vol) 자리를 이걸로 바꾼다.
if self.paused then return end
if ruid == nil then return end
if ruid == "" then return end

local v = baseVolume * self:GetSfxVolume01()
if v <= 0 then return end

pcall(function()
	_SoundService:PlaySound(ruid, v)
end)
end

@ExecSpace("ClientOnly")
method void PlayBgm(string ruid, number baseVolume)
-- BGM 재생. 어떤 곡을 어떤 크기로 틀었는지 기억해 두었다가,
-- 설정이 바뀌면 RestartBgm으로 새 볼륨에 맞춰 다시 재생한다.
if ruid == nil then return end
if ruid == "" then
	log("[SoundChannels] BGM RUID 없음 — 무음으로 진행")
	return
end

self.bgmRUID = ruid
self.bgmBaseVolume = baseVolume
self.bgmPlaying = true
self:PlayBgmNow()
end

@ExecSpace("ClientOnly")
method void PlayBgmNow()
self:StopBgmSound()
-- 정지 중에 누가 BGM을 틀려 해도 소리는 내지 않는다(곡 정보는 위에서 이미 기억됨).
if self.paused then return end

local v = self.bgmBaseVolume * self:GetBgmVolume01()
if v <= 0 then
	log("[SoundChannels] BGM 볼륨 0 — 재생 생략")
	return
end

local ruid = self.bgmRUID
local ok, handle = pcall(function()
	return _SoundService:PlaySound(ruid, v)
end)
if ok then
	if handle ~= nil then
		self.bgmHandle = { h = handle }
	end
	log("[SoundChannels] BGM 재생 (볼륨 " .. tostring(v) .. ")")
else
	log("[SoundChannels] BGM 재생 실패(무시)")
end
end

@ExecSpace("ClientOnly")
method void RestartBgm()
-- 재생 중인 BGM이 있을 때만, 껐다 새 볼륨으로 다시 튼다.
if self.bgmPlaying == false then return end
if self.bgmRUID == "" then return end
self:PlayBgmNow()
end

@ExecSpace("ClientOnly")
method void StopBgm()
self.bgmPlaying = false
self.bgmRUID = ""
self:StopBgmSound()
end

@ExecSpace("ClientOnly")
method void StopBgmSound()
-- 보관해 둔 핸들로 정지(RhythmGameManager의 StopBGM과 같은 방식).
if self.bgmHandle == nil then
	self.bgmHandle = {}
	return
end
local h = self.bgmHandle.h
self.bgmHandle = {}
if h == nil then return end
pcall(function()
	_SoundService:StopSound(h)
end)
end

@ExecSpace("ClientOnly")
method void PreviewSfx()
-- 효과음 슬라이더에서 손을 놓는 순간 1회 재생.
if self.previewSfxRUID == "" then
	log("[SoundChannels] previewSfxRUID 미지정 — 미리듣기 생략")
	return
end
self:PlaySfx(self.previewSfxRUID, 1)
end

@ExecSpace("ClientOnly")
method void PreviewVoice()
if self.previewVoiceRUID == "" then
	log("[SoundChannels] previewVoiceRUID 미지정 — 미리듣기 생략")
	return
end
self:PlaySfx(self.previewVoiceRUID, 1)
end

end
