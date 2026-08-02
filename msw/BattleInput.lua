@Component
script BattleInput extends Component

-- ================================================================
-- 원본에서 달라진 곳은 네 군데뿐이다.
--   (1) 메서드 추가: KeyOf  — 설정에 저장된 키 이름을 KeyboardKey 값으로
--   (2) HandleKeyDownEvent : 화살표 하드코딩 → KeyOf로 설정 키 비교
--   (3) OnUpdate 첫 줄     : 일시정지 중이면 마크 수명/동시입력 창도 멈춤
--   (4) PlayHitSound       : _SoundService 직접 호출 → _SoundChannels:PlaySfx
-- 나머지는 원본 그대로다.
--
-- 설정에서 "1번 입력"을 A로 바꾸면 draft.keys.BeatLeft = "A"가 되고,
-- 아래 KeyOf가 그 값을 매 입력마다 읽으므로 즉시 A로 조작된다.
--   BeatLeft = 1번 입력 / BeatRight = 2번 입력 / BeatConfirm = 확인
-- ================================================================

property Entity runner = nil -- BeatRunner(도는 네모) 엔티티. 드래그 연결
property Entity manager = nil -- RhythmGameManager 엔티티. 비우면 managerTag로 자동 연결
property string managerTag = "rhythmmanager" -- manager 자동 연결용 태그
property string triggerTag = "beattrigger" -- 온비트 판정 영역(BeatTrigger) 태그
property string successMarkModel = "model://1a9ad540-fd66-4d0b-b0eb-c515305ca8c8" -- 성공 마크 공통 모델(스폰 후 키별 스프라이트로 교체)
property string missMarkModel = "model://582f5643-e452-4d34-972b-09234bc51c9b" -- 실패 마크 모델(스프라이트 교체 없이 그대로)
property string markKey1 = "495aa8bf35f443cfaec3ab0353f06cd6" -- 왼쪽키(1) 성공 마크 스프라이트
property string markKey2 = "950bef171a994f1689b01ef9568d39b6" -- 오른쪽키(2) 성공 마크 스프라이트
property string markKey3 = "5d85238bfad14990b3528a7d37c0ce5c" -- 왼+오른(3) 성공 마크 스프라이트
property string markKey4 = "0f385cfa3bd24ad4af67fe2f950925ec" -- 아래키(4) 성공 마크 스프라이트
property string successEffect = "358cba6918d24d2e97e4c081002b8160" -- 성공 이펙트 스프라이트(공통 모델 successMarkModel에 교체, 스케일 0→1 후 파괴)
property string hitSound = "" -- 성공 시 재생할 사운드 RUID(넣으면 재생)
property number hitSoundVolume = 1 -- 성공 사운드 볼륨
property integer effectSteps = 10 -- 성공 이펙트 스케일 애니 단계 수
property number effectStepTime = 0.02 -- 성공 이펙트 스케일 단계 간격(초)
property Entity spawnParent = nil -- 마크가 붙을 부모. 비우면 러너의 부모
property number missLifetime = 0.5 -- 실패 마크 수명(초)
property table marks = {} -- 살아있는 마크 목록 {entity=, timeLeft=}
property Entity character = nil -- 공격 애니를 재생할 캐릭터. 비우면 LocalPlayer
property string attackState = "ATTACK" -- 공격 상태 이름
property string idleState = "IDLE" -- 대기 상태 이름
property number attackDuration = 0.4 -- 공격 애니 유지 시간(초)
property number attackTimeLeft = 0 -- 공격 애니 남은 시간(런타임)
property table candidates = {} -- 추적 중인 커맨드 후보 {id=, active=8자리, progress=}
property integer maxCandidates = 3 -- 동시에 추적할 스킬 수
property number simultaneousWindow = 0.12 -- 동시입력(키3) 허용 시간(초)
property integer pendingKey = 0 -- 확정 대기 중인 키(0=없음)
property number pendingTimeLeft = 0 -- 동시입력 판정 남은 시간(초)
property integer lastBeat = -99 -- 마지막으로 처리한 절대 박 번호(-99=미시작)
property boolean curBeatHandled = false -- 현재 박에 이미 입력을 소비했는지
property integer comboStartBeat = -99 -- 콤보 첫 입력의 절대 박(상대 박 기준). -99=콤보 미시작
property number perfectRatio = 0.6 -- 박 중심 근접도가 이 이상이면 퍼펙트(완화)
property number beatWindow = 0.42 -- 온비트 판정 여유(박의 ±비율, 0~0.5). 클수록 관대
property number comboMarkLife = 999 -- 콤보(성공) 마크 유지 수명. 커맨드 완성/실패 때 제거되므로 크게 둠
property number effectMaxScale = 1.6 -- 성공 이펙트 최대 스케일(0→이 값까지 커짐)

@ExecSpace("ClientOnly")
method void OnBeginPlay()
if self.manager == nil then
	self.manager = _EntityService:GetEntityByTag(self.managerTag)
	if self.manager == nil then
		log("[BattleInput] 태그 '" .. self.managerTag .. "' 로 RhythmGameManager 엔티티를 못 찾음 — 에디터에서 manager 슬롯을 직접 연결하세요")
	else
		log("[BattleInput] manager 자동 연결 완료")
	end
end
end

@ExecSpace("ClientOnly")
method void RefreshCandidates()
-- ==============================================================
-- 보유 스킬(최대 maxCandidates개)을 커맨드 후보로 등록.
-- 스킬을 '선택'하는 게 아니라, 등록된 후보를 전부 동시에 추적하다가
-- 내가 친 패턴과 맞는 스킬이 완성되면 그게 발동된다.
-- 전투 시작 시 RhythmGameManager가 호출.
-- ==============================================================
self.candidates = {}

local lp = _UserService.LocalPlayer
if lp == nil or lp.PlayerData == nil then
	log("[BattleInput] LocalPlayer/PlayerData 없음 — 커맨드 후보 없음")
	return
end

-- 보유 스킬 목록(JSON 배열 문자열) — 깨져도 터지지 않게 pcall
local skills = {}
local str = lp.PlayerData.ownedSkillsStr
if str ~= nil and str ~= "" then
	local ok, decoded = pcall(function() return _HttpService:JSONDecode(str) end)
	if ok and type(decoded) == "table" then
		skills = decoded
	else
		log("[BattleInput] ownedSkills 파싱 실패")
	end
end

local ds = _DataService:GetTable("SkillData")
if ds == nil then
	log("[BattleInput] SkillData 테이블 없음")
	return
end

local seen = {}
for i = 1, #skills do
	if #self.candidates >= self.maxCandidates then break end

	local id = tostring(skills[i])
	-- 같은 스킬이 여러 개 있어도 커맨드는 하나만 등록
	if id ~= "" and seen[id] == nil then
		seen[id] = true
		local row = ds:FindRow("Id", id)
		if row ~= nil then
			local s = tostring(row:GetItem("SkillActive"))
			-- 8자리 보정: 짧으면 뒤를 0(쉬는 박)으로, 길면 자른다
			while string.len(s) < 8 do s = s .. "0" end
			if string.len(s) > 8 then s = string.sub(s, 1, 8) end

			table.insert(self.candidates, { id = id, active = s, progress = 0, lastActive = self:GetLastActive(s) })
			log("[BattleInput] 커맨드 등록: " .. id .. " = " .. s)
		else
			log("[BattleInput] SkillData에 '" .. id .. "' 없음 — 건너뜀")
		end
	end
end

log("[BattleInput] 커맨드 후보 " .. tostring(#self.candidates) .. "개")
end

@ExecSpace("ClientOnly")
method void SetCandidates(table idList)
-- ==============================================================
-- 지정한 스킬 Id 목록(StageSelect에서 고른 것)을 커맨드 후보로 등록.
-- 각 후보는 동시에 추적되고, 친 패턴과 맞는 스킬이 완성되면 발동.
-- ==============================================================
self.candidates = {}
if idList == nil then
	log("[BattleInput] SetCandidates: 목록 없음")
	return
end

local ds = _DataService:GetTable("SkillData")
if ds == nil then
	log("[BattleInput] SkillData 테이블 없음")
	return
end

local seen = {}
for i = 1, #idList do
	if #self.candidates >= self.maxCandidates then break end
	local id = tostring(idList[i])
	if id ~= "" and seen[id] == nil then
		seen[id] = true
		local row = ds:FindRow("Id", id)
		if row ~= nil then
			local s = tostring(row:GetItem("SkillActive"))
			while string.len(s) < 8 do s = s .. "0" end
			if string.len(s) > 8 then s = string.sub(s, 1, 8) end
			table.insert(self.candidates, { id = id, active = s, progress = 0, lastActive = self:GetLastActive(s) })
			log("[BattleInput] 커맨드 등록: " .. id .. " = " .. s)
		else
			log("[BattleInput] SkillData에 '" .. id .. "' 없음 — 건너뜀")
		end
	end
end
log("[BattleInput] 커맨드 후보 " .. tostring(#self.candidates) .. "개 (선택 스킬)")
end

@ExecSpace("ClientOnly")
method integer GetLastActive(string active)
-- 마지막 0이 아닌 박 인덱스 = 커맨드 실제 길이. 뒤쪽 0(쉼)은 안 기다린다.
local last = 0
for k = 1, 8 do
	if string.sub(active, k, k) ~= "0" then last = k end
end
return last
end

@ExecSpace("ClientOnly")
method boolean AnyMatch(integer beatIndex, integer key)
-- beatIndex 박에서 key를 요구하는 후보가 하나라도 있는가(마크 성공/실패 표시용)
if beatIndex < 1 or beatIndex > 8 then return false end
for _, c in ipairs(self.candidates) do
	local req = tonumber(string.sub(c.active, beatIndex, beatIndex)) or 0
	if req == key then return true end
end
return false
end

@ExecSpace("ClientOnly")
method void ResetCombo(string reason)
-- 모든 후보의 진행도 + 콤보 시작점 초기화. 진행 중이던 게 있을 때만 로그.
local had = 0
for _, c in ipairs(self.candidates) do
	if c.progress > had then had = c.progress end
	c.progress = 0
end
self.comboStartBeat = -99
self:FadeComboMarks()   -- 리셋되면 콤보 마크도 곧 사라지게
if had > 0 then
	log("[BattleInput] 커맨드 리셋 (" .. tostring(reason) .. ", 최대 " .. tostring(had) .. "박에서 끊김)")
end
end

@ExecSpace("ClientOnly")
method string JudgeBeat(integer beatIndex, integer key)
-- ==============================================================
-- beatIndex 박을 key(0=입력없음, 1/2/3)로 판정.
-- 후보 전체를 각각 진행/리셋하고, 8박을 채운 스킬 Id를 반환("" = 없음).
--   · 요구 키와 일치 → 진행 (박 인덱스가 이어질 때만)
--   · 불일치 → 그 후보만 리셋
-- 쉬는 박(0)은 "안 친 게 정답"이라 입력 없이도 진행된다.
-- ==============================================================
local fired = ""
if beatIndex < 1 or beatIndex > 8 then return fired end

for _, c in ipairs(self.candidates) do
	local req = tonumber(string.sub(c.active, beatIndex, beatIndex)) or 0

	if req == key then
		-- 패턴은 절대 박에 고정 → 진행도와 박 인덱스가 이어져야 인정
		if beatIndex == c.progress + 1 then
			c.progress = c.progress + 1
		elseif beatIndex == 1 then
			c.progress = 1
		else
			c.progress = 0
		end

		-- 마지막 유효 박까지 채우면 발동(뒤쪽 쉼 박은 안 기다림)
		if c.lastActive ~= nil and c.lastActive > 0 and c.progress >= c.lastActive then
			if fired == "" then fired = c.id end
			c.progress = 0
		end
	else
		c.progress = 0
	end
end

return fired
end

@ExecSpace("ClientOnly")
method void CloseBeat(integer beat)
-- 입력 없이 지나간 박 마감(절대박 → 상대박 변환). 콤보 미시작이면 무시.
if self.comboStartBeat == -99 then return end
local relBeat = beat - self.comboStartBeat + 1
if relBeat < 1 then return end
if relBeat > 8 then
	self:ResetCombo("8박 초과")
	return
end
local fired = self:JudgeBeat(relBeat, 0)
if fired ~= "" then
	self:Attack(fired)
end
end

@ExecSpace("ClientOnly")
method void AdvanceBeats()
-- ==============================================================
-- 러너의 현재 박까지 따라잡으며 지나간 박들을 마감한다.
-- OnUpdate와 입력 확정 시점 양쪽에서 호출 → 프레임 경계에서
-- 박이 넘어가도 입력이 엉뚱한 박에 붙지 않는다.
-- ==============================================================
if self.runner == nil then return end
local br = self.runner.BeatRunner
if br == nil then return end

-- 러너 정지 중엔 판정 중단 + 진행도 초기화
if br.isMoving == false then
	if self.lastBeat ~= -99 then
		self:ResetCombo("러너 정지")
		self.lastBeat = -99
		self.curBeatHandled = false
	end
	return
end

local beat = br:GetCurrentBeat()

-- 첫 진입: 기준만 잡고 시작
if self.lastBeat == -99 then
	self.lastBeat = beat
	self.curBeatHandled = false
	self:ResetCombo("시작")
	return
end

-- 러너 재시작(elapsed 리셋)으로 박이 되감김
if beat < self.lastBeat then
	self:ResetCombo("러너 재시작")
	self.lastBeat = beat
	self.curBeatHandled = false
	return
end

if beat > self.lastBeat then
	-- 지나간 박들을 순서대로 마감. 입력으로 이미 처리한 박은 건너뜀
	local b = self.lastBeat
	while b < beat do
		if not (b == self.lastBeat and self.curBeatHandled) then
			self:CloseBeat(b)
		end
		b = b + 1
	end
	self.lastBeat = beat
	self.curBeatHandled = false
end
end

@ExecSpace("ClientOnly")
method void OnUpdate(number delta)
-- [추가] 일시정지 중에는 마크 수명도, 동시입력 판정 창도 흐르지 않는다.
-- (박 판정은 아래 AdvanceBeats가 br.isMoving == false에서 이미 멈춘다)
if _PauseManager:IsPaused() then return end

-- ==============================================================
-- 1) 마크 수명 관리
-- ==============================================================
for i = #self.marks, 1, -1 do
	local m = self.marks[i]
	m.timeLeft = m.timeLeft - delta
	if m.timeLeft <= 0 then
		if m.entity ~= nil and _EntityService:IsValid(m.entity) then
			m.entity:Destroy()
		end
		table.remove(self.marks, i)
	end
end

-- ==============================================================
-- 2) 동시입력(키3) 판정: window가 지나면 단독 입력으로 확정
-- ==============================================================
if self.pendingKey ~= 0 then
	self.pendingTimeLeft = self.pendingTimeLeft - delta
	if self.pendingTimeLeft <= 0 then
		local k = self.pendingKey
		self.pendingKey = 0
		self.pendingTimeLeft = 0
		self:ConfirmInput(k)
	end
end

-- ==============================================================
-- 3) 박 진행 따라잡기 (입력 없이 지나간 박 마감)
-- ==============================================================
self:AdvanceBeats()

-- ==============================================================
-- 4) 공격 애니 종료 → IDLE 복귀
-- ==============================================================
if self.attackTimeLeft > 0 then
	self.attackTimeLeft = self.attackTimeLeft - delta
	if self.attackTimeLeft <= 0 then
		local char = self.character
		if char == nil then char = _UserService.LocalPlayer end
		if char ~= nil and char.StateComponent ~= nil then
			char.StateComponent:ChangeState(self.idleState)
		end
	end
end
end

@ExecSpace("ClientOnly")
method void PressKey(integer key)
-- ==============================================================
-- 왼(1)/오른(2) 입력 접수. 즉시 처리하지 않고 pending에 담아 둔다.
--  - 대기 중인 키가 없으면 → pending에 넣고 window 시작
--  - window 안에 '다른' 키가 오면 → 앞 입력 취소하고 키3(동시)으로 즉시 확정
--  - 같은 키가 또 오면 → 무시(키 반복 입력 방지)
-- (아래=키4는 여기 안 오고 KeyDownEvent에서 바로 ConfirmInput)
-- ==============================================================
if key ~= 1 and key ~= 2 then return end
if not self:IsBattleOn() then return end

if self.pendingKey == 0 then
	self.pendingKey = key
	self.pendingTimeLeft = self.simultaneousWindow
	return
end

if self.pendingKey ~= key then
	-- 동시 입력 성립 → 앞 입력은 버리고 키3으로
	self.pendingKey = 0
	self.pendingTimeLeft = 0
	self:ConfirmInput(3)
end
end

@ExecSpace("ClientOnly")
method void ConfirmInput(integer key)
-- ==============================================================
-- 확정된 키(1/2/3) 하나를 현재 박에 대고, 후보 전체에 판정한다.
-- ==============================================================
if not self:IsBattleOn() then return end

if self.runner == nil then
	log("[BattleInput] runner 연결 안 됨")
	return
end
local br = self.runner.BeatRunner
if br == nil then
	log("[BattleInput] runner에 BeatRunner 없음")
	return
end

-- 스폰 위치/부모 (러너와 같은 부모에 붙여 좌표계 일치)
local p = self.runner.TransformComponent.Position
local spawnPos = Vector3(p.x, p.y, p.z)
local parent = self.spawnParent
if parent == nil then parent = self.runner.Parent end
if parent == nil then parent = self.Entity end

-- 온비트 영역 밖 입력: 틀림 마크만, 판정 안 함(콤보 유지).
if self:IsOnBeat() == false then
	self:SpawnMark(self.missMarkModel, "", spawnPos, parent, self.missLifetime, false)
	return
end

-- 온비트: 박을 따라잡고 '상대 박' 계산 (첫 입력 = 1박)
self:AdvanceBeats()
local beat = br:GetCurrentBeat()

local relBeat
if self.comboStartBeat == -99 then
	self.comboStartBeat = beat
	relBeat = 1
else
	relBeat = beat - self.comboStartBeat + 1
	if relBeat < 1 or relBeat > 8 then
		-- 콤보 범위를 벗어나면 이 입력을 새 콤보의 1박으로
		self.comboStartBeat = beat
		relBeat = 1
	end
end
self.curBeatHandled = true

-- 온비트 입력이면 친 키의 성공 마크(맞는 스프라이트)를 '항상' 띄운다(콤보 마크).
-- 커맨드에 맞든 틀리든 일단 표시하고, 판정은 아래에서.
self:SpawnMark(self.successMarkModel, self:GetMarkSprite(key), spawnPos, parent, self.comboMarkLife, true)
self:SpawnSuccessEffect(spawnPos, parent)
self:PlayHitSound()
local acc = self:GetAccuracy()
if acc >= self.perfectRatio then
	log("[BattleInput] " .. tostring(relBeat) .. "박 키" .. tostring(key) .. " PERFECT")
else
	log("[BattleInput] " .. tostring(relBeat) .. "박 키" .. tostring(key))
end

-- 판정: 후보 진행 + 완성/실패 처리
local fired = self:JudgeBeat(relBeat, key)
if fired ~= "" then
	-- 커맨드 완성 → 콤보 마크 한 번에 즉시 제거(쑥쑥) + 발동
	self:ClearComboMarks()
	self:Attack(fired)
	self.comboStartBeat = -99
else
	-- 이어지는 후보가 하나도 없으면 틀린 것처럼 콤보 마크를 짧게 제거 + 리셋
	local anyProgress = false
	for _, c in ipairs(self.candidates) do
		if c.progress > 0 then
			anyProgress = true
			break
		end
	end
	if not anyProgress then
		self:FadeComboMarks()
		self:ResetCombo("이어지는 커맨드 없음")
	end
end
end

@ExecSpace("ClientOnly")
method string GetMarkSprite(integer key)
-- 입력 키(1왼/2오른/3동시/4아래)에 맞는 성공 마크 스프라이트 RUID
if key == 1 then return self.markKey1 end
if key == 2 then return self.markKey2 end
if key == 3 then return self.markKey3 end
if key == 4 then return self.markKey4 end
return ""
end

@ExecSpace("ClientOnly")
method void SpawnMark(string model, string sprite, Vector3 pos, Entity parent, number lifetime, boolean isCombo)
-- 마크 모델 스폰 후 sprite 있으면 ImageRUID 교체. isCombo=콤보(성공) 마크 여부.
if model == nil or model == "" then return end
local mid = model
if string.sub(mid, 1, 8) ~= "model://" then mid = "model://" .. model end

local ok, mark = pcall(function()
	return _SpawnService:SpawnByModelId(mid, "Mark", pos, parent)
end)
if ok and mark ~= nil then
	if sprite ~= nil and sprite ~= "" then
		local sr = mark.SpriteGUIRendererComponent
		if sr ~= nil then
			sr.ImageRUID = sprite
		else
			log("[BattleInput] 마크에 SpriteGUIRendererComponent 없음 — 스프라이트 교체 실패")
		end
	end
	table.insert(self.marks, { entity = mark, timeLeft = lifetime, isCombo = isCombo })
end
end

@ExecSpace("ClientOnly")
method void SpawnSuccessEffect(Vector3 pos, Entity parent)
-- 성공 시 그 칸에 이펙트: 공통 모델(successMarkModel) 스폰 → 스프라이트(successEffect) 교체 → 스케일 0→1 → 파괴.
local model = self.successMarkModel
if model == nil or model == "" then return end
local mid = model
if string.sub(mid, 1, 8) ~= "model://" then mid = "model://" .. model end

local ok, eff = pcall(function()
	return _SpawnService:SpawnByModelId(mid, "HitEffect", pos, parent)
end)
if not ok or eff == nil then return end

-- 스프라이트 교체(successEffect = 스프라이트 RUID, UI)
if self.successEffect ~= nil and self.successEffect ~= "" and eff.SpriteGUIRendererComponent ~= nil then
	eff.SpriteGUIRendererComponent.ImageRUID = self.successEffect
end

-- 스케일 0 → effectMaxScale (UI)
local ut = eff.UITransformComponent
if ut ~= nil then
	ut.UIScale = Vector3(0, 0, 0)
	for i = 1, self.effectSteps do
		if not _EntityService:IsValid(eff) then return end
		local s = (i / self.effectSteps) * self.effectMaxScale
		ut.UIScale = Vector3(s, s, s)
		wait(self.effectStepTime)
	end
end

if _EntityService:IsValid(eff) then
	eff:Destroy()
end
end

@ExecSpace("ClientOnly")
method void PlayHitSound()
-- 성공 시 사운드 재생(RUID 있으면). 실패해도 무시.
if self.hitSound == nil or self.hitSound == "" then return end
-- [변경] 설정의 효과음 볼륨을 타고, 일시정지 중에는 울리지 않는다
_SoundChannels:PlaySfx(self.hitSound, self.hitSoundVolume)
end

@ExecSpace("ClientOnly")
method void ClearComboMarks()
-- 콤보(성공) 마크를 즉시 전부 제거 (커맨드 완성 시 한 번에 쑥쑥).
for i = #self.marks, 1, -1 do
	local m = self.marks[i]
	if m.isCombo == true then
		if m.entity ~= nil and _EntityService:IsValid(m.entity) then
			m.entity:Destroy()
		end
		table.remove(self.marks, i)
	end
end
end

@ExecSpace("ClientOnly")
method void FadeComboMarks()
-- 콤보 마크를 곧 사라지게(틀린 것처럼 짧은 수명). 커맨드 이어짐이 끊길 때.
for _, m in ipairs(self.marks) do
	if m.isCombo == true then
		m.timeLeft = self.missLifetime
	end
end
end

@ExecSpace("ClientOnly")
method boolean IsBattleOn()
-- 전투 중일 때만 입력을 처리한다.
-- (전투 종료 후 러너가 트리거 안에 멈춰 있으면 IsOnBeat가 계속 true라
--  메인 화면에서도 마크가 스폰되던 문제 방지)
if self.manager == nil then return false end
local mgr = self.manager.RhythmGameManager
if mgr == nil then return false end
return mgr.hasStarted == true
end

@ExecSpace("ClientOnly")
method boolean IsOnBeat()
-- 위치(BeatTrigger) 대신 시간으로 온비트 판정 — 훨씬 관대하고 조정 쉬움.
-- 박 경계(정수 박)에서 ±beatWindow 이내면 온비트.
if self.runner == nil then return false end
local br = self.runner.BeatRunner
if br == nil then return false end
if br.isMoving == false then return false end
local beatInterval = 60 / br.bpm
if beatInterval <= 0 then return false end
local phase = (br.elapsed / beatInterval) % 1   -- 박 내 위치 0~1
if phase <= self.beatWindow or phase >= (1 - self.beatWindow) then
	return true
end
return false
end

@ExecSpace("ClientOnly")
method number GetAccuracy()
-- 박 중심과의 시간 근접도(0~1). 1=박 정확, 0=beatWindow 끝.
if self.runner == nil then return 0 end
local br = self.runner.BeatRunner
if br == nil then return 0 end
local beatInterval = 60 / br.bpm
if beatInterval <= 0 then return 0 end
local phase = (br.elapsed / beatInterval) % 1
-- 박 경계(0 또는 1)까지의 최소 거리 0~0.5
local dist = phase
if (1 - phase) < dist then dist = 1 - phase end
if self.beatWindow <= 0 then return 0 end
local acc = 1 - dist / self.beatWindow
if acc < 0 then acc = 0 end
if acc > 1 then acc = 1 end
return acc
end

@ExecSpace("ClientOnly")
method void RemoveMark(Entity target)
-- 마크를 목록에서 빼고 즉시 제거
if target == nil then return end
for i = #self.marks, 1, -1 do
	if self.marks[i].entity == target then
		table.remove(self.marks, i)
		break
	end
end
if _EntityService:IsValid(target) then
	target:Destroy()
end
end

@ExecSpace("ClientOnly")
method void ClearMarks()
-- 남아있는 마크 전부 제거 (전투 종료 시)
for i = #self.marks, 1, -1 do
	local m = self.marks[i]
	if m.entity ~= nil and _EntityService:IsValid(m.entity) then
		m.entity:Destroy()
	end
	table.remove(self.marks, i)
end
end

@ExecSpace("ClientOnly")
method void Attack(string skillId)
-- ==============================================================
-- 커맨드 완성 → 캐릭터 공격 애니 + 매니저에 그 스킬로 공격 통보
-- ==============================================================
if skillId == nil or skillId == "" then return end
log("[BattleInput] *** 커맨드 성공! " .. tostring(skillId) .. " 발동 ***")

local char = self.character
if char == nil then char = _UserService.LocalPlayer end
if char ~= nil then
	local st = char.StateComponent
	if st ~= nil then
		st:ChangeState(self.attackState)
		self.attackTimeLeft = self.attackDuration
	else
		log("[BattleInput] 캐릭터에 StateComponent 없음 — 애니 재생 불가")
	end
end

if self.manager == nil then
	log("[BattleInput] manager(RhythmGameManager 엔티티) 연결 안 됨 — 공격 전달 불가")
	return
end
local mgr = self.manager.RhythmGameManager
if mgr ~= nil then
	mgr:PlayerAttack(skillId)
else
	log("[BattleInput] manager에 RhythmGameManager 컴포넌트 없음")
end
end

@ExecSpace("ClientOnly")
method any KeyOf(string action, any fallback)
-- [추가] 설정에 저장된 키 이름("A", "LeftArrow" ...)을 KeyboardKey 값으로 바꾼다.
-- 설정이 아직 로드되기 전이거나 이름이 이상하면 원래 기본키(fallback)를 쓴다.
local name = ""
local okName = pcall(function()
	name = _SettingsManager:GetKeyName(action)
end)
if okName == false then return fallback end
if name == nil then return fallback end
if name == "" then return fallback end

local key = nil
local okKey = pcall(function()
	key = KeyboardKey.CastFrom(name)
end)
if okKey == false then return fallback end
if key == nil then return fallback end
return key
end

@ExecSpace("Client")
@EventSender("Service", "InputService")
handler HandleKeyDownEvent(KeyDownEvent event)
-- [변경] 설정에서 지정한 키로 판정한다(원본은 화살표 하드코딩).
--   1번 입력 = 키1(왼쪽), 2번 입력 = 키2(오른쪽), 확인 = 키4
--   키1과 키2를 simultaneousWindow 안에 같이 누르면 키3(동시)
local k = event.key
if k == self:KeyOf("BeatLeft", KeyboardKey.LeftArrow) then
	self:PressKey(1)
elseif k == self:KeyOf("BeatRight", KeyboardKey.RightArrow) then
	self:PressKey(2)
elseif k == self:KeyOf("BeatConfirm", KeyboardKey.DownArrow) then
	self:ConfirmInput(4)
end
end

end
