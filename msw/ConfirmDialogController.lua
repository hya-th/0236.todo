@Logic
script ConfirmDialogController extends Logic

-- ================================================================
-- 확인 다이얼로그. 슬롯이 하나라도 비어 있으면 OnBeginPlay에서 멈춰
-- 이후 연결이 전부 무산되던 문제를 고쳤다.
--
-- 확인창 UI를 아직 만들지 않았다면 Show()가 곧바로 onConfirm을 실행한다
-- (allowSkipWhenUnwired). 그래야 "스테이지 나가기 / 재시도" 버튼이
-- 죽은 것처럼 보이지 않는다. 확인 절차를 반드시 거치게 하려면 이 값을
-- false로 두면 되고, 그때는 UI가 없으면 아무 일도 일어나지 않는다.
-- ================================================================

property Entity dialogRoot = "32675617-1675-428d-9059-eaab4b8dd18c"
property TextGUIRendererComponent titleText = "db46125a-5906-44df-abac-138fe0ff7cda"
property TextGUIRendererComponent messageText = "216570ac-34aa-4599-94dc-6ca5f23734ce"
property ButtonComponent btnYes = "7dea64bd-3614-4c1d-b835-f16ef8b8feb2"
property ButtonComponent btnNo = "8995441d-69b4-461b-927f-9c5c4f364621"

property boolean allowSkipWhenUnwired = true -- 확인창 미제작 시 바로 실행할지

property any onConfirmCallback = nil
property any onCancelCallback = nil
property any btnYesHandler = nil
property any btnNoHandler = nil

@ExecSpace("ClientOnly")
method void OnBeginPlay()
if isvalid(self.dialogRoot) then
	self.dialogRoot.Enable = false
else
	log("[ConfirmDialogController] dialogRoot 미연결 — 확인창 없이 동작한다")
end

if self.btnYes ~= nil then
	self.btnYesHandler = self.btnYes.Entity:ConnectEvent(ButtonClickEvent, self.OnYesClick)
else
	log("[ConfirmDialogController] btnYes 미연결")
end

if self.btnNo ~= nil then
	self.btnNoHandler = self.btnNo.Entity:ConnectEvent(ButtonClickEvent, self.OnNoClick)
else
	log("[ConfirmDialogController] btnNo 미연결")
end
end

@ExecSpace("ClientOnly")
method void OnEndPlay()
if self.btnYesHandler then self.btnYes.Entity:DisconnectEvent(ButtonClickEvent, self.btnYesHandler) end
if self.btnNoHandler then self.btnNo.Entity:DisconnectEvent(ButtonClickEvent, self.btnNoHandler) end
end

@ExecSpace("ClientOnly")
method boolean IsWired()
-- 확인창으로 쓸 수 있는 최소 조건: 루트와 "예" 버튼.
return isvalid(self.dialogRoot) and self.btnYes ~= nil
end

@ExecSpace("ClientOnly")
method void Show(string title, string message, any onConfirm, any onCancel)
if self:IsWired() == false then
	log("[ConfirmDialogController] 확인창 미연결 — " .. tostring(title))
	if self.allowSkipWhenUnwired and onConfirm ~= nil then
		onConfirm()
	end
	return
end

if self.titleText ~= nil then self.titleText.Text = title end
if self.messageText ~= nil then self.messageText.Text = message end
self.onConfirmCallback = onConfirm
self.onCancelCallback = onCancel
self.dialogRoot.Enable = true
end

@ExecSpace("ClientOnly")
method void Hide()
if isvalid(self.dialogRoot) then
	self.dialogRoot.Enable = false
end
self.onConfirmCallback = nil
self.onCancelCallback = nil
end

@ExecSpace("ClientOnly")
method void OnYesClick()
-- Hide()가 콜백을 비우므로 먼저 지역 변수로 옮겨 둔다.
local callback = self.onConfirmCallback
self:Hide()
if callback ~= nil then
	callback()
end
end

@ExecSpace("ClientOnly")
method void OnNoClick()
local callback = self.onCancelCallback
self:Hide()
if callback ~= nil then
	callback()
end
end

end
