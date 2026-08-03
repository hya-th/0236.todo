dofile(SCRATCH .. "/harness.lua")

local results = {}
local function T(name, orig, fixed, expect_orig, expect_fixed)
	local okO = (orig == expect_orig)
	local okF = (fixed == expect_fixed)
	table.insert(results, {
		name = name, orig = tostring(orig), fixed = tostring(fixed),
		eo = tostring(expect_orig), ef = tostring(expect_fixed), ok = okO and okF,
	})
end

local function boot(methods, keyTable, opts)
	resetLogs()
	_InputService = nil
	local logic = newLogic(methods)
	local mgr = newSettingsManager(keyTable, opts)
	_SettingsManager = mgr
	mgr.owner = logic
	_InputService = newInputService()
	logic:OnBeginPlay()
	return logic, mgr
end

local files = {
	orig  = SCRATCH .. "/orig_methods.lua",
	fixed = SCRATCH .. "/fixed_methods.lua",
}

-- ── A. 프로젝트에 Beat* 액션이 없을 때 (action1~3 강제 덮어쓰기의 결과) ──
local A = {}
for tag, f in pairs(files) do
	local logic, mgr = boot(f, { MoveLeft = "A", MoveRight = "D", Jump = "Space" }, { instantApply = true })
	logic:OpenSettings()
	local shownAtOpen = logic.keyText1.Text
	clickBtn(logic, logic.btnChange1); pressKey(logic, "K"); clickBtn(logic, logic.btnChange1)
	A[tag] = { open = shownAtOpen, ui = logic.keyText1.Text,
		data1 = mgr.saved.keys.MoveLeft, dataB = tostring(mgr.saved.keys.BeatLeft) }
end
T("A-1 창을 열었을 때 1번 행 표시", A.orig.open, A.fixed.open, "입력 대기", "A")
T("A-2 K로 바꾼 뒤 UI 표시",        A.orig.ui,   A.fixed.ui,   "[K]",      "K")
T("A-3 저장된 데이터(MoveLeft)",    A.orig.data1, A.fixed.data1, "A",       "K")
T("A-4 저장된 데이터(BeatLeft)",    A.orig.dataB, A.fixed.dataB, "nil",     "nil")

-- ── B. 저장 왕복 중 'applied'가 도착하면 대기 중인 행의 입력이 지워지는지 ──
local B = {}
for tag, f in pairs(files) do
	local logic, mgr = boot(f, { BeatLeft = "Z", BeatRight = "X", BeatConfirm = "Space" })
	logic:OpenSettings()
	clickBtn(logic, logic.btnChange1); pressKey(logic, "Q"); clickBtn(logic, logic.btnChange1)
	clickBtn(logic, logic.btnChange2); pressKey(logic, "W")
	mgr:CompleteApply()                      -- 1번 행 저장 완료 알림이 뒤늦게 도착
	B[tag] = { ui2 = logic.keyText2.Text, icon2 = tostring(logic.waitIcon2.Enable) }
end
T("B-1 대기 중인 2번 행 표시", B.orig.ui2,   B.fixed.ui2,   "X",     "[W]")
T("B-2 대기 아이콘 유지",      B.orig.icon2, B.fixed.icon2, "false", "true")

-- ── C. 저장 왕복이 끝나기 전에 같은 행의 [변경]을 다시 누르면 ──
local C = {}
for tag, f in pairs(files) do
	local logic, mgr = boot(f, { BeatLeft = "Z", BeatRight = "X", BeatConfirm = "Space" })
	logic:OpenSettings()
	clickBtn(logic, logic.btnChange1); pressKey(logic, "Q"); clickBtn(logic, logic.btnChange1)
	clickBtn(logic, logic.btnChange1)        -- 아직 saved에는 Z가 남아 있는 시점
	C[tag] = logic.keyText1.Text
end
T("C-1 다시 [변경]을 눌렀을 때 표시", C.orig, C.fixed, "[Z]", "[Q]")

-- ── D. 저장 왕복 중 중복 검사 (풀려난 키를 다른 행에 넣기) ──
local D = {}
for tag, f in pairs(files) do
	local logic, mgr = boot(f, { BeatLeft = "Z", BeatRight = "X", BeatConfirm = "Space" })
	logic:OpenSettings()
	clickBtn(logic, logic.btnChange1); pressKey(logic, "Q"); clickBtn(logic, logic.btnChange1)
	clickBtn(logic, logic.btnChange2); pressKey(logic, "Z")   -- Z는 이제 아무도 안 쓴다
	clickBtn(logic, logic.btnChange2)
	D[tag] = { data = mgr.draft.keys.BeatRight, rejected = tostring(lastNoticeContains("이미 사용 중")) }
end
T("D-1 2번 행에 Z를 넣은 결과", D.orig.data,     D.fixed.data,     "X",    "Z")
T("D-2 '이미 사용 중' 거절",    D.orig.rejected, D.fixed.rejected, "true", "false")

-- ── E. 되돌리기: draft.volume에 voice가 없는 구성 ──
local E = {}
for tag, f in pairs(files) do
	local logic, mgr = boot(f, { BeatLeft = "Z", BeatRight = "X", BeatConfirm = "Space" })
	logic:OpenSettings()
	E[tag] = tostring(pcall(function() logic:OnRevertKeysClick() end))
end
T("E-1 되돌리기가 에러 없이 끝나는가", E.orig, E.fixed, "false", "true")

-- ── F. 즉시 저장 환경에서 [적용하기]의 안내 문구 ──
local F = {}
for tag, f in pairs(files) do
	local logic, mgr = boot(f, { BeatLeft = "Z", BeatRight = "X", BeatConfirm = "Space" }, { instantApply = true })
	logic:OpenSettings()
	clickBtn(logic, logic.btnChange1); pressKey(logic, "Q")
	resetLogs()
	clickBtn(logic, logic.btnApply)
	F[tag] = { msg = tostring(lastNoticeContains("변경된 내용이 없습니다")), data = mgr.saved.keys.BeatLeft }
end
T("F-1 잘못된 '변경된 내용이 없습니다'", F.orig.msg,  F.fixed.msg,  "true", "false")
T("F-2 실제로 저장된 값",               F.orig.data, F.fixed.data, "Q",    "Q")

-- ── G. 정상 경로 회귀: 열기 → 변경 → 저장 → 닫기 → 다시 열기 ──
local G = {}
for tag, f in pairs(files) do
	local logic, mgr = boot(f, { BeatLeft = "Z", BeatRight = "X", BeatConfirm = "Space" }, { instantApply = true })
	logic:OpenSettings()
	clickBtn(logic, logic.btnChange1); pressKey(logic, "Q"); clickBtn(logic, logic.btnChange1)
	local afterSave = logic.keyText1.Text
	clickBtn(logic, logic.btnClose)
	logic:OpenSettings()
	G[tag] = { ui = afterSave, reopen = logic.keyText1.Text, data = mgr.saved.keys.BeatLeft }
end
T("G-1 저장 직후 UI",   G.orig.ui,     G.fixed.ui,     "Q", "Q")
T("G-2 다시 열었을 때", G.orig.reopen, G.fixed.reopen, "Q", "Q")
T("G-3 저장된 데이터",  G.orig.data,   G.fixed.data,   "Q", "Q")

-- 결과 출력 ------------------------------------------------------------
local pass, fail = 0, 0
print(string.format("%-38s %-12s %-12s %s", "시나리오", "원본", "수정본", "예상대로"))
print(string.rep("-", 78))
for _, r in ipairs(results) do
	if r.ok then pass = pass + 1 else fail = fail + 1 end
	print(string.format("%-38s %-12s %-12s %s", r.name, r.orig, r.fixed,
		r.ok and "OK" or ("불일치 (예상 " .. r.eo .. " / " .. r.ef .. ")")))
end
print(string.rep("-", 78))
print(string.format("예상과 일치: %d, 불일치: %d", pass, fail))
