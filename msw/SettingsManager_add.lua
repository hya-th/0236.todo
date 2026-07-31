-- ================================================================
-- SettingsManager에 "추가"할 메서드 2개.
-- 기존 SettingsManager 파일은 그대로 두고, 아무 메서드 사이에 이 두 개만
-- 붙여넣으세요. (파일 전체를 교체하지 마세요)
--
-- 사운드 재생부(_SoundChannels)가 볼륨을 조회할 때 쓴다.
-- draft를 읽는 이유: 슬라이더를 움직이면 즉시 소리에 반영되고,
-- 저장 없이 닫으면 RevertDraftToSaved가 draft를 되돌리므로 소리도 복구된다.
-- (PlayerInputBridge가 키를 draft로 읽는 것과 같은 규칙)
-- ================================================================

@ExecSpace("ClientOnly")
method integer GetVolume(string channel)
if self._T == nil or self._T.draft == nil then return 100 end
local v = self._T.draft.volume[channel]
if v == nil then return 100 end
return v
end

@ExecSpace("ClientOnly")
method number GetVolume01(string channel)
-- 0~100 정수를 실제 재생 볼륨 0.0~1.0으로. 0이면 완전 무음.
return self:GetVolume(channel) / 100
end

@ExecSpace("ClientOnly")
method string GetKeyName(string action)
-- 게임플레이 코드가 쓰는 키 조회. 하드코딩된 KeyboardKey 비교 대신 이걸 쓴다.
-- 예) BattleInput에서 _SettingsManager:GetKeyName("BeatLeft")
if self._T == nil or self._T.draft == nil then return "" end
local v = self._T.draft.keys[action]
if v == nil then return "" end
return v
end
