@Component
script BeatTrigger extends Component

-- ================================================================
-- 꼭짓점 판정 네모에 부착. 도는 네모(BeatRunner)가 오차범위(hitRadius) 안으로
-- 들어오는 순간 쿵 소리 + 점멸 오브젝트를 잠깐 켠다.
--
-- 원본에서 달라진 곳은 두 군데뿐이다.
--   (1) OnUpdate 첫 줄: 러너가 멈춰 있으면(일시정지 포함) 아무것도 하지 않음
--   (2) OnHit: _SoundService 직접 호출 → _SoundChannels:PlaySfx
--              (설정의 효과음 볼륨이 먹고, 정지 중에는 소리가 나지 않는다)
-- ================================================================

property Entity runner = nil
property Entity flashObject = nil
property number hitRadius = 15
property string soundRUID = "41bf0f6f8d4945958183f7fca798a226"
property number volume = 0.6
property number flashDuration = 0.5
property boolean isInside = false
property number flashTimeLeft = 0

@ExecSpace("ClientOnly")
method void OnBeginPlay()
if self.runner == nil then
	log("[BeatTrigger] runner(도는 네모)가 연결 안 됨 — 에디터에서 연결하세요")
end
if self.flashObject ~= nil then
	self.flashObject.Enable = false
end
end

@ExecSpace("ClientOnly")
method void OnUpdate(number delta)
-- [추가] 러너가 멈춰 있으면 점멸 카운트다운도 멈춘다.
-- 일시정지 중에 남은 점멸이 혼자 꺼져 버리는 것을 막는다.
local runner = self.runner
if runner == nil then return end
local br = runner.BeatRunner
if br ~= nil and br.isMoving == false then return end

if self.flashTimeLeft > 0 then
	self.flashTimeLeft = self.flashTimeLeft - delta
	if self.flashTimeLeft <= 0 and self.flashObject ~= nil then
		self.flashObject.Enable = false
	end
end

local rp = runner.TransformComponent.Position
local mp = self.Entity.TransformComponent.Position
local dx = rp.x - mp.x
local dy = rp.y - mp.y
local dist = math.sqrt(dx * dx + dy * dy)

if dist <= self.hitRadius then
	if self.isInside == false then
		self.isInside = true
		self:OnHit()
	end
else
	self.isInside = false
end
end

@ExecSpace("ClientOnly")
method void OnHit()
-- [변경] 설정 볼륨을 타고, 일시정지 중에는 울리지 않는다
if self.soundRUID ~= "" then
	_SoundChannels:PlaySfx(self.soundRUID, self.volume)
end
if self.flashObject ~= nil then
	self.flashObject.Enable = true
	self.flashTimeLeft = self.flashDuration
end
end

@ExecSpace("ClientOnly")
method void OnEndPlay()
if self.flashObject ~= nil then
	self.flashObject.Enable = false
end
end

end
