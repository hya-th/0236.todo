@Component
script RhythmGameManager extends Component

-- ================================================================
-- 원본에서 달라진 곳은 다섯 군데뿐이다.
--   (1) 프로퍼티 4개 추가: battlePaused / stopBgmWhilePaused / pauseHandler / escExitsBattle
--   (2) OnBeginPlay 첫 줄: PauseStateChangedEvent 구독
--   (3) OnUpdate 두 번째 줄: 정지 중이면 아무것도 하지 않음
--   (4) 메서드 3개 추가: OnBattlePauseChanged / PauseBattle / ResumeBattle
--   (5) HandleKeyDownEvent: ESC로 전투를 끝낼지 프로퍼티로 선택(기본 끔)
-- 나머지는 원본 그대로다.
-- ================================================================

property string stageId = "Stage_1-1"
property Entity character = nil -- 플레이어 캐릭터(비우면 LocalPlayer)
property Entity enemyEntity = nil -- 미리 배치한 몬스터 표시 엔티티(SpriteRenderer). 드래그 연결
property number enemyMaxHP = 100
property number enemyHP = 100
property number playerMaxHP = 100
property number playerHP = 100
property string monsterId = ""
property string attackEffectRUID = ""
property string hitEffectRUID = ""
property string deathEffectRUID = ""
property string monsterSpriteRUID = ""
property number animDuration = 0.3
property number hpMultiplier = 1
property number attackMultiplier = 1
property number attackInterval = 0
property number defaultAttackInterval = 3
property number attackTimer = 0
property table patterns = {}
property number defaultSkillDamage = 5
property number stageTime = 0
property number timeLeft = 0
property string bgmRUID = ""
property number bpm = 112.3
property table bgmHandle = {}
property number bgmVolume = 1
property number cameraZoom = 150
property number cameraOffsetX = 1.11
property number cameraOffsetY = 0.43
property Entity gameUI = nil -- GameUI 컴포넌트가 붙은 엔티티. 드래그 연결
property Entity runner = nil -- BeatRunner(도는 네모). 드래그 연결
property boolean hasStarted = false

-- [추가] 일시정지 연동
property boolean battlePaused = false -- 정지 중이면 OnUpdate가 아무것도 하지 않는다
property boolean stopBgmWhilePaused = true -- 정지 시 BGM을 끄고, 재개 시 비트와 함께 처음부터
property boolean escExitsBattle = false -- ESC로 전투를 즉시 끝낼지(설정 팝업과 겹치므로 기본 끔)
property any pauseHandler = nil

property Entity gameUIGroupEntity = nil -- 전투 UI 그룹
property Entity rythemSoloGroupEntity = nil -- 리듬 UI 그룹
property Entity mainScreenEntity = nil -- 전투 종료 시 복귀할 메인 화면
property Entity skillSlotUI = nil -- SkillSlotUI가 붙은 엔티티. 전투 시작 시 보유 스킬 배치
property Entity battleInput = nil -- BattleInput이 붙은 엔티티. 전투 종료 시 마크 정리
property table selectedSkills = {}
property number buffAttackTime = 0
property number buffAttackAmount = 0
property number buffDefenseTime = 0
property integer buffDefenseCharges = 0
property number buffDefenseAmount = 0
property number buffEvadeTime = 0
property number buffCritTime = 0
property number buffCritChance = 0
property table dots = {}
property boolean markActive = false
property number markDamage = 0
property integer comboCount = 0
property integer comboMax = 5

@ExecSpace("ClientOnly")
method number ToNumber(string v, number def)
-- CSV 셀(문자열)을 숫자로. 빈 칸/비숫자면 def 반환.
if v == nil or v == "" then return def end
local n = tonumber(v)
if n == nil then return def end
return n
end

@ExecSpace("ClientOnly")
method table ParseIdList(string s)
-- "{Pattern_001,Pattern_002}" → { "Pattern_001", "Pattern_002" }
local t = {}
if s == nil or s == "" then return t end
for token in string.gmatch(s, '[^{}(),%s"]+') do
	table.insert(t, token)
end
return t
end

@ExecSpace("ClientOnly")
method number ParseAttack(string s)
-- "{Attack:5, Heal:5}" 에서 Attack 값을 뽑는다.
if s == nil or s == "" then return self.defaultSkillDamage end

local v = string.match(s, "[Aa]ttack%s*[:=]%s*(%-?%d+%.?%d*)")
if v == nil then
	v = string.match(s, "(%-?%d+%.?%d*)")
end
if v == nil then return self.defaultSkillDamage end

local n = tonumber(v)
if n == nil then return self.defaultSkillDamage end
return n
end

@ExecSpace("ClientOnly")
method number CalcOutgoing(number base)
-- 적에게 줄 데미지에 공격버프/크리버프를 반영.
local d = base
if self.buffAttackTime > 0 then d = d + self.buffAttackAmount end
if self.buffCritTime > 0 and math.random() * 100 <= self.buffCritChance then
	d = d * 2
	log("[RhythmGameManager] 크리티컬! (님블바디)")
end
return d
end

@ExecSpace("ClientOnly")
method void PlayerHeal(number amount)
-- 플레이어 HP 회복(최대 초과 없음).
if amount == nil or amount <= 0 then return end
self.playerHP = self.playerHP + amount
if self.playerHP > self.playerMaxHP then self.playerHP = self.playerMaxHP end
self:RefreshUI()
log("[RhythmGameManager] 회복 +" .. tostring(amount) .. " → " .. tostring(self.playerHP))
end

@ExecSpace("ClientOnly")
method void AddDoT(number time, number dps)
-- 도트(지속 데미지) 추가: time초 동안 1초마다 dps.
if dps == nil or dps <= 0 or time == nil or time <= 0 then return end
table.insert(self.dots, { timeLeft = time, dps = dps, tickAccum = 0 })
end

@ExecSpace("ClientOnly")
method void ResetEffects()
-- 전투 시작 시 모든 지속효과/상태 초기화.
self.buffAttackTime = 0
self.buffAttackAmount = 0
self.buffDefenseTime = 0
self.buffDefenseCharges = 0
self.buffDefenseAmount = 0
self.buffEvadeTime = 0
self.buffCritTime = 0
self.buffCritChance = 0
self.dots = {}
self.markActive = false
self.markDamage = 0
self.comboCount = 0
end

@ExecSpace("ClientOnly")
method void PlayEffect(string ruid, Entity target)
-- 이펙트 재생. API가 없거나 RUID가 잘못돼도 전투가 멈추면 안 되므로 pcall로 감싼다.
if ruid == nil or ruid == "" then return end

local t = target
if t == nil then t = self.Entity end

local ok = pcall(function()
	_EffectService:PlayEffect(ruid, t)
end)
if ok == false then
	log("[RhythmGameManager] 이펙트 재생 실패(무시): " .. tostring(ruid))
end
end

@ExecSpace("ClientOnly")
method void PlayBGM()
-- 볼륨은 설정(_SoundChannels)이 관리한다. self.bgmVolume은 이 BGM의 기본 크기.
if self.bgmRUID == nil or self.bgmRUID == "" then
	log("[RhythmGameManager] BGM RUID 없음 — 무음으로 진행")
	return
end

self.bgmHandle = {}
_SoundChannels:PlayBgm(self.bgmRUID, self.bgmVolume)
log("[RhythmGameManager] BGM 재생 (" .. self.bgmRUID .. ")")
end

@ExecSpace("ClientOnly")
method void StopBGM()
self.bgmHandle = {}
_SoundChannels:StopBgm()
end

@ExecSpace("ClientOnly")
method void SetupCamera()
-- 전투 카메라 줌/오프셋 세팅(로컬 플레이어 카메라)
local p = _UserService.LocalPlayer
if p == nil then return end

-- 리듬게임 진입 시 캐릭터가 오른쪽(몬스터 쪽)을 보도록 고정
if p.PlayerControllerComponent ~= nil then
	p.PlayerControllerComponent.LookDirectionX = 1
end

local cam = p.CameraComponent
if cam == nil then return end

cam.ZoomRatio = self.cameraZoom
-- CameraOffset은 필드 직접 수정이 안 먹어서 구조체를 통째로 재할당한다
local off = cam.CameraOffset
off.x = self.cameraOffsetX
off.y = self.cameraOffsetY
cam.CameraOffset = off

log("[RhythmGameManager] 카메라 줌=" .. tostring(self.cameraZoom)
	.. " 오프셋=(" .. tostring(self.cameraOffsetX) .. ", " .. tostring(self.cameraOffsetY) .. ")")
end

@ExecSpace("ClientOnly")
method void LoadStageData()
-- ================================================================
-- self.stageId로 StageData → MonsterData → MusicData를 읽어 전투 값을 채운다.
-- ================================================================
local monsterId = ""
local bgmId = ""
self.stageTime = 0
self.hpMultiplier = 1
self.attackMultiplier = 1
self.attackInterval = 0

-- ---- StageData ----
local stage = _DataService:GetTable("StageData")
if stage == nil then
	log("[RhythmGameManager] StageData 테이블 없음 — 기본값으로 진행")
else
	local row = stage:FindRow("Id", self.stageId)
	if row == nil then
		log("[RhythmGameManager] StageData에 " .. tostring(self.stageId) .. " 행 없음")
	else
		monsterId = row:GetItem("Monster") or ""
		bgmId = row:GetItem("BGMRUID") or ""
		self.stageTime = self:ToNumber(row:GetItem("Time"), 0)
		self.hpMultiplier = self:ToNumber(row:GetItem("HP_Multiplier"), 1)
		self.attackMultiplier = self:ToNumber(row:GetItem("Attack_Multiplier"), 1)
		self.attackInterval = self:ToNumber(row:GetItem("AttackInterval"), 0)
	end
end
self.timeLeft = self.stageTime
self.monsterId = monsterId

-- ---- MonsterData ----
local baseHP = 100
self.attackEffectRUID = ""
self.hitEffectRUID = ""
self.deathEffectRUID = ""
self.patterns = {}
local monsterRUID = ""

local mon = _DataService:GetTable("MonsterData")
if mon == nil then
	log("[RhythmGameManager] MonsterData 테이블 없음")
elseif monsterId ~= "" then
	local row = mon:FindRow("Id", monsterId)
	if row == nil then
		log("[RhythmGameManager] MonsterData에 " .. monsterId .. " 행 없음")
	else
		monsterRUID = row:GetItem("MonsterRUID") or ""
		baseHP = self:ToNumber(row:GetItem("HP"), 100)
		self.attackEffectRUID = row:GetItem("AttackEffectRUID") or ""
		self.hitEffectRUID = row:GetItem("HitEffectRUID") or ""
		self.deathEffectRUID = row:GetItem("DeathEffectRUID") or ""
		self.patterns = self:ParseIdList(row:GetItem("BossPatternIDs"))
	end
end

-- HP = 몬스터 기본 HP × 스테이지 HP 배율
self.enemyMaxHP = math.floor(baseHP * self.hpMultiplier)

-- 공격주기(초)가 비어 있으면 기본값
if self.attackInterval <= 0 then
	self.attackInterval = self.defaultAttackInterval
end

-- ---- MusicData ----
self.bgmRUID = ""
local music = _DataService:GetTable("MusicData")
if music == nil then
	log("[RhythmGameManager] MusicData 테이블 없음")
elseif bgmId ~= "" then
	local row = music:FindRow("ID", bgmId)
	if row == nil then row = music:FindRow("Id", bgmId) end
	if row == nil then
		self.bgmRUID = bgmId
		log("[RhythmGameManager] MusicData에 " .. bgmId .. " 행 없음 — RUID 직접 사용 시도")
	else
		self.bgmRUID = row:GetItem("RUID") or ""
		self.bpm = self:ToNumber(row:GetItem("BPM"), self.bpm)
	end
end

-- 미리 배치한 몬스터 엔티티에 스프라이트 교체
self:SetMonsterSprite(monsterRUID)

log("[RhythmGameManager] 스테이지 로드: " .. tostring(self.stageId)
	.. " / 몬스터=" .. tostring(monsterId)
	.. " HP=" .. tostring(self.enemyMaxHP) .. "(x" .. tostring(self.hpMultiplier) .. ")"
	.. " 공격주기=" .. tostring(self.attackInterval) .. "s"
	.. " 공격배율=" .. tostring(self.attackMultiplier)
	.. " / BPM=" .. tostring(self.bpm)
	.. " / 제한시간=" .. tostring(self.stageTime))
end

@ExecSpace("ClientOnly")
method number GetPatternInterval()
-- 첫 패턴의 AttackInterval을 가져온다. 없으면 defaultAttackInterval.
if self.patterns == nil then return self.defaultAttackInterval end
local first = self.patterns[1]
if first == nil then return self.defaultAttackInterval end

local pt = _DataService:GetTable("PatternData")
if pt == nil then return self.defaultAttackInterval end

local row = pt:FindRow("Id", first)
if row == nil then return self.defaultAttackInterval end

return self:ToNumber(row:GetItem("AttackInterval"), self.defaultAttackInterval)
end

@ExecSpace("ClientOnly")
method void PlayMonsterAnim(string animRUID)
-- 몬스터 스프라이트를 잠깐 애니 스프라이트로 바꿨다가 기본으로 되돌린다.
if not isvalid(self.enemyEntity) then return end
if animRUID == nil or animRUID == "" then return end

local sr = self.enemyEntity.SpriteRendererComponent
if sr == nil then return end

sr.SpriteRUID = animRUID
wait(self.animDuration)
if self.monsterSpriteRUID ~= nil and self.monsterSpriteRUID ~= "" then
	sr.SpriteRUID = self.monsterSpriteRUID
end
end

@ExecSpace("ClientOnly")
method void SetMonsterSprite(string ruid)
-- 미리 배치한 몬스터 엔티티에 스프라이트만 교체(스폰하지 않음).
if not isvalid(self.enemyEntity) then
	log("[RhythmGameManager] enemyEntity 연결 안 됨 — 에디터에서 몬스터 엔티티를 연결하세요")
	return
end
if ruid == nil or ruid == "" then
	log("[RhythmGameManager] MonsterRUID 없음 — 스프라이트 교체 생략")
	return
end

local sr = self.enemyEntity.SpriteRendererComponent
if sr ~= nil then
	sr.SpriteRUID = ruid
	self.monsterSpriteRUID = ruid
	log("[RhythmGameManager] 몬스터 스프라이트 교체: " .. ruid)
else
	log("[RhythmGameManager] enemyEntity에 SpriteRendererComponent 없음")
end
end

@ExecSpace("ClientOnly")
method void SetSelectedSkills(table list)
-- StageSelect에서 고른 전투 스킬 목록을 받아둔다(StartBattle 전에 호출)
self.selectedSkills = list or {}
log("[RhythmGameManager] 선택 스킬 " .. tostring(#self.selectedSkills) .. "개 수신")
end

@ExecSpace("ClientOnly")
method void StartBattle()
-- ================================================================
-- 전투 시작: 스테이지 데이터 로드 → HP 초기화 → BGM/BPM → BeatRunner 가동 → UI
-- ================================================================
if self.hasStarted then
	return
end
self.hasStarted = true
self.battlePaused = false

-- 다른 맵에서 넘어온 전투 값(스테이지/스킬)을 PlayerData에서 가져온다
local lpBattle = _UserService.LocalPlayer
if lpBattle ~= nil and lpBattle.PlayerData ~= nil then
	if lpBattle.PlayerData.battleStageId ~= "" then
		self.stageId = lpBattle.PlayerData.battleStageId
	end
	local sj = lpBattle.PlayerData.battleSkillsStr
	if sj ~= nil and sj ~= "" then
		local ok, decoded = pcall(function() return _HttpService:JSONDecode(sj) end)
		if ok and type(decoded) == "table" then self.selectedSkills = decoded end
	end
end

-- 1) CSV 로드 + 몬스터 스프라이트
self:LoadStageData()

-- 1-1) 전투 카메라 세팅
self:SetupCamera()

-- 2) HP 초기화
self.enemyHP = self.enemyMaxHP
self.playerHP = self.playerMaxHP
self:ResetEffects()
self.attackTimer = 0

-- 3) 캐릭터 이동 제한
local char = self.character
if char == nil then
	char = _UserService.LocalPlayer
end
if char ~= nil then
	local ctrl = char.PlayerControllerComponent
	if ctrl ~= nil then
		ctrl.Enable = false
	else
		log("[RhythmGameManager] 캐릭터에 PlayerControllerComponent 없음")
	end
end

-- 4) 전투 UI 켜기
if self.gameUI ~= nil then
	self.gameUI.Enable = true
	if self.gameUI.GameUI ~= nil then
		self.gameUI.GameUI:Show()
	end
end

-- 4-1) 보유 스킬을 슬롯에 표시
if isvalid(self.skillSlotUI) and self.skillSlotUI.SkillSlotUI ~= nil then
	self.skillSlotUI.SkillSlotUI:Show()
else
	log("[RhythmGameManager] skillSlotUI 연결 안 됨 — 스킬 슬롯 표시 생략")
end

-- 4-2) 커맨드 후보 등록
if isvalid(self.battleInput) and self.battleInput.BattleInput ~= nil then
	local bi = self.battleInput.BattleInput
	if self.selectedSkills ~= nil and #self.selectedSkills > 0 then
		bi:SetCandidates(self.selectedSkills)
	else
		bi:RefreshCandidates()
	end
else
	log("[RhythmGameManager] battleInput 연결 안 됨 — 커맨드 등록 불가")
end

-- 5) BGM 재생 + BeatRunner에 BPM 반영 후 가동
self:PlayBGM()

if self.runner ~= nil then
	local br = self.runner.BeatRunner
	if br ~= nil then
		br.bpm = self.bpm
		br:ResetRun()
	else
		log("[RhythmGameManager] runner에 BeatRunner 컴포넌트가 없음")
	end
else
	log("[RhythmGameManager] runner 연결 안 됨 — 비트 진행 불가")
end

-- 6) UI 갱신 + 타이머 초기 표시
self:RefreshUI()
if isvalid(self.gameUI) and self.gameUI.GameUI ~= nil then
	self.gameUI.GameUI:SetTime(self.timeLeft)
end
end

@ExecSpace("ClientOnly")
method void OnUpdate(number delta)
if self.hasStarted == false then return end
if self.battlePaused then return end

-- ---- 스테이지 제한 시간 ----
if self.timeLeft > 0 then
	self.timeLeft = self.timeLeft - delta
	if self.timeLeft <= 0 then
		self.timeLeft = 0
		log("[RhythmGameManager] 제한 시간 종료 → 패배")
		self:OnBattleLose()
		return
	end
	if isvalid(self.gameUI) and self.gameUI.GameUI ~= nil then
		self.gameUI.GameUI:SetTime(self.timeLeft)
	end
end

-- ---- 몬스터 공격 타이머 ----
if self.attackInterval > 0 and self.enemyHP > 0 and self.playerHP > 0 then
	self.attackTimer = self.attackTimer + delta
	if self.attackTimer >= self.attackInterval then
		self.attackTimer = self.attackTimer - self.attackInterval
		self:MonsterAttack()
	end
end

-- ---- 지속효과: 버프 시간 감소 ----
if self.buffAttackTime > 0 then
	self.buffAttackTime = self.buffAttackTime - delta
	if self.buffAttackTime < 0 then self.buffAttackTime = 0 end
end
if self.buffDefenseTime > 0 then
	self.buffDefenseTime = self.buffDefenseTime - delta
	if self.buffDefenseTime < 0 then self.buffDefenseTime = 0 end
end
if self.buffEvadeTime > 0 then
	self.buffEvadeTime = self.buffEvadeTime - delta
	if self.buffEvadeTime < 0 then self.buffEvadeTime = 0 end
end
if self.buffCritTime > 0 then
	self.buffCritTime = self.buffCritTime - delta
	if self.buffCritTime < 0 then self.buffCritTime = 0 end
end

-- ---- 도트: time초 동안 1초마다 dps ----
if self.dots ~= nil and #self.dots > 0 and self.enemyHP > 0 then
	local i = #self.dots
	while i >= 1 do
		local d = self.dots[i]
		d.timeLeft = d.timeLeft - delta
		d.tickAccum = d.tickAccum + delta
		if d.tickAccum >= 1.0 then
			d.tickAccum = d.tickAccum - 1.0
			self:EnemyTakeDamage(d.dps)
		end
		if d.timeLeft <= 0 then table.remove(self.dots, i) end
		i = i - 1
	end
end
end

-- ================================================================
-- [추가] 일시정지 연동.
-- PauseManager가 정지/재개를 알리면 리듬 전투도 함께 멈추고 이어간다.
-- ================================================================
@ExecSpace("ClientOnly")
method void OnBattlePauseChanged(PauseStateChangedEvent event)
if event.isPaused then
	self:PauseBattle()
else
	self:ResumeBattle()
end
end

@ExecSpace("ClientOnly")
method void PauseBattle()
if self.hasStarted == false then return end
if self.battlePaused then return end
self.battlePaused = true

-- 도는 네모를 멈추면 BattleInput의 판정도 함께 멈춘다
if isvalid(self.runner) then
	local br = self.runner.BeatRunner
	if br ~= nil then br.isMoving = false end
end

if self.stopBgmWhilePaused then
	_SoundChannels:StopBgm()
end
log("[RhythmGameManager] 전투 일시정지")
end

@ExecSpace("ClientOnly")
method void ResumeBattle()
if self.hasStarted == false then return end
if self.battlePaused == false then return end
self.battlePaused = false

if self.stopBgmWhilePaused then
	-- 음악과 비트를 함께 처음부터 → 싱크 유지
	self:PlayBGM()
	if isvalid(self.runner) then
		local br = self.runner.BeatRunner
		if br ~= nil then br:ResetRun() end
	end
else
	if isvalid(self.runner) then
		local br = self.runner.BeatRunner
		if br ~= nil then br.isMoving = true end
	end
end

-- PauseManager가 재개하며 캐릭터 조작을 다시 켜므로, 전투 중엔 다시 끈다
local char = self.character
if char == nil then char = _UserService.LocalPlayer end
if char ~= nil then
	local ctrl = char.PlayerControllerComponent
	if ctrl ~= nil then ctrl.Enable = false end
end
log("[RhythmGameManager] 전투 재개")
end

@ExecSpace("ClientOnly")
method void MonsterAttack()
-- 몬스터가 가진 패턴 중 하나를 골라 공격.
local dmg = 0
local special = ""
local patternId = ""

if self.patterns ~= nil and #self.patterns > 0 then
	patternId = self.patterns[math.random(1, #self.patterns)]
end

if patternId ~= "" then
	local pt = _DataService:GetTable("PatternData")
	if pt ~= nil then
		local row = pt:FindRow("Id", patternId)
		if row ~= nil then
			local atk = row:GetItem("Attack")
			local n = nil
			if atk ~= nil and atk ~= "" then n = tonumber(atk) end
			if n ~= nil then
				dmg = n
			else
				special = atk or ""
			end
		else
			log("[RhythmGameManager] PatternData에 " .. patternId .. " 행 없음")
		end
	end
end

if special ~= "" then
	log("[RhythmGameManager] 특수 패턴 발동: " .. special .. " (데미지 0)")
	-- TODO: PlayerStun 등 특수 효과 구현
end

self:PlayMonsterAnim(self.attackEffectRUID)

log("[RhythmGameManager] 몬스터 공격 (패턴=" .. tostring(patternId) .. ", 데미지=" .. tostring(dmg) .. ")")
self:PlayerTakeDamage(dmg)
end

@ExecSpace("ClientOnly")
method void PlayerAttack(string skillId)
-- ==============================================================
-- BattleInput이 8박 커맨드를 성공했을 때 호출.
-- SkillData.EffectType을 보고 효과별로 분기. 강화값은 PlayerData:GetSkillStat.
--
--  EffectType     동작                       Damage 컬럼 예시
--  Damage         즉시 데미지                 {Attack:N}
--  Heal           내 HP 회복                  {Heal:N}
--  DoT            Time초 동안 1초마다 데미지    {Time:N,Damage:N}
--  Lifesteal      데미지 + 그만큼 HP 흡수       {Damage:N,Heal:N}
--  DamageChance   데미지 + 30% 확률 추가타      {Damage:N}
--  Buff_Attack    Time초 내 공격 +N            {Time:N,Attack:N}
--  Buff_Defense   받는 피해 N 감소             {Time:N,Attack:N}
--  Buff_Evade     Time초 몬스터 공격 무시       {Time:N}
--  Buff_Crit      Time초 Luck% 확률로 2배딜     {Time:N,Luck:N}
--  Mark           표식 → 다음 공격스킬에 추가딜  {Damage:N}
--  Combo          쓸수록 카운트↑, 카운트×딜      {Attack:N}
-- ==============================================================
if skillId == nil or skillId == "" then
	log("[RhythmGameManager] skillId 비어 있음 — 기본 데미지")
	self:EnemyTakeDamage(self:CalcOutgoing(self.defaultSkillDamage))
	return
end

local sk = _DataService:GetTable("SkillData")
local row = nil
if sk ~= nil then row = sk:FindRow("Id", skillId) end
if row == nil then
	log("[RhythmGameManager] SkillData에 " .. tostring(skillId) .. " 없음 — 기본 데미지")
	self:EnemyTakeDamage(self:CalcOutgoing(self.defaultSkillDamage))
	return
end

local effectType = row:GetItem("EffectType")
if effectType == nil or effectType == "" then effectType = "Damage" end

-- 강화 반영 스탯 조회(PlayerData). pd 없으면 0.
local pd = nil
local lp = _UserService.LocalPlayer
if lp ~= nil then pd = lp.PlayerData end
local function stat(name)
	if pd ~= nil then return pd:GetSkillStat(skillId, name) end
	return 0
end

log("[RhythmGameManager] 스킬 " .. tostring(skillId) .. " (" .. effectType .. ")")

if effectType == "Heal" then
	self:PlayerHeal(stat("Heal"))

elseif effectType == "DoT" then
	local time = stat("Time")
	if time <= 0 then time = 1 end
	self:AddDoT(time, stat("Damage"))

elseif effectType == "Lifesteal" then
	local dmg = stat("Damage")
	self:EnemyTakeDamage(self:CalcOutgoing(dmg))
	self:PlayerHeal(stat("Heal"))

elseif effectType == "DamageChance" then
	local dmg = stat("Damage")
	self:EnemyTakeDamage(self:CalcOutgoing(dmg))
	if math.random() * 100 <= 30 then
		self:EnemyTakeDamage(dmg)
		log("[RhythmGameManager] 파이널어택 추가타!")
	end

elseif effectType == "Buff_Attack" then
	self.buffAttackTime = stat("Time")
	self.buffAttackAmount = stat("Damage")

elseif effectType == "Buff_Defense" then
	local time = stat("Time")
	self.buffDefenseAmount = stat("Damage")
	if time > 0 then
		self.buffDefenseTime = time
	else
		self.buffDefenseCharges = 1
	end

elseif effectType == "Buff_Evade" then
	self.buffEvadeTime = stat("Time")

elseif effectType == "Buff_Crit" then
	self.buffCritTime = stat("Time")
	self.buffCritChance = stat("Luck")

elseif effectType == "Mark" then
	self.markActive = true
	self.markDamage = stat("Damage")

elseif effectType == "Combo" then
	self.comboCount = self.comboCount + 1
	if self.comboCount > self.comboMax then self.comboCount = self.comboMax end
	self:EnemyTakeDamage(self:CalcOutgoing(stat("Damage") * self.comboCount))

else
	local dmg = stat("Damage")
	if dmg <= 0 then dmg = self:ParseAttack(row:GetItem("Damage")) end
	local total = self:CalcOutgoing(dmg)
	if self.markActive then
		total = total + self.markDamage
		self.markActive = false
		log("[RhythmGameManager] 표식 발동! +" .. tostring(self.markDamage))
	end
	self:EnemyTakeDamage(total)
end
end

@ExecSpace("ClientOnly")
method void EnemyTakeDamage(number dmg)
if dmg == nil then dmg = 0 end

self.enemyHP = self.enemyHP - dmg
if self.enemyHP < 0 then self.enemyHP = 0 end
self:RefreshUI()
log("[RhythmGameManager] 몬스터 HP " .. tostring(self.enemyHP) .. "/" .. tostring(self.enemyMaxHP))

if self.enemyHP <= 0 then
	log("[RhythmGameManager] 몬스터 처치 — 승리!")
	self:OnBattleWin()
else
	self:PlayMonsterAnim(self.hitEffectRUID)
end
end

@ExecSpace("ClientOnly")
method void PlayerTakeDamage(number dmg)
if dmg == nil then dmg = 0 end

-- 회피버프: 피해 완전 무시
if self.buffEvadeTime > 0 then
	log("[RhythmGameManager] 회피! (다크사이트)")
	return
end
-- 방어버프: 피해 감소(지속 또는 1회권)
if self.buffDefenseTime > 0 or self.buffDefenseCharges > 0 then
	dmg = dmg - self.buffDefenseAmount
	if dmg < 0 then dmg = 0 end
	if self.buffDefenseTime <= 0 and self.buffDefenseCharges > 0 then
		self.buffDefenseCharges = self.buffDefenseCharges - 1
	end
	log("[RhythmGameManager] 방어버프 적용 → 피해 " .. tostring(dmg))
end

self.playerHP = self.playerHP - dmg
if self.playerHP < 0 then self.playerHP = 0 end
self:RefreshUI()
log("[RhythmGameManager] 플레이어 HP " .. tostring(self.playerHP) .. "/" .. tostring(self.playerMaxHP))

if self.playerHP <= 0 then
	log("[RhythmGameManager] 플레이어 사망 — 패배...")
	self:OnBattleLose()
end
end

@ExecSpace("ClientOnly")
method void RefreshUI()
-- GameUI에 양쪽 HP를 넘긴다. 연결 전이어도 터지지 않게 nil 체크.
if isvalid(self.gameUI) then
	local ui = self.gameUI.GameUI
	if ui ~= nil then
		ui:SetEnemyHP(self.enemyHP, self.enemyMaxHP)
		ui:SetPlayerHP(self.playerHP, self.playerMaxHP)
	else
		log("[RhythmGameManager] gameUI에 GameUI 컴포넌트 없음 — HP 바 갱신 불가")
	end
else
	log("[RhythmGameManager] gameUI 연결 안 됨 — HP 바 갱신 불가")
end
end

@ExecSpace("ClientOnly")
method void RefreshHP()
-- 구버전 호환용 별칭
self:RefreshUI()
end

@ExecSpace("ClientOnly")
method void OnBeginPlay()
-- [추가] 정지/재개 알림 구독.
-- 구독에 실패해도 전투 시작(아래 StartBattle)까지 막으면 안 되므로 pcall로 감싼다.
local okPause = pcall(function()
	self.pauseHandler = _PauseManager:ConnectEvent(PauseStateChangedEvent, self.OnBattlePauseChanged)
end)
if okPause == false then
	log("[RhythmGameManager] 일시정지 구독 실패 — 전투는 그대로 시작한다")
end

-- Game 인스턴스 맵 진입 시 자동 전투 시작.
-- 1) 서버에 전투 데이터 로드 요청(공유메모리 → Sync 프로퍼티)
local lp0 = _UserService.LocalPlayer
if lp0 ~= nil and lp0.PlayerData ~= nil then
	lp0.PlayerData:LoadBattleData()
end

-- 2) battleStageId + battleSkillsStr가 Sync로 둘 다 도착할 때까지 대기
local ready = false
for i = 1, 50 do
	local lp = _UserService.LocalPlayer
	if lp ~= nil and lp.PlayerData ~= nil then
		local sid = lp.PlayerData.battleStageId
		local sj = lp.PlayerData.battleSkillsStr
		if sid ~= "" and sj ~= nil and sj ~= "" and sj ~= "[]" then
			ready = true
			break
		end
	end
	wait(0.1)
end

if not ready then
	log("[RhythmGameManager] 전투 데이터(스테이지/스킬)를 다 못 받음 — 있는 값으로 시작 시도")
end
self:StartBattle()
end

@ExecSpace("ClientOnly")
method void OnEndPlay()
if self.pauseHandler then
	_PauseManager:DisconnectEvent(PauseStateChangedEvent, self.pauseHandler)
end
end

@ExecSpace("ClientOnly")
method void EndBattle()
-- 전투 종료 공통 처리: 러너 정지, 마크 정리, 캐릭터 이동 복구.
self.hasStarted = false
self.battlePaused = false

self:StopBGM()

if isvalid(self.runner) then
	local br = self.runner.BeatRunner
	if br ~= nil then br.isMoving = false end
end
if isvalid(self.battleInput) and self.battleInput.BattleInput ~= nil then
	self.battleInput.BattleInput:ClearMarks()
end

local char = self.character
if char == nil then char = _UserService.LocalPlayer end
if char ~= nil then
	local ctrl = char.PlayerControllerComponent
	if ctrl ~= nil then ctrl.Enable = true end
end
end

@ExecSpace("ClientOnly")
method void OnBattleWin()
-- 승리 처리(중복 방지: 이미 끝났으면 무시)
if self.hasStarted == false then return end
self:EndBattle()

local stars = 0
if isvalid(self.gameUI) and self.gameUI.GameUI ~= nil then
	stars = self.gameUI.GameUI:ShowResult(true, self.timeLeft, self.stageTime)
end

local lp = _UserService.LocalPlayer
if lp ~= nil and lp.PlayerData ~= nil then
	lp.PlayerData:ClearStage(self.stageId, stars)
end

log("[RhythmGameManager] 전투 승리 (별 " .. tostring(stars) .. ")")
end

@ExecSpace("ClientOnly")
method void OnBattleLose()
-- 패배 처리(시간 초과 또는 플레이어 사망). 중복 방지.
if self.hasStarted == false then return end
self:EndBattle()

if isvalid(self.gameUI) and self.gameUI.GameUI ~= nil then
	self.gameUI.GameUI:ShowResult(false, 0, self.stageTime)
end

log("[RhythmGameManager] 전투 패배")
end

@ExecSpace("ClientOnly")
method void ExitBattle()
-- 전투를 정리하고 메인 화면으로 복귀
if not self.hasStarted then
	return
end
self.hasStarted = false
self.battlePaused = false

self:StopBGM()

self.attackTimer = 0
self.timeLeft = 0

local char = self.character
if char == nil then
	char = _UserService.LocalPlayer
end
if char ~= nil then
	local ctrl = char.PlayerControllerComponent
	if ctrl ~= nil then
		ctrl.Enable = true
	end
end

if isvalid(self.runner) then
	local br = self.runner.BeatRunner
	if br ~= nil then
		br.isMoving = false
	end
end

-- 남은 판정 마크 정리
if isvalid(self.battleInput) and self.battleInput.BattleInput ~= nil then
	self.battleInput.BattleInput:ClearMarks()
end

-- 전투 HUD 끄기(StartBattle에서 켠 것과 대칭)
if self.gameUI ~= nil then
	if self.gameUI.GameUI ~= nil then
		self.gameUI.GameUI:Hide()
	else
		self.gameUI.Enable = false
	end
end
if isvalid(self.skillSlotUI) and self.skillSlotUI.SkillSlotUI ~= nil then
	self.skillSlotUI.SkillSlotUI:Hide()
end

if isvalid(self.gameUIGroupEntity) then
	self.gameUIGroupEntity:SetEnable(false)
end
if isvalid(self.rythemSoloGroupEntity) then
	self.rythemSoloGroupEntity:SetEnable(false)
end
if isvalid(self.mainScreenEntity) then
	self.mainScreenEntity:SetEnable(true)
end

log("[RhythmGameManager] 전투 종료 → 메인 화면 복귀")
end

@ExecSpace("ClientOnly")
@EventSender("Service", "InputService")
handler HandleKeyDownEvent(KeyDownEvent event)
-- ESC는 이제 설정 팝업(InGameSettingLogic)이 열고 닫는다.
-- 여기서도 전투를 끝내면 한 번의 ESC로 팝업이 뜨면서 전투까지 종료되므로
-- 기본값(escExitsBattle = false)에서는 아무것도 하지 않는다.
-- 예전처럼 ESC로 바로 나가고 싶으면 프로퍼티를 true로 켜면 된다.
if self.escExitsBattle == false then return end
if self.battlePaused then return end
if event.key == KeyboardKey.Escape then
	self:ExitBattle()
end
end

end
