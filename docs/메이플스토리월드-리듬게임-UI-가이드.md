# 메이플스토리 월드로 리듬게임 UI 만들기 (왕초보용 가이드)

> 목표: 사진 속 리듬게임 화면(점수, 등급, 생명바, 콤보, 내려오는 음표, 판정선, GREAT 글자)을
> 메이플스토리 월드 에디터에서 처음부터 만들어 봅니다.
> **초등학생도 이해할 수 있게** 한 걸음씩 설명합니다.

---

## 0단계. 먼저 "큰 그림"부터 이해하기 🧩

복잡해 보이지만, 화면을 **작은 조각**으로 쪼개면 아주 쉬워져요.
사진을 조각내면 이렇게 9개예요.

| 번호 | 이름 | 위치 | 하는 일 |
|------|------|------|---------|
| ① | 점수판 (SCORE) | 왼쪽 위 | 지금 점수를 숫자로 보여줌 |
| ② | 등급 (C B A S) | 점수 옆 | 잘하면 등급이 올라감 |
| ③ | 생명바 (LIFE) | 오른쪽 위 | 실수하면 줄어드는 막대 |
| ④ | 일시정지 버튼 (⏸) | 오른쪽 위 끝 | 누르면 게임 멈춤 |
| ⑤ | 콤보 (COMBO) | 오른쪽 가운데 | 연속 성공 횟수 |
| ⑥ | 노트 길(레일) | 화면 가운데 | 음표가 내려오는 길 |
| ⑦ | 노트(음표) | 길 위 | 위에서 아래로 내려옴 |
| ⑧ | 판정선 | 화면 아래 | 여기서 눌러야 성공! |
| ⑨ | 판정 글자 (GREAT) | 가운데 | 얼마나 잘 눌렀는지 보여줌 |

👉 **핵심 아이디어**: "음표(⑦)가 위에서 아래로 내려오다가, 판정선(⑧)에 닿았을 때 손가락으로 누르면 점수가 오른다."
나머지(점수·콤보·생명)는 그 결과를 화면에 **글자로 보여주는 것**뿐이에요.

---

## 1단계. 메이플스토리 월드의 3가지 기본 단어 📚

메이플 월드를 처음 쓴다면, 딱 **3개 단어**만 기억하세요.

1. **엔티티(Entity)** = 화면에 있는 "물건 하나".
   예: 음표 1개, 글자 1개, 버튼 1개. → 레고 블록이라고 생각하세요.

2. **컴포넌트(Component)** = 물건에 붙이는 "부품/능력".
   예: `그림 보여주기` 부품, `글자 보여주기` 부품, `움직이기` 부품.
   → 레고 블록에 끼우는 액세서리예요.

3. **스크립트(Script)** = 우리가 쓰는 "명령문(코드)".
   메이플 월드는 **Lua(루아)** 라는 쉬운 언어를 써요.
   → "음표야, 아래로 내려가!" 같은 명령을 글로 적는 거예요.

> 정리: **엔티티(물건)** 에 **컴포넌트(부품)** 를 붙이고, **스크립트(명령)** 로 움직인다.

---

## 2단계. 메이플 월드 스크립트 생김새 익히기 ✍️

메이플 월드 코드는 항상 이런 모양이에요. 무서워하지 마세요. 그냥 **틀(형식)** 이에요.

```lua
@Component
script NoteController extends Component

    -- 이 안에 "설정값"이나 "명령"을 적어요
    -- 앞에 -- 두 개가 붙으면 "메모(주석)"라서 컴퓨터는 무시해요

    @ExecSpace("ClientOnly")
    method void OnBeginPlay()
    {
        -- 게임이 "시작될 때" 딱 한 번 실행돼요
        log("게임 시작!")   -- log는 화면 아래 로그창에 글을 찍어줘요 (print 같은 거)
    }

    @ExecSpace("ClientOnly")
    method void OnUpdate(number delta)
    {
        -- 아주아주 짧은 순간마다 계속 반복 실행돼요 (1초에 수십 번!)
        -- delta = "지난번 실행 이후 흐른 시간(초)". 부드럽게 움직일 때 씀
    }
```

외울 것 딱 2개:
- **`OnBeginPlay()`** = "시작할 때 한 번" 실행되는 방(함수)
- **`OnUpdate(delta)`** = "계속 반복해서" 실행되는 방(함수) → 음표가 내려오게 하는 곳!

> 💡 `@ExecSpace("ClientOnly")` 는 "이 명령은 각자 화면(플레이어)에서 실행해"라는 뜻이에요.
> UI/화면 관련은 대부분 `ClientOnly`(또는 `Client`)로 두면 됩니다. 지금은 그냥 그런갑다 하세요.

---

## 3단계. 화면에 고정된 것들(HUD) 만들기 🖼️

점수, 콤보, 생명바, 판정글자처럼 **화면에 딱 붙어 있는 것**을 UI(유아이)라고 해요.
이건 코드보다 **에디터에서 마우스로 만드는 게 훨씬 쉬워요.**

### (1) UI 만드는 순서 (에디터에서)
1. 위쪽 메뉴에서 **UI(또는 화면/GUI)** 만들기 모드를 켜요.
2. **텍스트(Text)** 를 하나 화면에 끌어다 놓아요. → 이게 "점수판"이 돼요.
3. 오른쪽 **속성(Properties) 창**에서:
   - 위치를 **왼쪽 위**로 옮기고,
   - 글자 크기/색을 예쁘게 바꾸고,
   - 이름(Name)을 알아보기 쉽게 `ScoreText` 라고 지어요.
4. 같은 방법으로 `ComboText`(콤보), `JudgeText`(GREAT/GOOD 등)도 만들어요.
5. 생명바는 **그림(Sprite/Image)** 을 2개 겹쳐서 만들어요.
   - 뒤: 회색 빈 막대, 앞: 초록색 채워진 막대 → 앞 막대의 **가로 길이**를 줄이면 생명이 닳는 것처럼 보여요.

> ✋ 위치·크기·색깔은 전부 **속성 창에서 마우스로** 조절해요. 코드 필요 없어요!
> 이름(Name)만 위처럼 정확히 지어두면, 나중에 코드에서 부르기 쉬워요.

### (2) UI 글자를 코드로 바꾸는 법
글자를 가진 엔티티에는 보통 **Text 컴포넌트**가 붙어 있어요. 코드로 이렇게 글자를 바꿔요.

```lua
-- 이 엔티티(스크립트가 붙은 물건)의 글자를 바꾸기
self.Entity.TextComponent.Text = "00048427"
```

> ⚠️ 실제 부품 이름은 에디터 버전에 따라 `TextComponent` 또는 `UITextComponent` 처럼 조금 다를 수 있어요.
> **속성 창에서 그 엔티티에 붙은 컴포넌트 이름을 눈으로 확인**하고, 그 이름 그대로 쓰면 돼요.
> (에디터에서 컴포넌트를 클릭하면 정확한 이름이 보여요.)

---

## 4단계. ⭐핵심⭐ 음표가 아래로 내려오게 하기

리듬게임의 심장이에요. **음표는 "월드에 놓인 그림 블록"** 으로 만드는 게 가장 쉬워요.

### (1) 음표 블록 준비
1. 노란색 막대 모양 **스프라이트(그림)** 엔티티를 하나 만들어요. 이름은 `Note`.
2. 이걸 **모델(Model)** 로 저장해 두면, 게임 중에 여러 개를 복제(스폰)할 수 있어요.

### (2) 음표에 붙일 스크립트: `NoteMover`
음표 블록에 아래 스크립트를 붙이면, **혼자 알아서 아래로 내려가요.**

```lua
@Component
script NoteMover extends Component

    -- 1초에 몇 칸 내려올지 정하는 값 (숫자가 크면 더 빠름)
    property number Speed = 5

    @ExecSpace("ClientOnly")
    method void OnUpdate(number delta)
    {
        -- 1) 이 음표의 "위치 부품"을 가져와요
        local transform = self.Entity.TransformComponent

        -- 2) 지금 위치를 읽어요 (x=좌우, y=위아래, z=앞뒤)
        local pos = transform.Position

        -- 3) y(위아래)를 조금 줄여서 아래로 내려요
        --    Speed * delta => "속도 X 흐른시간" 이라 어떤 컴퓨터든 똑같은 속도로 부드럽게 내려가요
        transform.Position = Vector3(pos.x, pos.y - self.Speed * delta, pos.z)

        -- 4) 너무 아래로 내려가서 화면 밖이면(놓쳤으면) 음표를 없애요
        if pos.y < -6 then
            self.Entity:Destroy()   -- 음표 삭제
        end
    end
```

**한 줄씩 쉽게 풀면:**
- `Speed = 5` → "속도" 설정값. 게임이 어려우면 크게, 쉬우면 작게.
- `transform.Position` → 음표의 지금 위치(좌표).
- `pos.y - self.Speed * delta` → "지금 높이에서 살짝 아래로". 이걸 매 순간 반복하니까 스르륵 내려와요.
- `if pos.y < -6` → 판정선보다 훨씬 아래로 지나갔으면 → 놓친 거니까 `Destroy()`(삭제).

> 🎯 왜 `Speed * delta` 로 곱하나요?
> 컴퓨터마다 속도가 달라도 **똑같이** 움직이게 하려는 거예요. `delta`(흐른 시간)를 곱하면 공평해져요.
> "1초에 5칸"처럼 시간 기준으로 움직이게 됩니다.

### (3) 음표를 계속 만들어 내보내기(스폰)
박자에 맞춰 음표를 위에서 하나씩 만들어 주는 "공장" 스크립트예요. 아무 곳(빈 엔티티)에 붙이세요.

```lua
@Component
script NoteSpawner extends Component

    -- 몇 초마다 음표를 만들지 (0.8초마다 하나)
    property number SpawnDelay = 0.8

    -- 음표를 만들 "위쪽 시작 높이"
    property number StartY = 6

    @ExecSpace("ClientOnly")
    method void OnBeginPlay()
    {
        -- SpawnDelay(0.8초)마다 SpawnNote()를 계속 반복 실행하라는 예약
        _TimerService:SetTimerRepeat(
            function()
                self:SpawnNote()
            end,
            self.SpawnDelay,   -- 몇 초마다
            0                  -- 0 = 무한 반복
        )
    end

    method void SpawnNote()
    {
        -- 왼쪽 길? 오른쪽 길? 아무거나 랜덤으로 골라요 (2개 길이라서 -2 또는 +2)
        local laneX = -2
        if math.random(1, 2) == 2 then
            laneX = 2
        end

        -- 위쪽(StartY)에서 음표 모델을 하나 복제해서 세상에 내보내요
        -- "노트모델아이디" 자리에는 3단계에서 저장한 음표 모델의 ID를 넣어요
        _SpawnService:SpawnByModelId(
            "여기에_음표_모델_ID",       -- 어떤 모양을 만들지
            "Note",                       -- 만들어진 물건의 이름
            Vector3(laneX, self.StartY, 0), -- 어디에 만들지 (위쪽)
            self.Entity                    -- 어디에 소속시킬지 (부모)
        )
    end
```

**쉽게 풀면:**
- `_TimerService:SetTimerRepeat(...)` → "**0.8초마다** 음표 하나 만들어!" 라고 알람을 맞춰 두는 거예요.
- `math.random(1, 2)` → 주사위처럼 1 또는 2를 뽑아서 **왼쪽/오른쪽 길**을 정해요.
- `_SpawnService:SpawnByModelId(...)` → 저장해 둔 음표 모델을 **복제해서 화면에 등장**시켜요.

> ✋ `"여기에_음표_모델_ID"` 는 여러분이 3단계에서 만든 **음표 모델의 실제 ID**로 바꿔야 해요.
> 에디터에서 모델을 우클릭하면 ID를 복사할 수 있어요.
> (버전에 따라 `SpawnByModelId` 대신 다른 스폰 함수를 쓸 수도 있으니, 에디터의 스폰 예제를 한 번 보면 좋아요.)

---

## 5단계. 손가락으로 눌렀을 때 판정하기 👆

이제 음표가 판정선 근처에 왔을 때 화면을 누르면 **성공/실패**를 정해요.
"판정 관리자" 스크립트를 하나 만들어요. (게임 전체를 관리하는 빈 엔티티에 붙이세요.)

```lua
@Component
script JudgeManager extends Component

    property number Score = 0     -- 점수
    property number Combo = 0     -- 콤보(연속 성공)
    property number Life  = 830   -- 생명

    -- 판정선의 높이 (음표 y가 이 근처면 "지금 눌러야 함")
    property number JudgeLineY = -4

    -- 화면을 손가락으로 눌렀을 때 자동으로 실행돼요
    @ExecSpace("Client")
    method void HandleScreenTouchEvent(ScreenTouchEvent event)
    {
        -- 화면에 남아 있는 음표들 중에서, 판정선과 가장 가까운 걸 찾아 판정해요
        -- (여기서는 개념만! 가장 가까운 Note를 찾았다고 가정)

        local closestNote = self:FindClosestNote()   -- 아래에서 만든 방(함수)

        if closestNote == nil then
            return   -- 누를 음표가 없으면 아무 일도 안 함
        end

        -- 음표의 높이와 판정선의 차이를 구해요 (math.abs = 부호 무시, 거리만)
        local diff = math.abs(closestNote.TransformComponent.Position.y - self.JudgeLineY)

        if diff < 0.3 then
            self:OnGreat(closestNote)     -- 아주 정확 → GREAT
        elseif diff < 0.6 then
            self:OnGood(closestNote)      -- 조금 아쉬움 → GOOD
        else
            self:OnMiss()                 -- 너무 멀리서 누름 → MISS
        end
    end

    -- 아주 잘 눌렀을 때
    method void OnGreat(any note)
    {
        self.Score = self.Score + 300     -- 점수 많이!
        self.Combo = self.Combo + 1       -- 콤보 +1
        self:ShowJudge("GREAT")           -- 화면에 GREAT 글자
        note:Destroy()                    -- 맞춘 음표 삭제
        self:RefreshUI()
    end

    -- 조금 아쉽게 눌렀을 때
    method void OnGood(any note)
    {
        self.Score = self.Score + 100
        self.Combo = self.Combo + 1
        self:ShowJudge("GOOD")
        note:Destroy()
        self:RefreshUI()
    end

    -- 놓쳤을 때
    method void OnMiss()
    {
        self.Combo = 0                    -- 콤보 끊김!
        self.Life = self.Life - 50        -- 생명 줄어듦
        self:ShowJudge("MISS")
        self:RefreshUI()
    end
```

**핵심 아이디어만 기억하세요:**
- 화면을 누르면 → 판정선 근처 음표를 찾아 → **얼마나 가까웠는지**로 GREAT / GOOD / MISS를 나눠요.
- GREAT일수록 점수·콤보를 많이 주고, MISS면 콤보가 0이 되고 생명이 줄어요.

> ⚠️ `FindClosestNote()`(가장 가까운 음표 찾기)는 조금 어려운 부분이라, 처음엔
> "음표가 판정선에 닿는 순간, 음표 자신이 신호를 보내는 방식"으로 더 쉽게 만들 수도 있어요.
> 우선은 위 흐름(누르기 → 거리 재기 → 판정)만 이해하면 충분해요.

---

## 6단계. 점수·콤보·생명바를 화면에 새로고침하기 🔄

판정할 때마다 숫자가 바뀌니까, **화면 글자도 새로 그려줘야** 해요.
`JudgeManager` 안에 아래 방(함수)들을 추가하세요.

```lua
    -- 화면의 점수/콤보/생명 표시를 최신 값으로 바꿔요
    method void RefreshUI()
    {
        -- 이름으로 UI 엔티티를 찾아서 글자를 바꿔요
        local scoreEntity = _EntityService:GetEntityByPath("ScoreText")
        scoreEntity.TextComponent.Text = tostring(self.Score)  -- 숫자를 글자로

        local comboEntity = _EntityService:GetEntityByPath("ComboText")
        comboEntity.TextComponent.Text = tostring(self.Combo)

        -- 생명바: 앞쪽 초록 막대의 가로 크기를 생명 비율만큼 줄여요 (개념)
        -- 예) 생명 830/1000 이면 => 가로 83%
    }

    -- GREAT / GOOD / MISS 글자를 잠깐 보여줘요
    method void ShowJudge(string text)
    {
        local judgeEntity = _EntityService:GetEntityByPath("JudgeText")
        judgeEntity.TextComponent.Text = text
        -- (선택) 0.3초 뒤에 글자를 지우고 싶으면 타이머로 지울 수 있어요
    }
```

**쉽게 풀면:**
- `_EntityService:GetEntityByPath("ScoreText")` → 3단계에서 이름 붙인 `ScoreText`를 이름으로 **찾아오기**.
- `tostring(self.Score)` → 숫자(48427)를 **글자("48427")** 로 바꿔서 화면에 보여줘요.
- 생명바는 앞 막대의 **가로 길이(스케일/사이즈)** 를 생명 비율만큼 줄이면 닳는 효과가 나요.

> ⚠️ `GetEntityByPath` 는 "경로/이름으로 찾기"예요. 실제 경로는 UI를 어디에 두었는지에 따라 달라요.
> 가장 쉬운 방법은, 필요한 UI 엔티티들을 **속성(property)으로 미리 연결**해 두는 거예요:
> ```lua
> property Entity ScoreText = nil
> ```
> 이렇게 만든 뒤, 에디터의 속성 창에서 마우스로 `ScoreText` 칸에 실제 UI를 끌어다 넣으면
> 코드에서 `self.ScoreText.TextComponent.Text = ...` 처럼 바로 쓸 수 있어 훨씬 편해요. (추천!)

---

## 7단계. 일시정지 버튼(⏸) 만들기

1. 오른쪽 위에 **버튼(Button) UI** 를 하나 만들고 이름을 `PauseButton` 이라고 지어요.
2. 버튼에는 "눌렸을 때" 실행되는 이벤트가 있어요. 아래처럼 연결해요.

```lua
    -- 버튼을 눌렀을 때
    @ExecSpace("Client")
    method void OnClickPause()
    {
        -- 여기서 노트 스폰과 이동을 멈추면 "일시정지"가 돼요
        -- 예: 진행 여부를 나타내는 값(IsPlaying)을 false 로 바꾸기
        log("일시정지!")
    }
```

> 버튼과 함수를 연결하는 방법은 에디터의 **버튼 이벤트(예: OnClick)** 칸에
> 위 함수를 지정하면 돼요. (에디터 UI에서 마우스로 연결)

---

## 8단계. 만드는 순서 정리 (체크리스트 ✅)

무엇부터 해야 할지 헷갈리면 이 순서대로 하세요!

1. [ ] 노란 음표 그림 1개 → **모델로 저장** (`Note`)
2. [ ] 음표에 `NoteMover` 스크립트 붙이기 → **혼자 내려가는지** 테스트
3. [ ] 빈 엔티티에 `NoteSpawner` 붙이기 → **계속 생겨나는지** 테스트
4. [ ] UI 텍스트 만들기: `ScoreText`, `ComboText`, `JudgeText`
5. [ ] 생명바(막대 그림 2개) 만들기
6. [ ] 일시정지 버튼 `PauseButton` 만들기
7. [ ] `JudgeManager` 스크립트로 **누르기 판정** 붙이기
8. [ ] `RefreshUI` 로 점수/콤보/생명 **화면 갱신** 확인
9. [ ] 속도(`Speed`), 생성 간격(`SpawnDelay`) 숫자를 바꿔가며 **난이도 조절**

> 👶 초보 팁: **한 번에 다 만들지 마세요.**
> "음표 1개가 내려온다 → 여러 개가 생긴다 → 누르면 점수가 오른다" 처럼
> **작게 하나씩** 성공시키면서 늘려가는 게 가장 빠른 길이에요.

---

## 자주 막히는 부분 (미리 알려주는 정답) 🆘

- **글자가 안 바뀌어요** → 컴포넌트 이름이 `TextComponent`가 맞는지 속성 창에서 확인하세요.
  (버전에 따라 `UITextComponent`일 수 있어요. 화면에 보이는 이름 그대로 쓰세요.)
- **음표가 안 움직여요** → 스크립트가 음표 엔티티에 **붙어 있는지**, `OnUpdate` 철자가 맞는지 확인.
- **음표가 안 생겨요** → `SpawnByModelId`의 **모델 ID**가 실제 음표 모델 ID로 바뀌었는지 확인.
- **좌표가 이상해요** → 화면(카메라)이 보는 위치에 맞게 `StartY`, `JudgeLineY`, `laneX` 숫자를 조절.
  숫자를 조금씩 바꿔 보며 눈으로 맞추면 돼요.
- **정확한 함수/부품 이름이 궁금해요** → 메이플 월드 에디터의 **도움말/예제 템플릿**을 열어
  비슷한 예제(예: 오브젝트 스폰, UI 텍스트 변경)를 참고하는 게 가장 정확해요.

---

## 마무리 한마디 💗

리듬게임은 결국 이 한 문장이에요:

> **"음표가 내려오고(4단계) → 판정선에서 누르면(5단계) → 점수·콤보·생명이 바뀌고(6단계) → 화면에 보여준다(3·6단계)."**

이 흐름만 이해하면, 나머지는 숫자(속도·간격·점수)만 바꾸는 놀이예요.
처음엔 어렵게 느껴져도, **작은 조각부터 하나씩** 성공시키면 반드시 완성할 수 있어요. 화이팅! 🚀
