@Logic
script SoundManager extends Logic

-- ================================================================
-- BGM / 효과음 2채널 볼륨 관리. 전역이므로 _SoundManager 로 접근한다.
-- 사운드 API 호출은 RhythmGameManager와 같은 방식으로 pcall로 감싼다
-- (실패해도 게임이 멈추지 않게).
-- ================================================================

property number bgmVolume01 = 0.5 -- 0.0~1.0
property number sfxVolume01 = 0.5 -- 0.0~1.0
property boolean sfxMuted = false -- 0%면 재생 자체를 건너뛴다
property table bgmHandle = {} -- 재생 중인 BGM 핸들(RegisterBgmHandle로 받음)
property string previewSfxRUID = "" -- 효과음 슬라이더 미리듣기용 샘플. 에디터에서 지정

@ExecSpace("ClientOnly")
method void ApplyVolumes(integer bgm, integer sfx)
self:SetBgmVolume(bgm)
self:SetSfxVolume(sfx)
end

@ExecSpace("ClientOnly")
method number ToUnit(any value0to100)
local v = (tonumber(value0to100) or 0) / 100
if v < 0 then v = 0 end
if v > 1 then v = 1 end
return v
end

@ExecSpace("ClientOnly")
method void SetBgmVolume(integer value0to100)
self.bgmVolume01 = self:ToUnit(value0to100)
self:PushBgmVolume()
end

@ExecSpace("ClientOnly")
method void SetSfxVolume(integer value0to100)
-- 0%는 완전 무음: 볼륨 0으로 재생하지 않고 재생을 건너뛴다.
self.sfxVolume01 = self:ToUnit(value0to100)
self.sfxMuted = (self.sfxVolume01 <= 0)
end

@ExecSpace("ClientOnly")
method void RegisterBgmHandle(any handle)
-- RhythmGameManager의 PlayBGM이 얻은 핸들을 넘겨주면,
-- 재생 중에도 슬라이더로 볼륨을 바꿀 수 있다.
self.bgmHandle = {}
if handle == nil then return end
self.bgmHandle = { h = handle }
self:PushBgmVolume()
end

@ExecSpace("ClientOnly")
method void ClearBgmHandle()
self.bgmHandle = {}
end

@ExecSpace("ClientOnly")
method void PushBgmVolume()
-- 재생 중인 BGM에 볼륨을 즉시 반영해 본다.
-- 핸들에 볼륨 필드가 없는 경우에는 다음 PlaySound부터 적용된다
-- (RhythmGameManager의 PlayBGM이 _SettingsManager에서 볼륨을 읽어가므로).
local h = nil
if self.bgmHandle ~= nil then h = self.bgmHandle.h end
if h == nil then return end

local volume = self.bgmVolume01
local ok = pcall(function()
	h.Volume = volume
end)
if ok == false then
	log("[SoundManager] 재생 중 BGM 볼륨 변경 불가 — 다음 재생부터 적용")
end
end

@ExecSpace("ClientOnly")
method void PlaySfx(string ruid)
-- 게임 안의 모든 효과음은 이 함수를 거쳐야 볼륨 설정이 적용된다.
if self.sfxMuted then return end
if ruid == nil or ruid == "" then return end

local volume = self.sfxVolume01
local ok = pcall(function()
	_SoundService:PlaySound(ruid, volume)
end)
if ok == false then
	log("[SoundManager] 효과음 재생 실패(무시): " .. tostring(ruid))
end
end

@ExecSpace("ClientOnly")
method void PreviewSfx()
-- 효과음 슬라이더에서 손을 놓는 순간 1회 재생해 크기를 확인시켜 준다.
if self.previewSfxRUID == nil or self.previewSfxRUID == "" then
	log("[SoundManager] previewSfxRUID 미지정 — 미리듣기 생략")
	return
end
self:PlaySfx(self.previewSfxRUID)
end

end
