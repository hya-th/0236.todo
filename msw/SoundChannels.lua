@Logic
script SoundChannels extends Logic

-- ================================================================
-- 사운드 볼륨 게이트웨이. 게임의 모든 사운드 재생은 이 로직을 거쳐야
-- 설정의 BGM / 효과음 볼륨이 실제로 반영된다.
--
--   _SoundChannels:PlaySfx(ruid, 기본볼륨)      -- 효과음 재생
--   _SoundChannels:PlayBgm(ruid, 기본볼륨)      -- BGM 재생(핸들 보관)
--   _SoundChannels:ScaleSfx(기본볼륨)           -- SoundComponent.Volume에 넣을 값
--   _SoundChannels:StopBgm()
--
-- 볼륨은 SettingsManager의 draft를 읽는다. 그래서
--   · 슬라이더를 움직이면 즉시 반영되고(미리듣기),
--   · 저장 없이 닫으면 RevertDraftToSaved로 함께 되돌아가고,
--   · 로그인/맵 진입 시 로드된 값이 그대로 쓰인다.
-- 0%는 완전 무음(재생 자체를 건너뜀).
-- ================================================================

property string previewSfxRUID = "" -- 효과음 슬라이더 미리듣기 샘플
property string previewVoiceRUID = "" -- 음성 슬라이더 미리듣기 샘플

property table bgmHandle = {} -- 재생 중인 BGM 핸들
property number bgmBaseVolume = 1 -- 현재 BGM의 기본 볼륨(설정 비율을 곱하기 전)
property any settingsHandler = nil

@ExecSpace("ClientOnly")
method void OnBeginPlay()
-- 설정이 바뀌거나 뒤늦게 로드되면 재생 중인 BGM에 바로 반영한다.
-- (전투 진입 직후 BGM이 먼저 시작되고 설정 로드가 나중에 도착하는 경우 대비)
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
local k = event.kind
if k == "volume" or k == "loaded" or k == "applied" or k == "restored" or k == "reverted" then
	self:PushBgmVolume()
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
method number GetVoiceVolume01()
return _SettingsManager:GetVolume01("voice")
end

@ExecSpace("ClientOnly")
method number ScaleSfx(number baseVolume)
-- SoundComponent.Volume에 직접 넣을 값(원래 볼륨 × 설정 비율).
-- 클론해서 재생하는 방식(GachaResultPopup)에서 쓴다.
local base = baseVolume
if base == nil then base = 1 end
return base * self:GetSfxVolume01()
end

@ExecSpace("ClientOnly")
method number ScaleVoice(number baseVolume)
local base = baseVolume
if base == nil then base = 1 end
return base * self:GetVoiceVolume01()
end

@ExecSpace("ClientOnly")
method void PlaySfx(string ruid, number baseVolume)
-- 효과음 재생. 기존 _SoundService:PlaySound(ruid, vol) 자리를 이걸로 바꾼다.
if ruid == nil or ruid == "" then return end
local v = self:ScaleSfx(baseVolume)
if v <= 0 then return end -- 0% = 완전 무음
pcall(function()
	_SoundService:PlaySound(ruid, v)
end)
end

@ExecSpace("ClientOnly")
method void PlayVoice(string ruid, number baseVolume)
if ruid == nil or ruid == "" then return end
local v = self:ScaleVoice(baseVolume)
if v <= 0 then return end
pcall(function()
	_SoundService:PlaySound(ruid, v)
end)
end

@ExecSpace("ClientOnly")
method any PlayBgm(string ruid, number baseVolume)
-- BGM 재생 + 핸들 보관. 재생 중에도 설정이 바뀌면 PushBgmVolume이 반영한다.
self:StopBgm()
if ruid == nil or ruid == "" then
	log("[SoundChannels] BGM RUID 없음 — 무음으로 진행")
	return nil
end

local base = baseVolume
if base == nil then base = 1 end
self.bgmBaseVolume = base

local v = base * self:GetBgmVolume01()
local ok, handle = pcall(function()
	return _SoundService:PlaySound(ruid, v)
end)
if ok == false then
	log("[SoundChannels] BGM 재생 실패(무시)")
	return nil
end

if handle ~= nil then
	self.bgmHandle = { h = handle }
end
log("[SoundChannels] BGM 재생 (볼륨 " .. tostring(v) .. ")")
return handle
end

@ExecSpace("ClientOnly")
method void RegisterBgmHandle(any handle, number baseVolume)
-- 기존 코드가 직접 PlaySound를 호출했을 때, 그 핸들만 넘겨받아 관리한다.
self.bgmHandle = {}
if handle == nil then return end
local base = baseVolume
if base == nil then base = 1 end
self.bgmBaseVolume = base
self.bgmHandle = { h = handle }
self:PushBgmVolume()
end

@ExecSpace("ClientOnly")
method void StopBgm()
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
method void PushBgmVolume()
-- 재생 중인 BGM에 현재 설정 볼륨을 즉시 반영한다.
-- 핸들에 볼륨 필드가 없는 구현이면 다음 재생부터 적용된다.
if self.bgmHandle == nil then return end
local h = self.bgmHandle.h
if h == nil then return end

local v = self.bgmBaseVolume * self:GetBgmVolume01()
local ok = pcall(function()
	h.Volume = v
end)
if ok == false then
	log("[SoundChannels] 재생 중 BGM 볼륨 변경 불가 — 다음 재생부터 적용")
end
end

@ExecSpace("ClientOnly")
method void PreviewSfx()
-- 효과음 슬라이더에서 손을 놓는 순간 1회 재생.
if self.previewSfxRUID == nil or self.previewSfxRUID == "" then
	log("[SoundChannels] previewSfxRUID 미지정 — 미리듣기 생략")
	return
end
self:PlaySfx(self.previewSfxRUID, 1)
end

@ExecSpace("ClientOnly")
method void PreviewVoice()
if self.previewVoiceRUID == nil or self.previewVoiceRUID == "" then
	log("[SoundChannels] previewVoiceRUID 미지정 — 미리듣기 생략")
	return
end
self:PlayVoice(self.previewVoiceRUID, 1)
end

end
