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
property any settingsHandler = nil

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
method number ScaleSfx(number baseVolume)
-- SoundComponent.Volume에 직접 넣을 값(원래 볼륨 x 설정 비율).
return baseVolume * self:GetSfxVolume01()
end

@ExecSpace("ClientOnly")
method void PlaySfx(string ruid, number baseVolume)
-- 기존 _SoundService:PlaySound(ruid, vol) 자리를 이걸로 바꾼다.
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
local v = self.bgmBaseVolume * self:GetBgmVolume01()
if v <= 0 then
	log("[SoundChannels] BGM 볼륨 0 — 재생 생략")
	return
end

local ruid = self.bgmRUID
pcall(function()
	_SoundService:PlaySound(ruid, v)
end)
log("[SoundChannels] BGM 재생 (볼륨 " .. tostring(v) .. ")")
end

@ExecSpace("ClientOnly")
method void RestartBgm()
-- 재생 중인 BGM이 있을 때만, 껐다 새 볼륨으로 다시 튼다.
if self.bgmPlaying == false then return end
if self.bgmRUID == "" then return end
self:StopBgmSound()
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
-- 재생 중인 BGM 정지. 프로젝트의 정지 방법이 다르면 이 메서드만 고치면 된다.
pcall(function()
	_SoundService:StopAllSound()
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
