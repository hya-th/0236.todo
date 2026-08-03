# SettingsLogic 검증 하네스 (선택 사항)

메이플스토리 월드 없이도 `SettingsLogic.xml`의 Lua 메서드를 그대로 실행해
"UI 텍스트 입력값을 바꿔 저장했을 때 값이 UI에 남고 데이터에도 저장되는가"를
확인하는 하네스다. 게임 실행 파일에는 포함되지 않으므로 필요 없으면 지워도 된다.

## 실행

```sh
S=$(pwd)/tests
git show HEAD~1:SettingsLogic.xml > /tmp/orig.xml      # 수정 전 파일
python3 tests/extract.py /tmp/orig.xml       /tmp/orig_methods.lua
python3 tests/extract.py SettingsLogic.xml   /tmp/fixed_methods.lua
lua5.4 -e "SCRATCH='/tmp'" -e "dofile('$S/tests.lua')"
```

`extract.py`가 XML의 각 `<CodeBlockMethod>`를 `function M:Name(args) ... end`로
풀어내고, `harness.lua`가 엔티티/컴포넌트/`_SettingsManager`/`_InputService`/
`_TimerService`를 흉내낸다. `tests.lua`는 수정 전·후 파일을 같은 시나리오로
돌려 결과를 나란히 비교한다.

## 주의

`harness.lua`의 `_SettingsManager`는 **실제 구현이 아니라 모델**이다.
`SettingsLogic`이 호출하는 API(`GetDraft` / `GetKeyName` / `SetDraftKey` /
`HasUnsavedChanges` / `Apply` / `RestoreDraftDefaults`)만 보고, 흔한 계약을
가정해 만들었다.

- `SetDraftKey`는 `draft.keys`에 없는 액션 이름을 조용히 거절한다
- `Apply()`는 서버 왕복이므로 `CompleteApply()`가 불릴 때까지 `saved`가 옛 값이다
  (`instantApply = true`로 즉시 저장 환경도 시험한다)

실제 `SettingsManager`의 계약이 다르면 하네스 쪽을 그에 맞춰 고쳐야 한다.
