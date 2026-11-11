-- Neverlose UI — патченная копия для «Пьяного Петуха» (P1-P14, P13-хаб 0.49).
-- 0.50: библиотека снова ОТДЕЛЬНЫМ файлом (вшивка в скрипт была с 0.44 —
-- с неё начались фризы). Залить в репозиторий GalinDeonor/Beta:
-- neverlose_patched.lua. Скрипт грузит этот файл loadstring'ом.
-- Извлечено байт-в-байт из Fust 0.49 (блок FUST_LG_FN), правок ноль.
local Library = {}

local NeverloseVersion = "v1.1A."

local TweenService = game:GetService("TweenService")
local input = game:GetService("UserInputService")

local function getRoot()
    local ok, r = pcall(function()
        if type(gethui) == "function" then return gethui() end
        return nil
    end)
    if ok and r then return r end
    local ok2, r2 = pcall(function()
        return game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end)
    if ok2 and r2 then return r2 end
    return nil
end
local NL_ROOT = getRoot()
local NL_SAVED_SG = nil
if NL_ROOT then
    for i,v in next, NL_ROOT:GetChildren() do
        if v:IsA("ScreenGui") and (v.Name == "Neverlose" or v.Name == "FUST_Neverlose") then
            v:Destroy()
        end
    end
end

-- 0.49 P13: ОБЩИЙ ВВОД ДЛЯ ВСЕХ ЭЛЕМЕНТОВ UI.
-- БЫЛО (0.48): каждый слайдер/колорпикер/кейбинд вешал СВОИ глобальные
-- соединения (InputChanged + InputEnded + RenderStepped / InputBegan).
-- При 40+ элементах это 120+ ВЕЧНЫХ колбэков: каждый тап и каждый кадр
-- гнал их все. Плюс GetMouse() в конструкторах мог БЛОКИРОВАТЬ поток до
-- спавна игрока (см. комментарий выше) — итог: FPS 0, игра умирает.
-- СТАЛО: 4 соединения на всю библиотеку, GetMouse не вызывается ВООБЩЕ.
local NL_HUB_X, NL_HUB_Y = nil, nil
local NL_SLIDE_FN = nil -- активный слайдер: обновляется каждый кадр
local NL_PICK_FN = nil  -- активный колорпикер: обновляется при движении пальца
local NL_KEY_FNS = {}   -- кейбинды: по одной функции на элемент
local NL_HUB_UIS = game:GetService("UserInputService")
NL_HUB_UIS.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        NL_HUB_X = inp.Position.X
        NL_HUB_Y = inp.Position.Y
        if NL_PICK_FN then
            local okP = pcall(NL_PICK_FN, NL_HUB_X, NL_HUB_Y)
            if not okP then NL_PICK_FN = nil end
        end
    end
end)
NL_HUB_UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseMovement then
        NL_SLIDE_FN = nil
        NL_PICK_FN = nil
    end
end)
game:GetService("RunService").RenderStepped:Connect(function()
    if NL_SLIDE_FN then
        local okS = pcall(NL_SLIDE_FN)
        if not okS then NL_SLIDE_FN = nil end
    end
end)
NL_HUB_UIS.InputBegan:Connect(function(key, focused)
    if focused then return end
    for i = 1, #NL_KEY_FNS do
        if NL_KEY_FNS[i] then pcall(NL_KEY_FNS[i], key) end
    end
end)

local function Notify(tt, tx)
    -- 0.48: SetCore может БЛОКИРОВАТЬ поток до загрузки CoreGui.
    -- Уведомление уходит отдельным потоком — загрузка зависнуть на нём не может.
    task.spawn(function()
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = tt,
                Text = tx,
                Duration = 5
            })
        end)
    end)
end

local function Dragify(frame, parent)

    parent = parent or frame

    local dragging = false
    local dragInput, mousePos, framePos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = parent.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    input.InputBegan:Connect(function(i2)
        if i2.UserInputType == Enum.UserInputType.Touch and dragging then
            dragInput = i2
        end
    end)

    input.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            parent.Position  = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

local function round(num, bracket)
    bracket = bracket or 1
    local a = math.floor(num/bracket + (math.sign(num) * 0.5)) * bracket
    if a < 0 then
        a = a + bracket
    end
    return a
end

local function buttoneffect(options)
    pcall(function()
        options.entered.MouseEnter:Connect(function()
            if options.frame.TextColor3 ~= Color3.fromRGB(234, 239, 246) then
                TweenService:Create(options.frame, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    TextColor3 = Color3.fromRGB(234, 239, 245)
                }):Play()
            end
        end)
        options.entered.MouseLeave:Connect(function()
            if options.frame.TextColor3 ~= Color3.fromRGB(157, 171, 182) and options.frame.TextColor3 ~= Color3.fromRGB(234, 239, 246) then
                TweenService:Create(options.frame, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    TextColor3 = Color3.fromRGB(157, 171, 182)
                }):Play()
            end
        end)
    end)
end

local function clickEffect(options)
    options.button.MouseButton1Click:Connect(function()
        local new = options.button.TextSize - tonumber(options.amount)
        local revert = new + tonumber(options.amount)
        TweenService:Create(options.button, TweenInfo.new(0.15, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {TextSize = new}):Play()
        wait(0.1)
        TweenService:Create(options.button, TweenInfo.new(0.1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {TextSize = revert}):Play()
    end)
end

-- P3: оригинал звал несуществующий метод — чиним через NL_SAVED_SG
function Library:Toggle(value)
    if not NL_SAVED_SG then return nil end
    if type(value) == "boolean" then
        NL_SAVED_SG.Enabled = value
    else
        NL_SAVED_SG.Enabled = not NL_SAVED_SG.Enabled
    end
    return NL_SAVED_SG.Enabled
end

function Library:Window(options)
    options.text = options.text or "NEVERLOSE"

    local SG = Instance.new("ScreenGui")
    local Body = Instance.new("Frame")
    Dragify(Body, Body)
    local bodyCorner = Instance.new("UICorner")

    local SideBar = Instance.new("Frame")
    local sidebarCorner = Instance.new("UICorner")
    local sbLine = Instance.new("Frame")

    local TopBar = Instance.new("Frame")
    local tbLine = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    --local saveBtn = Instance.new("TextButton")
    --local saveLabel = Instance.new("ImageLabel")

    local allPages = Instance.new("Frame")
    local tabContainer = Instance.new("Frame")

    SG.ResetOnSpawn = false
    SG.Name = "FUST_Neverlose"
    SG.Parent = NL_ROOT
    NL_SAVED_SG = SG
    if not NL_ROOT then
        local okP, rP = pcall(function()
            return game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
        end)
        if okP and rP then SG.Parent = rP end
    end

    Body.Name = "Body"
    Body.Parent = SG
    Body.AnchorPoint = Vector2.new(0.5, 0.5)
    Body.BackgroundColor3 = Color3.fromRGB(9, 8, 13)
    Body.BorderSizePixel = 0
    Body.Position = UDim2.new(0.475730786, 0, 0.5, 0)
    Body.Size = UDim2.new(0, 658, 0, 516)

    bodyCorner.CornerRadius = UDim.new(0, 4)
    bodyCorner.Name = "bodyCorner"
    bodyCorner.Parent = Body

    SideBar.Name = "SideBar"
    SideBar.Parent = Body
    SideBar.BackgroundColor3 = Color3.fromRGB(26, 36, 48)
    SideBar.BorderSizePixel = 0
    SideBar.Size = UDim2.new(0, 187, 0, 516)

    sidebarCorner.CornerRadius = UDim.new(0, 4)
    sidebarCorner.Name = "sidebarCorner"
    sidebarCorner.Parent = SideBar

    sbLine.Name = "sbLine"
    sbLine.Parent = SideBar
    sbLine.BackgroundColor3 = Color3.fromRGB(15, 23, 36)
    sbLine.BorderSizePixel = 0
    sbLine.Position = UDim2.new(0.99490571, 0, 0, 0)
    sbLine.Size = UDim2.new(0, 3, 0, 516)

    TopBar.Name = "TopBar"
    TopBar.Parent = Body
    TopBar.BackgroundColor3 = Color3.fromRGB(9, 8, 13)
    TopBar.BackgroundTransparency = 1.000
    TopBar.BorderColor3 = Color3.fromRGB(14, 21, 32)
    TopBar.BorderSizePixel = 0
    TopBar.Position = UDim2.new(0.25166446, 0, 0, 0)
    TopBar.Size = UDim2.new(0, 562, 0, 49)

    tbLine.Name = "tbLine"
    tbLine.Parent = TopBar
    tbLine.BackgroundColor3 = Color3.fromRGB(15, 23, 36)
    tbLine.BorderSizePixel = 0
    tbLine.Position = UDim2.new(0.0400355868, 0, 1, 0)
    tbLine.Size = UDim2.new(0, 469, 0, 3)

    Title.Name = "Title"
    Title.Parent = SideBar
    Title.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
    Title.BackgroundTransparency = 1.000
    Title.BorderSizePixel = 0
    Title.Position = UDim2.new(0.0614973232, 0, 0.0213178284, 0)
    Title.Size = UDim2.new(0, 162, 0, 26)
    Title.Font = Enum.Font.ArialBold
    Title.Text = options.text
    Title.TextColor3 = Color3.fromRGB(234, 239, 245)
    Title.TextSize = 28.000
    Title.TextWrapped = true

    --[[saveBtn.Name = "saveBtn"
    saveBtn.Parent = TopBar
    saveBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    saveBtn.BackgroundColor3 = Color3.fromRGB(9, 8, 13)
    saveBtn.Position = UDim2.new(0.146918148, 0, 0.479591846, 0)
    saveBtn.Size = UDim2.new(0, 88, 0, 20)
    saveBtn.AutoButtonColor = false
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.Text = "   Save"
    saveBtn.TextColor3 = Color3.fromRGB(132, 146, 153)
    saveBtn.TextSize = 14.000

    saveLabel.Name = "saveLabel"
    saveLabel.Parent = saveBtn
    saveLabel.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
    saveLabel.BackgroundTransparency = 1.000
    saveLabel.BorderSizePixel = 0
    saveLabel.Position = UDim2.new(0.0862553269, 0, 0.0500000007, 0)
    saveLabel.Size = UDim2.new(0, 18, 0, 18)
    saveLabel.Image = "rbxassetid://7999984136"
    saveLabel.ImageColor3 = Color3.fromRGB(132, 146, 153)
    ]]

    allPages.Name = "allPages"
    allPages.Parent = Body
    allPages.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
    allPages.BackgroundTransparency = 1.000
    allPages.BorderSizePixel = 0
    allPages.Position = UDim2.new(0.29508087, 0, 0.100775197, 0)
    allPages.Size = UDim2.new(0, 463, 0, 464)

    tabContainer.Name = "tabContainer"
    tabContainer.Parent = SideBar
    tabContainer.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
    tabContainer.BackgroundTransparency = 1.000
    tabContainer.BorderSizePixel = 0
    tabContainer.Position = UDim2.new(0, 0, 0.100775197, 0)
    tabContainer.Size = UDim2.new(0, 187, 0, 464)

    local tabsections = {}

    -- P10: наружу — управление окном
    tabsections.SG = SG
    tabsections.Body = Body
    tabsections.SideBar = SideBar
    tabsections.Library = Library
    tabsections.SetTitle = function(_, t)
        pcall(function() Title.Text = tostring(t or "") end)
    end
    tabsections.SetVisible = function(_, b)
        pcall(function() SG.Enabled = b and true or false end)
    end

    function tabsections:TabSection(options)
        options.text = options.text or "Tab Section"

        local tabLayout = Instance.new("UIListLayout")
        local tabSection = Instance.new("Frame")
        local tabSectionLabel = Instance.new("TextLabel")
        local tabSectionLayout = Instance.new("UIListLayout")

        tabLayout.Name = "tabLayout"
        tabLayout.Parent = tabContainer

        tabSection.Name = "tabSection"
        tabSection.Parent = tabContainer
        tabSection.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
        tabSection.BackgroundTransparency = 1.000
        tabSection.BorderSizePixel = 0
        tabSection.Size = UDim2.new(0, 189, 0, options.text == "" and 4 or 22)

        local function ResizeTS(num)
            tabSection.Size += UDim2.new(0, 0, 0, num)
        end

        tabSectionLabel.Name = "tabSectionLabel"
        tabSectionLabel.Parent = tabSection
        tabSectionLabel.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
        tabSectionLabel.BackgroundTransparency = 1.000
        tabSectionLabel.BorderSizePixel = 0
        tabSectionLabel.Size = UDim2.new(0, 190, 0, 22)
        tabSectionLabel.Font = Enum.Font.Gotham
        tabSectionLabel.Text = "     ".. options.text
        tabSectionLabel.TextColor3 = Color3.fromRGB(79, 107, 126)
        tabSectionLabel.TextSize = 13.000
        tabSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabSectionLabel.Visible = options.text ~= ''

        tabSectionLayout.Name = "tabSectionLayout"
        tabSectionLayout.Parent = tabSection
        tabSectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tabSectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabSectionLayout.Padding = UDim.new(0, 7)

        local tabs = {}

        function tabs:Tab(options)
            options.text = options.text or "New Tab"
            options.icon = options.icon or "rbxassetid://7999345313"

            local tabButton = Instance.new("TextButton")
            local tabButtonCorner = Instance.new("UICorner")
            local tabIcon = Instance.new("ImageLabel")

            local newPage = Instance.new("ScrollingFrame")
            local pageLayout = Instance.new("UIGridLayout")

            tabButton.Name = "tabButton"
            tabButton.Parent = tabSection
            tabButton.BackgroundColor3 = Color3.fromRGB(78, 22, 18)
            tabButton.BorderSizePixel = 0
            tabButton.Position = UDim2.new(0.0714285746, 0, 0.402777791, 0)
            tabButton.Size = UDim2.new(0, 165, 0, 26)
            tabButton.AutoButtonColor = false
            tabButton.Font = Enum.Font.GothamSemibold
            tabButton.Text = "        " .. options.text
            tabButton.TextColor3 = Color3.fromRGB(234, 239, 245)
            tabButton.TextSize = 13.000
            tabButton.BackgroundTransparency = 1
            tabButton.TextXAlignment = Enum.TextXAlignment.Left
            tabButton.MouseButton1Click:Connect(function()
                for i,v in next, allPages:GetChildren() do
                    v.Visible = false
                end

                newPage.Visible = true

                for i,v in next, SideBar:GetDescendants() do
                    if v:IsA("TextButton") then
                        TweenService:Create(v, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                            BackgroundTransparency = 1
                        }):Play()
                    end
                end

                TweenService:Create(tabButton, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    BackgroundTransparency = 0
                }):Play()
            end)

            tabButtonCorner.CornerRadius = UDim.new(0, 4)
            tabButtonCorner.Name = "tabButtonCorner"
            tabButtonCorner.Parent = tabButton

            tabIcon.Name = "tabIcon"
            tabIcon.Parent = tabButton
            tabIcon.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
            tabIcon.BackgroundTransparency = 1.000
            tabIcon.BorderSizePixel = 0
            tabIcon.Position = UDim2.new(0.0408859849, 0, 0.133333355, 0)
            tabIcon.Size = UDim2.new(0, 16, 0, 16)
            tabIcon.Image = options.icon
            tabIcon.ImageColor3 = Color3.fromRGB(255, 99, 88)

            newPage.Name = "newPage"
            newPage.Parent = allPages
            newPage.Visible = false
            newPage.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
            newPage.BackgroundTransparency = 1.000
            newPage.BorderSizePixel = 0
            newPage.ClipsDescendants = false
            newPage.Position = UDim2.new(0.021598272, 0, 0.0237068962, 0)
            newPage.Size = UDim2.new(0, 442, 0, 440)
            newPage.ScrollBarThickness = 4
            newPage.CanvasSize = UDim2.new(0,0,0,0)

            pageLayout.Name = "pageLayout"
            pageLayout.Parent = newPage
            pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
            pageLayout.CellPadding = UDim2.new(0, 12, 0, 12)
            pageLayout.CellSize = UDim2.new(0, 215, 0, -10)
            pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                newPage.CanvasSize = UDim2.new(0,0,0,pageLayout.AbsoluteContentSize.Y) 
            end)

            ResizeTS(33)

            local sections = {}

            function sections:Section(options)
                options.text = options.text or "Section"

                local sectionFrame = Instance.new("Frame")
                local sectionLabel = Instance.new("TextLabel")
                local sectionFrameCorner = Instance.new("UICorner")
                local sectionLayout = Instance.new("UIListLayout")
                local sLine = Instance.new("TextLabel")
                local sectionSizeConstraint = Instance.new("UISizeConstraint")

                sectionFrame.Name = "sectionFrame"
                sectionFrame.Parent = newPage
                sectionFrame.BackgroundColor3 = Color3.fromRGB(0, 15, 30)
                sectionFrame.BorderSizePixel = 0
                sectionFrame.Size = UDim2.new(0, 215, 0, 134)

                sectionLabel.Name = "sectionLabel"
                sectionLabel.Parent = sectionFrame
                sectionLabel.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
                sectionLabel.BackgroundTransparency = 1.000
                sectionLabel.BorderSizePixel = 0
                sectionLabel.Position = UDim2.new(0.0121902823, 0, 0, 0)
                sectionLabel.Size = UDim2.new(0, 213, 0, 25)
                sectionLabel.Font = Enum.Font.GothamSemibold
                sectionLabel.Text = "   " .. options.text
                sectionLabel.TextColor3 = Color3.fromRGB(234, 239, 245)
                sectionLabel.TextSize = 14.000
                sectionLabel.TextXAlignment = Enum.TextXAlignment.Left

                sectionFrameCorner.CornerRadius = UDim.new(0, 4)
                sectionFrameCorner.Name = "sectionFrameCorner"
                sectionFrameCorner.Parent = sectionFrame

                sectionLayout.Name = "sectionLayout"
                sectionLayout.Parent = sectionFrame
                sectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
                sectionLayout.Padding = UDim.new(0, 2)

                sLine.Name = "sLine"
                sLine.Parent = sectionFrame
                sLine.BackgroundColor3 = Color3.fromRGB(13, 28, 44)
                sLine.BorderSizePixel = 0
                sLine.Position = UDim2.new(0.0255813953, 0, 0.41538462, 0)
                sLine.Size = UDim2.new(0, 202, 0, 3)
                sLine.Font = Enum.Font.SourceSans
                sLine.Text = ""
                sLine.TextColor3 = Color3.fromRGB(0, 0, 0)
                sLine.TextSize = 0

                sectionSizeConstraint.Name = "sectionSizeConstraint"
                sectionSizeConstraint.Parent = sectionFrame
                sectionSizeConstraint.MinSize = Vector2.new(215, 35)

                local function Resize(num)
                    sectionSizeConstraint.MinSize += Vector2.new(0, num)
                end

                local elements = {}
                elements.Frame = sectionFrame

                function elements:Button(options)
                    if not options.text or not options.callback then Notify("Button", "Missing arguments!") return end

                    local TextButton = Instance.new("TextButton")

                    TextButton.Parent = sectionFrame
                    TextButton.BackgroundColor3 = Color3.fromRGB(78, 22, 18)
                    TextButton.BorderSizePixel = 0
                    TextButton.Position = UDim2.new(0.0348837227, 0, 0.355555564, 0)
                    TextButton.Size = UDim2.new(0, 200, 0, 22)
                    TextButton.AutoButtonColor = false
                    TextButton.Text = options.text
                    TextButton.Font = Enum.Font.Gotham
                    TextButton.TextColor3 = Color3.fromRGB(157, 171, 182)
                    TextButton.TextSize = 14.000
                    TextButton.BackgroundTransparency = 1
                    buttoneffect({frame = TextButton, entered = TextButton})
                    clickEffect({button = TextButton, amount = 5})
                    TextButton.MouseButton1Click:Connect(function()
                        options.callback()
                    end)

                    Resize(25)
                    -- P6: объект кнопки
                    local self = {}
                    function self:Fire() options.callback() end
                    self.Instance = TextButton
                    return self
                end

                function elements:Toggle(options)
                    if not options.text or not options.callback then Notify("Toggle", "Missing arguments!") return end

                    local toggleLabel = Instance.new("TextLabel")
                    local toggleFrame = Instance.new("TextButton")
                    local togFrameCorner = Instance.new("UICorner")
                    local toggleButton = Instance.new("TextButton")
                    local togBtnCorner = Instance.new("UICorner")

                    local State = options.state or false

                    if options.state then
                        toggleButton.Position = UDim2.new(0.74, 0, 0.5, 0)
                        toggleLabel.TextColor3 = Color3.fromRGB(234, 239, 246)
                        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
                        toggleFrame.BackgroundColor3 = Color3.fromRGB(51, 12, 10)
                    end

                    toggleLabel.Name = "toggleLabel"
                    toggleLabel.Parent = sectionFrame
                    toggleLabel.BackgroundColor3 = Color3.fromRGB(157, 171, 182)
                    toggleLabel.BackgroundTransparency = 1.000
                    toggleLabel.Position = UDim2.new(0.0348837227, 0, 0.965517223, 0)
                    toggleLabel.Size = UDim2.new(0, 200, 0, 22)
                    toggleLabel.Font = Enum.Font.Gotham
                    toggleLabel.Text = " " .. options.text
                    toggleLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    toggleLabel.TextSize = 14.000
                    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    buttoneffect({frame = toggleLabel, entered = toggleLabel})

                    local function PerformToggle()
                        State = not State
                        options.callback(State)
                        TweenService:Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            Position = State and UDim2.new(0.74, 0, 0.5, 0) or UDim2.new(0.25, 0, 0.5, 0)
                        }):Play()
                        TweenService:Create(toggleLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            TextColor3 = State and Color3.fromRGB(234, 239, 246) or Color3.fromRGB(157, 171, 182)
                        }):Play()
                        TweenService:Create(toggleButton, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            BackgroundColor3 = State and Color3.fromRGB(255, 59, 48) or Color3.fromRGB(77, 77, 77)
                        }):Play()
                        TweenService:Create(toggleFrame, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            BackgroundColor3 = State and Color3.fromRGB(51, 12, 10) or Color3.fromRGB(4, 4, 11)
                        }):Play()
                    end

                    toggleFrame.Name = "toggleFrame"
                    toggleFrame.Parent = toggleLabel
                    toggleFrame.BackgroundColor3 = Color3.fromRGB(4, 4, 11)
                    toggleFrame.BorderSizePixel = 0
                    toggleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                    toggleFrame.Position = UDim2.new(0.9, 0, 0.5, 0)
                    toggleFrame.Size = UDim2.new(0, 38, 0, 18)
                    toggleFrame.AutoButtonColor = false
                    toggleFrame.Font = Enum.Font.SourceSans
                    toggleFrame.Text = ""
                    toggleFrame.TextColor3 = Color3.fromRGB(0, 0, 0)
                    toggleFrame.TextSize = 14.000
                    toggleFrame.MouseButton1Click:Connect(function()
                        PerformToggle()
                    end)

                    togFrameCorner.CornerRadius = UDim.new(0, 50)
                    togFrameCorner.Name = "togFrameCorner"
                    togFrameCorner.Parent = toggleFrame

                    toggleButton.Name = "toggleButton"
                    toggleButton.Parent = toggleFrame
                    toggleButton.BackgroundColor3 = Color3.fromRGB(77, 77, 77)
                    toggleButton.BorderSizePixel = 0
                    toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
                    toggleButton.Position = UDim2.new(0.25, 0, 0.5, 0)
                    toggleButton.Size = UDim2.new(0, 16, 0, 16)
                    toggleButton.AutoButtonColor = false
                    toggleButton.Font = Enum.Font.SourceSans
                    toggleButton.Text = ""
                    toggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
                    toggleButton.TextSize = 14.000
                    toggleButton.MouseButton1Click:Connect(function()
                        PerformToggle()
                    end)

                    togBtnCorner.CornerRadius = UDim.new(0, 50)
                    togBtnCorner.Name = "togFrameCorner"
                    togBtnCorner.Parent = toggleButton

                    Resize(25)
                    -- P6: возвращаем объект для конфигов
                    local self = {}
                    function self:Set(v, silent)
                        v = v and true or false
                        if v == State then return end
                        State = v
                        if not silent then options.callback(State) end
                        TweenService:Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            Position = State and UDim2.new(0.74, 0, 0.5, 0) or UDim2.new(0.25, 0, 0.5, 0)
                        }):Play()
                        TweenService:Create(toggleLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            TextColor3 = State and Color3.fromRGB(234, 239, 246) or Color3.fromRGB(157, 171, 182)
                        }):Play()
                        TweenService:Create(toggleButton, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            BackgroundColor3 = State and Color3.fromRGB(255, 59, 48) or Color3.fromRGB(77, 77, 77)
                        }):Play()
                        TweenService:Create(toggleFrame, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            BackgroundColor3 = State and Color3.fromRGB(51, 12, 10) or Color3.fromRGB(4, 4, 11)
                        }):Play()
                    end
                    function self:Get() return State end
                    self.Value = function() return State end
                    self.Instance = toggleLabel
                    return self
                end

                function elements:Slider(options)
                    if not options.text or not options.min or not options.max or not options.callback then Notify("Slider", "Missing arguments!") return end

                    local Slider = Instance.new("Frame")
                    local sliderLabel = Instance.new("TextLabel")
                    local sliderFrame = Instance.new("TextButton")
                    local sliderBall = Instance.new("TextButton")
                    local sliderBallCorner = Instance.new("UICorner")
                    local sliderTextBox = Instance.new("TextBox")
                    buttoneffect({frame = sliderLabel, entered = Slider})

                    local Value

                    local UIS = game:GetService("UserInputService")

                    local percentage = 0
                    local step = 0.01
                    -- 0.49 P13: позицию пальца/мыши даёт общий хаб (NL_HUB_X)

                    local function snap(number, factor)
                        if factor == 0 then
                            return number
                        else
                            return math.floor(number/factor+0.5)*factor
                        end
                    end

                    -- 0.49 P13: обновление слайдера — одна функция на элемент,
                    -- крутит общий хаб, пока палец зажат
                    local function sliderUpdate()
                        local BtnPos = sliderBall.Position
                        local MousePos = NL_HUB_X or UIS:GetMouseLocation().X
                        local FrameSize = sliderFrame.AbsoluteSize.X
                        local FramePos = sliderFrame.AbsolutePosition.X
                        local pos = snap((MousePos-FramePos)/FrameSize,step)
                        percentage = math.clamp(pos,0,0.9)

                        Value = ((((tonumber(options.max) - tonumber(options.min)) / 0.9) * percentage)) + tonumber(options.min)
                        Value = round(Value, options.float)
                        Value = math.clamp(Value, options.min, options.max)
                        sliderTextBox.Text = Value
                        options.callback(Value)
                        sliderBall.Position = UDim2.new(percentage,0,BtnPos.Y.Scale, BtnPos.Y.Offset)
                    end

                    Slider.Name = "Slider"
                    Slider.Parent = sectionFrame
                    Slider.BackgroundColor3 = Color3.fromRGB(157, 171, 182)
                    Slider.BackgroundTransparency = 1.000
                    Slider.Position = UDim2.new(0.0395348854, 0, 0.947335422, 0)
                    Slider.Size = UDim2.new(0, 200, 0, 22)

                    sliderLabel.Name = "sliderLabel"
                    sliderLabel.Parent = Slider
                    sliderLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    sliderLabel.BackgroundColor3 = Color3.fromRGB(157, 171, 182)
                    sliderLabel.BackgroundTransparency = 1.000
                    sliderLabel.Position = UDim2.new(0.2, 0, 0.5, 0)
                    sliderLabel.Size = UDim2.new(0, 77, 0, 22)
                    sliderLabel.Font = Enum.Font.Gotham
                    sliderLabel.Text = " " .. options.text
                    sliderLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    sliderLabel.TextSize = 14.000
                    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                    sliderLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
                        if sliderLabel.TextBounds.X > 75 then
                            sliderLabel.TextScaled = true
                        else
                            sliderLabel.TextScaled = false
                        end
                    end)

                    sliderFrame.Name = "sliderFrame"
                    sliderFrame.Parent = sliderLabel
                    sliderFrame.BackgroundColor3 = Color3.fromRGB(110, 34, 28)
                    sliderFrame.BorderSizePixel = 0
                    sliderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                    sliderFrame.Position = UDim2.new(1.6, 0, 0.5, 0)
                    sliderFrame.Size = UDim2.new(0, 72, 0, 2)
                    sliderFrame.Text = ""
                    sliderFrame.AutoButtonColor = false
                    sliderFrame.MouseButton1Down:Connect(function()
                        NL_SLIDE_FN = sliderUpdate
                    end)

                    sliderBall.Name = "sliderBall"
                    sliderBall.Parent = sliderFrame
                    sliderBall.AnchorPoint = Vector2.new(0.5, 0.5)
                    sliderBall.BackgroundColor3 = Color3.fromRGB(255, 94, 84)
                    sliderBall.BorderSizePixel = 0
                    sliderBall.Position = UDim2.new(0, 0, 0.5, 0)
                    sliderBall.Size = UDim2.new(0, 14, 0, 14)
                    sliderBall.AutoButtonColor = false
                    sliderBall.Font = Enum.Font.SourceSans
                    sliderBall.Text = ""
                    sliderBall.TextColor3 = Color3.fromRGB(0, 0, 0)
                    sliderBall.TextSize = 14.000
                    sliderBall.MouseButton1Down:Connect(function()
                        NL_SLIDE_FN = sliderUpdate
                    end)

                    local function setByValue(v, silent)
                        v = tonumber(v) or options.min
                        v = math.clamp(v, options.min, options.max)
                        Value = v
                        percentage = math.clamp((v - options.min) / ((options.max - options.min) / 0.9), 0, 0.9)
                        sliderTextBox.Text = tostring(Value)
                        sliderBall.Position = UDim2.new(percentage, 0, 0.5, 0)
                        if not silent then options.callback(Value) end
                    end
                    -- 0.49 P13: личный RenderStepped удалён — рендерит общий хаб
                    -- P4: стартовое значение
                    if options.default ~= nil then
                        setByValue(options.default, true)
                    else
                        sliderTextBox.Text = tostring(options.min)
                        Value = options.min
                    end

                    sliderBallCorner.CornerRadius = UDim.new(0, 50)
                    sliderBallCorner.Name = "sliderBallCorner"
                    sliderBallCorner.Parent = sliderBall

                    sliderTextBox.Name = "sliderTextBox"
                    sliderTextBox.Parent = sliderLabel
                    sliderTextBox.BackgroundColor3 = Color3.fromRGB(1, 7, 17)
                    sliderTextBox.AnchorPoint = Vector2.new(0.5, 0.5)
                    sliderTextBox.Position = UDim2.new(2.4, 0, 0.5, 0)
                    sliderTextBox.Size = UDim2.new(0, 31, 0, 15)
                    sliderTextBox.Font = Enum.Font.Gotham
                    sliderTextBox.Text = options.min
                    sliderTextBox.TextColor3 = Color3.fromRGB(234, 239, 245)
                    sliderTextBox.TextSize = 11.000
                    sliderTextBox.TextWrapped = true

                    sliderTextBox.Focused:Connect(function()
                        TweenService:Create(sliderLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {TextColor3 = Color3.fromRGB(234, 239, 246)}):Play()
                    end)

                    sliderTextBox.FocusLost:Connect(function(Enter)
                        TweenService:Create(sliderLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {TextColor3 = Color3.fromRGB(157, 171, 182)}):Play()
                        if Enter then
                            if sliderTextBox.Text ~= nil and sliderTextBox.Text ~= "" then
                                if tonumber(sliderTextBox.Text) > options.max then
                                    setByValue(options.max, false)
                                elseif tonumber(sliderTextBox.Text) < options.min then
                                    setByValue(options.min, false)
                                else
                                    setByValue(tonumber(sliderTextBox.Text), false)
                                end
                            end
                        end
                    end)

                    Resize(25)
                    -- P6: объект слайдера
                    local self = {}
                    function self:Set(v, silent) setByValue(v, silent) end
                    function self:Get() return Value end
                    self.Value = function() return Value end
                    self.Instance = sliderLabel
                    return self
                end

                function elements:Dropdown(options)
                    if not options.text or not options.default or not options.list or not options.callback then Notify("Dropdown", "Missing arguments!") return end

                    local DropYSize = 0
                    local Dropped = false

                    local Dropdown = Instance.new("Frame")
                    local dropdownLabel = Instance.new("TextLabel")
                    local dropdownText = Instance.new("TextLabel")
                    local dropdownArrow = Instance.new("ImageButton")
                    local dropdownList = Instance.new("Frame")

                    local dropListLayout = Instance.new("UIListLayout")
                    buttoneffect({frame = dropdownLabel, entered = Dropdown})

                    Dropdown.Name = "Dropdown"
                    Dropdown.Parent = sectionFrame
                    Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Dropdown.BackgroundTransparency = 1.000
                    Dropdown.BorderSizePixel = 0
                    Dropdown.Position = UDim2.new(0.0697674453, 0, 0.237037033, 0)
                    Dropdown.Size = UDim2.new(0, 200, 0, 22)
                    Dropdown.ZIndex = 2

                    dropdownLabel.Name = "dropdownLabel"
                    dropdownLabel.Parent = Dropdown
                    dropdownLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    dropdownLabel.BackgroundTransparency = 1.000
                    dropdownLabel.BorderSizePixel = 0
                    dropdownLabel.Size = UDim2.new(0, 105, 0, 22)
                    dropdownLabel.Font = Enum.Font.Gotham
                    dropdownLabel.Text = " " .. options.text
                    dropdownLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    dropdownLabel.TextSize = 14.000
                    dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                    dropdownLabel.TextWrapped = true

                    dropdownText.Name = "dropdownText"
                    dropdownText.Parent = dropdownLabel
                    dropdownText.BackgroundColor3 = Color3.fromRGB(2, 5, 12)
                    dropdownText.Position = UDim2.new(1.08571434, 0, 0.0909090936, 0)
                    dropdownText.Size = UDim2.new(0, 87, 0, 18)
                    dropdownText.Font = Enum.Font.Gotham
                    dropdownText.Text = " " .. (type(options.default) == "table" and tostring(options.default[1] or "") or tostring(options.default or ""))
                    dropdownText.TextColor3 = Color3.fromRGB(234, 239, 245)
                    dropdownText.TextSize = 12.000
                    dropdownText.TextXAlignment = Enum.TextXAlignment.Left
                    dropdownText.TextWrapped = true

                    dropdownArrow.Name = "dropdownArrow"
                    dropdownArrow.Parent = dropdownText
                    dropdownArrow.BackgroundColor3 = Color3.fromRGB(2, 5, 12)
                    dropdownArrow.BorderSizePixel = 0
                    dropdownArrow.Position = UDim2.new(0.87356323, 0, 0.138888866, 0)
                    dropdownArrow.Size = UDim2.new(0, 11, 0, 13)
                    dropdownArrow.AutoButtonColor = false
                    dropdownArrow.Image = "rbxassetid://8008296380"
                    dropdownArrow.ImageColor3 = Color3.fromRGB(157, 171, 182)

                    dropdownArrow.MouseButton1Click:Connect(function()
                        Dropped = not Dropped
                        if Dropped then
                            if dropdownLabel.TextColor3 ~= Color3.fromRGB(234, 239, 245) then
                                TweenService:Create(dropdownLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                    TextColor3 = Color3.fromRGB(234, 239, 246)
                                }):Play()
                            end
                            TweenService:Create(dropdownList, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                Size = UDim2.new(0, 87, 0, DropYSize)
                            }):Play()
                            TweenService:Create(dropdownList, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                BorderSizePixel = 1
                            }):Play()
                        elseif not Dropped then
                            if dropdownLabel.TextColor3 ~= Color3.fromRGB(157, 171, 182) then
                                TweenService:Create(dropdownLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                    TextColor3 = Color3.fromRGB(157, 171, 182)
                                }):Play()
                            end
                            TweenService:Create(dropdownList, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                Size = UDim2.new(0, 87, 0, 0)
                            }):Play()
                            TweenService:Create(dropdownList, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                BorderSizePixel = 0
                            }):Play()
                        end
                    end)

                    dropdownList.Name = "dropdownList"
                    dropdownList.Parent = dropdownText
                    dropdownList.BackgroundColor3 = Color3.fromRGB(2, 5, 12)
                    dropdownList.Position = UDim2.new(0, 0, 1, 0)
                    dropdownList.Size = UDim2.new(0, 87, 0, 0)
                    dropdownList.ClipsDescendants = true
                    dropdownList.BorderSizePixel = 0
                    dropdownList.ZIndex = 10

                    dropListLayout.Name = "dropListLayout"
                    dropListLayout.Parent = dropdownList
                    dropListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    Resize(25)

                    -- P8: Multi-режим + P6: объект
                    local multi = options.multi == true
                    local selected = {}
                    if multi then
                        -- Default может быть строкой или таблицей
                        if type(options.default) == "string" then
                            selected[options.default] = true
                        elseif type(options.default) == "table" then
                            for _, dv in ipairs(options.default) do selected[dv] = true end
                        end
                    end
                    local function selectedText()
                        if not multi then return dropdownText.Text end
                        local n = 0
                        for _ in pairs(selected) do n = n + 1 end
                        return " выбрано: " .. n
                    end

                    local listButtons = {}
                    local function buildList()
                        for _, ch in ipairs(dropdownList:GetChildren()) do
                            if ch:IsA("TextButton") then ch:Destroy() end
                        end
                        DropYSize = 0
                        for i,v in next, options.list do
                            local dropdownBtn = Instance.new("TextButton")

                            dropdownBtn.Name = "dropdownBtn"
                            dropdownBtn.Parent = dropdownList
                            dropdownBtn.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
                            dropdownBtn.BackgroundTransparency = 1.000
                            dropdownBtn.BorderSizePixel = 0
                            dropdownBtn.Size = UDim2.new(0, 87, 0, 18)
                            dropdownBtn.AutoButtonColor = false
                            dropdownBtn.Font = Enum.Font.Gotham
                            dropdownBtn.TextColor3 = (multi and selected[v]) and Color3.fromRGB(255, 59, 48) or Color3.fromRGB(234, 239, 245)
                            dropdownBtn.TextSize = 12.000
                            dropdownBtn.Text = (multi and selected[v]) and ("+ " .. v) or v
                            dropdownBtn.ZIndex = 15
                            clickEffect({button = dropdownBtn, amount = 5})

                            DropYSize = DropYSize + 18
                            listButtons[v] = dropdownBtn

                            dropdownBtn.MouseButton1Click:Connect(function()
                                if multi then
                                    selected[v] = not selected[v]
                                    dropdownBtn.Text = selected[v] and ("+ " .. v) or v
                                    dropdownBtn.TextColor3 = selected[v] and Color3.fromRGB(255, 59, 48) or Color3.fromRGB(234, 239, 245)
                                    local list = {}
                                    for lv in pairs(selected) do table.insert(list, lv) end
                                    dropdownText.Text = selectedText()
                                    options.callback(list)
                                else
                                    dropdownText.Text = " " .. v
                                    options.callback(v)
                                end
                            end)
                        end
                    end
                    buildList()
                    if multi then
                        dropdownText.Text = selectedText()
                    end

                    -- P6: объект дропдауна
                    local self = {}
                    function self:Set(v, silent)
                        if multi then
                            if type(v) == "string" then v = { v } end
                            selected = {}
                            if type(v) == "table" then
                                for _, dv in ipairs(v) do selected[dv] = true end
                            end
                            buildList()
                            dropdownText.Text = selectedText()
                            if not silent then
                                local list = {}
                                for lv in pairs(selected) do table.insert(list, lv) end
                                options.callback(list)
                            end
                        else
                            if v ~= nil then
                                dropdownText.Text = " " .. tostring(v)
                                if not silent then options.callback(v) end
                            end
                        end
                    end
                    function self:Get()
                        if multi then
                            local list = {}
                            for lv in pairs(selected) do table.insert(list, lv) end
                            return list
                        end
                        return (dropdownText.Text:gsub("^%s+", ""))
                    end
                    self.Value = self.Get
                    function self:SetOptions(newList)
                        options.list = newList or {}
                        if multi then selected = {} end
                        buildList()
                        if multi then dropdownText.Text = selectedText() end
                    end
                    self.SetValues = self.SetOptions
                    self.Instance = dropdownLabel
                    return self
                end

                -- P7: Label (в Neverlose не было)
                function elements:Label(text)
                    text = tostring(text or "")
                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "nlLabel"
                    lbl.Parent = sectionFrame
                    lbl.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
                    lbl.BackgroundTransparency = 1.000
                    lbl.BorderSizePixel = 0
                    lbl.Size = UDim2.new(0, 200, 0, 22)
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = " " .. text
                    lbl.TextColor3 = Color3.fromRGB(157, 171, 182)
                    lbl.TextSize = 14.000
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.TextWrapped = false
                    Resize(22)
                    local self = {}
                    function self:SetText(t) lbl.Text = " " .. tostring(t) end
                    self.SetTitle = self.SetText
                    function self:Get() return lbl.Text end
                    self.Value = self.Get
                    function self:SetVisible(b) lbl.Visible = b and true or false end
                    self.Instance = lbl
                    return self
                end

                -- P7: Paragraph (многострочный текст)
                function elements:Paragraph(options)
                    options = options or {}
                    local title = tostring(options.text or options.title or "")
                    local content = tostring(options.content or "")
                    local holder = Instance.new("Frame")
                    holder.Name = "nlParagraph"
                    holder.Parent = sectionFrame
                    holder.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
                    holder.BackgroundTransparency = 1.000
                    holder.BorderSizePixel = 0
                    holder.Size = UDim2.new(0, 200, 0, 22)
                    local tt = Instance.new("TextLabel")
                    tt.Name = "title"
                    tt.Parent = holder
                    tt.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
                    tt.BackgroundTransparency = 1.000
                    tt.BorderSizePixel = 0
                    tt.Size = UDim2.new(0, 200, 0, title ~= "" and 16 or 0)
                    tt.Font = Enum.Font.GothamSemibold
                    tt.Text = " " .. title
                    tt.TextColor3 = Color3.fromRGB(234, 239, 245)
                    tt.TextSize = 13.000
                    tt.TextXAlignment = Enum.TextXAlignment.Left
                    tt.TextWrapped = true
                    tt.Visible = title ~= ""
                    local cc = Instance.new("TextLabel")
                    cc.Name = "content"
                    cc.Parent = holder
                    cc.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
                    cc.BackgroundTransparency = 1.000
                    cc.BorderSizePixel = 0
                    cc.Position = UDim2.new(0, 0, 0, title ~= "" and 16 or 0)
                    cc.Size = UDim2.new(0, 200, 0, 18)
                    cc.Font = Enum.Font.Gotham
                    cc.Text = " " .. content
                    cc.TextColor3 = Color3.fromRGB(157, 171, 182)
                    cc.TextSize = 12.000
                    cc.TextXAlignment = Enum.TextXAlignment.Left
                    cc.TextYAlignment = Enum.TextYAlignment.Top
                    cc.TextWrapped = true
                    -- авто-высота по содержимому
                    cc:GetPropertyChangedSignal("TextBounds"):Connect(function()
                        local lines = math.max(1, math.ceil(cc.TextBounds.Y / 16))
                        cc.Size = UDim2.new(0, 200, 0, lines * 16)
                        holder.Size = UDim2.new(0, 200, 0, (title ~= "" and 16 or 0) + lines * 16 + 4)
                    end)
                    holder.Size = UDim2.new(0, 200, 0, (title ~= "" and 16 or 0) + 18 + 4)
                    Resize((title ~= "" and 16 or 0) + 18 + 4)
                    local self = {}
                    function self:SetText(t) cc.Text = " " .. tostring(t) end
                    function self:SetTitle(t) tt.Text = " " .. tostring(t) end
                    function self:Set(v)
                        if type(v) == "table" and v.Content then cc.Text = " " .. tostring(v.Content)
                        else cc.Text = " " .. tostring(v) end
                    end
                    function self:SetVisible(b) holder.Visible = b and true or false end
                    self.Instance = holder
                    return self
                end

                function elements:Textbox(options)
                    if not options.text or not options.value or not options.callback then Notify("Textbox", "Missing arguments!") return end

                    local Textbox = Instance.new("Frame")
                    local textBoxLabel = Instance.new("TextLabel")
                    local textBox = Instance.new("TextBox")

                    Textbox.Name = "Textbox"
                    Textbox.Parent = sectionFrame
                    Textbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Textbox.BackgroundTransparency = 1.000
                    Textbox.BorderSizePixel = 0
                    Textbox.Position = UDim2.new(0.0348837227, 0, 0.945454538, 0)
                    Textbox.Size = UDim2.new(0, 200, 0, 22)
                    buttoneffect({frame = textBoxLabel, entered = Textbox})

                    textBoxLabel.Name = "textBoxLabel"
                    textBoxLabel.Parent = Textbox
                    textBoxLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    textBoxLabel.BackgroundColor3 = Color3.fromRGB(157, 171, 182)
                    textBoxLabel.BackgroundTransparency = 1.000
                    textBoxLabel.Position = UDim2.new(0.237000003, 0, 0.5, 0)
                    textBoxLabel.Size = UDim2.new(0, 99, 0, 22)
                    textBoxLabel.Font = Enum.Font.Gotham
                    textBoxLabel.Text = "  " .. options.text
                    textBoxLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    textBoxLabel.TextSize = 14.000
                    textBoxLabel.TextXAlignment = Enum.TextXAlignment.Left

                    textBox.Name = "textBox"
                    textBox.Parent = Textbox
                    textBox.AnchorPoint = Vector2.new(0.5, 0.5)
                    textBox.BackgroundColor3 = Color3.fromRGB(1, 7, 17)
                    textBox.Position = UDim2.new(0.850000024, 0, 0.5, 0)
                    textBox.Size = UDim2.new(0, 53, 0, 15)
                    textBox.Font = Enum.Font.Gotham
                    textBox.Text = options.value
                    textBox.TextColor3 = Color3.fromRGB(234, 239, 245)
                    textBox.TextSize = 11.000
                    textBox.TextWrapped = true

                    Resize(25)

                    textBox.Focused:Connect(function()
                        TweenService:Create(textBoxLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextColor3 = Color3.fromRGB(234, 239, 246)}):Play()
                    end)

                    textBox.FocusLost:Connect(function(Enter)
                        TweenService:Create(textBoxLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextColor3 = Color3.fromRGB(157, 171, 182)}):Play()
                        if Enter then
                            if textBox.Text ~= nil and textBox.Text ~= "" then
                                options.callback(textBox.Text)
                            end
                        end
                    end)
                    -- P6: объект текстбокса
                    local self = {}
                    function self:Set(v) textBox.Text = tostring(v or "") end
                    function self:Get() return textBox.Text end
                    self.Value = self.Get
                    self.Instance = textBoxLabel
                    return self
                end

                function elements:Colorpicker(options)
                    if not options.text or not options.color or not options.callback then Notify("Colorpicker", "Missing arguments!") return end


                    local hue, sat, val = Color3.toHSV(options.color)

                    local Colorpicker = Instance.new("Frame")
                    local colorpickerLabel = Instance.new("TextLabel")
                    local colorpickerButton = Instance.new("ImageButton")
                    local colorpickerFrame = Instance.new("Frame")
                    local RGB = Instance.new("ImageButton")
                    local RGBCircle = Instance.new("ImageLabel")
                    local Darkness = Instance.new("ImageButton")
                    local DarknessCircle = Instance.new("Frame")
                    local colorHex = Instance.new("TextLabel")
                    local Copy = Instance.new("TextButton")
                    buttoneffect({frame = colorpickerLabel, entered = Colorpicker})

                    local vis = false 

                    Colorpicker.Name = "Colorpicker"
                    Colorpicker.Parent = sectionFrame
                    Colorpicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Colorpicker.BackgroundTransparency = 1.000
                    Colorpicker.BorderSizePixel = 0
                    Colorpicker.Position = UDim2.new(0.0348837227, 0, 0.945454538, 0)
                    Colorpicker.Size = UDim2.new(0, 200, 0, 22)
                    Colorpicker.ZIndex = 2

                    colorpickerLabel.Name = "colorpickerLabel"
                    colorpickerLabel.Parent = Colorpicker
                    colorpickerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    colorpickerLabel.BackgroundColor3 = Color3.fromRGB(157, 171, 182)
                    colorpickerLabel.BackgroundTransparency = 1.000
                    colorpickerLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                    colorpickerLabel.Size = UDim2.new(0, 200, 0, 22)
                    colorpickerLabel.Font = Enum.Font.Gotham
                    colorpickerLabel.Text = " " .. options.text
                    colorpickerLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    colorpickerLabel.TextSize = 14.000
                    colorpickerLabel.TextXAlignment = Enum.TextXAlignment.Left

                    colorpickerButton.Name = "colorpickerButton"
                    colorpickerButton.Parent = colorpickerLabel
                    colorpickerButton.AnchorPoint = Vector2.new(0.5, 0.5)
                    colorpickerButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    colorpickerButton.BackgroundTransparency = 1.000
                    colorpickerButton.BorderSizePixel = 0
                    colorpickerButton.Position = UDim2.new(0.920, 0, 0.57, 0)
                    colorpickerButton.Size = UDim2.new(0, 15, 0, 15)
                    colorpickerButton.Image = "rbxassetid://8023491332"
                    colorpickerButton.MouseButton1Click:Connect(function()
                        colorpickerFrame.Visible = not colorpickerFrame.Visible
                        vis = not vis
                        TweenService:Create(colorpickerLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            TextColor3 = vis and Color3.fromRGB(234, 239, 246) or Color3.fromRGB(157, 171, 182)
                        }):Play()
                    end)

                    colorpickerFrame.Name = "colorpickerFrame"
                    colorpickerFrame.Parent = Colorpicker
                    colorpickerFrame.Visible = false
                    colorpickerFrame.BackgroundColor3 = Color3.fromRGB(0, 10, 21)
                    colorpickerFrame.Position = UDim2.new(1.15, 0, 0.5, 0)
                    colorpickerFrame.Size = UDim2.new(0, 251, 0, 221)
                    colorpickerFrame.ZIndex = 15
                    Dragify(colorpickerFrame, Colorpicker)

                    RGB.Name = "RGB"
                    RGB.Parent = colorpickerFrame
                    RGB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    RGB.BackgroundTransparency = 1.000
                    RGB.BorderSizePixel = 0
                    RGB.Position = UDim2.new(0.0670000017, 0, 0.0680000037, 0)
                    RGB.Size = UDim2.new(0, 179, 0, 161)
                    RGB.AutoButtonColor = false
                    RGB.Image = "rbxassetid://6523286724"
                    RGB.ZIndex = 16

                    RGBCircle.Name = "RGBCircle"
                    RGBCircle.Parent = RGB
                    RGBCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    RGBCircle.BackgroundTransparency = 1.000
                    RGBCircle.BorderColor3 = Color3.fromRGB(27, 42, 53)
                    RGBCircle.BorderSizePixel = 0
                    RGBCircle.Size = UDim2.new(0, 14, 0, 14)
                    RGBCircle.Image = "rbxassetid://3926309567"
                    RGBCircle.ImageRectOffset = Vector2.new(628, 420)
                    RGBCircle.ImageRectSize = Vector2.new(48, 48)
                    RGBCircle.ZIndex = 16

                    Darkness.Name = "Darkness"
                    Darkness.Parent = colorpickerFrame
                    Darkness.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Darkness.BorderSizePixel = 0
                    Darkness.Position = UDim2.new(0.831940293, 0, 0.0680000708, 0)
                    Darkness.Size = UDim2.new(0, 33, 0, 161)
                    Darkness.AutoButtonColor = false
                    Darkness.Image = "rbxassetid://156579757"
                    Darkness.ZIndex = 16

                    DarknessCircle.Name = "DarknessCircle"
                    DarknessCircle.Parent = Darkness
                    DarknessCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    DarknessCircle.BorderSizePixel = 0
                    DarknessCircle.Position = UDim2.new(0, 0, 0, 0)
                    DarknessCircle.Size = UDim2.new(0, 33, 0, 5)
                    DarknessCircle.ZIndex = 16

                    colorHex.Name = "colorHex"
                    colorHex.Parent = colorpickerFrame
                    colorHex.BackgroundColor3 = Color3.fromRGB(9, 8, 13)
                    colorHex.Position = UDim2.new(0.0717131495, 0, 0.850678742, 0)
                    colorHex.Size = UDim2.new(0, 94, 0, 24)
                    colorHex.Font = Enum.Font.GothamSemibold
                    colorHex.Text = "#FFFFFF"
                    colorHex.TextColor3 = Color3.fromRGB(234, 239, 245)
                    colorHex.TextSize = 14.000
                    colorHex.ZIndex = 16

                    Copy.Parent = colorpickerFrame
                    Copy.BackgroundColor3 = Color3.fromRGB(9, 8, 13)
                    Copy.Position = UDim2.new(0.72111553, 0, 0.850678742, 0)
                    Copy.Size = UDim2.new(0, 60, 0, 24)
                    Copy.AutoButtonColor = false
                    Copy.Font = Enum.Font.GothamSemibold
                    Copy.Text = "Copy"
                    Copy.TextColor3 = Color3.fromRGB(234, 239, 245)
                    Copy.TextSize = 14.000
                    Copy.ZIndex = 16
                    Resize(25)
                    Copy.MouseButton1Click:Connect(function()
                        if setclipboard then
                            setclipboard(tostring(colorHex.Text))
                            Notify("Cryptweb:", tostring(colorHex.Text))
                            Notify("Cryptweb:", "Done!")
                        else
                            print(tostring(colorHex.Text))
                            Notify("Cryptweb:", tostring(colorHex.Text))
                            Notify("Cryptweb:", "Your exploit does not support the function 'setclipboard', so we've printed it out.")
                        end
                    end)

                    local ceil,clamp,atan2,pi   = math.ceil,math.clamp,math.atan2,math.pi
                    local tostr,sub             = tostring,string.sub
                    local fromHSV               = Color3.fromHSV
                    local v2,udim2              = Vector2.new,UDim2.new

                    local UserInputService  = game:GetService("UserInputService")
                    -- 0.49 P13: GetMouse удалён (блокировал поток) — координаты даёт общий хаб

                    local WheelDown         = false
                    local SlideDown         = false

                    local function toPolar(v)
                        return atan2(v.y, v.x), v.magnitude;
                    end

                    local function radToDeg(x)
                        return ((x + pi) / (2 * pi)) * 360;
                    end
                    local hue, saturation, value = 0, 0, 1;
                    local color = {1,1,1}

                    local function to_hex(color)
                        return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
                    end
                    local function update()
                        local r = color[1];
                        local g = color[2];
                        local b = color[3];

                        local c = fromHSV(r, g, b);
                        colorHex.Text = tostring(to_hex(c))
                    end
                    local function UpdateSlide(iX,iY)   
                        local y = iY - Darkness.AbsolutePosition.Y
                        local maxY = Darkness.AbsoluteSize.Y
                        if y<0 then y=0 end
                        if y>maxY then y=maxY end
                        y = y/maxY
                        local cy = DarknessCircle.AbsoluteSize.Y/2
                        color = {color[1],color[2],1-y}
                        local realcolor = Color3.fromHSV(color[1],color[2],color[3])
                        DarknessCircle.BackgroundColor3 = realcolor
                        DarknessCircle.Position = UDim2.new(0,0,y,-cy)
                        options.callback(realcolor)

                        update();
                    end
                    local function UpdateRing(iX,iY)
                        local ml = mouseLocation()
                        local x,y = ml.X - RGB.AbsolutePosition.X,ml.Y - RGB.AbsolutePosition.Y
                        local maxX,maxY = RGB.AbsoluteSize.X,RGB.AbsoluteSize.Y
                        if x<0 then 
                            x=0 
                        end
                        if x>maxX then 
                            x=maxX 
                        end
                        if y<0 then 
                            y=0 
                        end
                        if y>maxY then 
                            y=maxY
                        end
                        x = x/maxX
                        y = y/maxY

                        local cx = RGBCircle.AbsoluteSize.X/2
                        local cy = RGBCircle.AbsoluteSize.Y/2

                        RGBCircle.Position = udim2(x,-cx,y,-cy)

                        color = {1-x,1-y,color[3]}
                        local realcolor = Color3.fromHSV(color[1],color[2],color[3])
                        Darkness.BackgroundColor3 = realcolor
                        DarknessCircle.BackgroundColor3 = realcolor
                        options.callback(realcolor)
                        update();
                    end


                    RGB.MouseButton1Down:Connect(function()
                        WheelDown = true
                        NL_PICK_FN = function(x, y) UpdateRing(x, y) end
                        if NL_HUB_X and NL_HUB_Y then UpdateRing(NL_HUB_X, NL_HUB_Y) end
                    end)
                    Darkness.MouseButton1Down:Connect(function()
                        SlideDown = true
                        NL_PICK_FN = function(x, y) UpdateSlide(x, y) end
                        if NL_HUB_X and NL_HUB_Y then UpdateSlide(NL_HUB_X, NL_HUB_Y) end
                    end)


                    -- 0.49 P13: отпускание пальца ловит общий хаб

                    -- P5: MouseMoved не работает на таче -> UserInputService.InputChanged
                    -- 0.49 P13: движение ловит общий хаб (NL_PICK_FN)

                    local function setcolor(tbl)
                        local realcolor = Color3.fromHSV(tbl[1],tbl[2],tbl[3])
                        colorHex.Text = tostring(to_hex(realcolor))
                        DarknessCircle.BackgroundColor3 = realcolor
                    end
                    setcolor({hue,sat,val})
                    -- P6: объект колорпикера
                    local self = {}
                    function self:Set(c, silent)
                        if typeof(c) ~= "Color3" then return end
                        local h, s, v2 = Color3.toHSV(c)
                        color = {h, s, v2}
                        setcolor(color)
                        Darkness.BackgroundColor3 = c
                        if not silent then options.callback(c) end
                    end
                    function self:Get()
                        return Color3.fromHSV(color[1], color[2], color[3])
                    end
                    self.Value = self.Get
                    self.Instance = colorpickerLabel
                    return self
                end

                function elements:Keybind(options)
                    if not options.text or not options.default or not options.callback then Notify("Keybind", "Missing arguments") return end

                    Resize(25)

                    local blacklisted = {
                        Return = true,
                        Space = true,
                        Tab = true,
                        W = true,
                        A = true,
                        S = true,
                        D = true,
                        I = true,
                        O = true,
                        Unknown = true
                    }

                    local short = {
                        RightControl = "RCtrl",
                        LeftControl = "LCtrl",
                        LeftShift = "LShift",
                        RightShift = "RShift",
                        MouseButton1 = "M1",
                        MouseButton2 = "M2",
                        LeftAlt = "LAlt",
                        RightAlt = "RAlt"
                    }

                    local oldKey = (typeof(options.default) == "EnumItem" and options.default.Name) or tostring(options.default or "None")
                    local Keybind = Instance.new("Frame")
                    local keybindButton = Instance.new("TextButton")
                    local keybindLabel = Instance.new("TextLabel")

                    Keybind.Name = "Keybind"
                    Keybind.Parent = sectionFrame
                    Keybind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Keybind.BackgroundTransparency = 1.000
                    Keybind.BorderSizePixel = 0
                    Keybind.Position = UDim2.new(0.0348837227, 0, 0.945454538, 0)
                    Keybind.Size = UDim2.new(0, 200, 0, 22)
                    Keybind.ZIndex = 2
                    buttoneffect({frame = keybindButton, entered = Keybind})

                    keybindButton.Name = "keybindButton"
                    keybindButton.Parent = Keybind
                    keybindButton.AnchorPoint = Vector2.new(0.5, 0.5)
                    keybindButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    keybindButton.BackgroundTransparency = 1.000
                    keybindButton.BorderSizePixel = 0
                    keybindButton.Position = UDim2.new(0.5, 0, 0.5, 0)
                    keybindButton.Size = UDim2.new(0, 200, 0, 22)
                    keybindButton.AutoButtonColor = false
                    keybindButton.Font = Enum.Font.Gotham
                    keybindButton.Text = " " .. options.text
                    keybindButton.TextColor3 = Color3.fromRGB(157, 171, 182)
                    keybindButton.TextSize = 14.000
                    keybindButton.TextXAlignment = Enum.TextXAlignment.Left
                    keybindButton.MouseButton1Click:Connect(function()
                        keybindLabel.Text = "... "
                        TweenService:Create(keybindButton, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                            TextColor3 = Color3.fromRGB(234, 239, 246)
                        }):Play()
                        TweenService:Create(keybindLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                            TextColor3 = Color3.fromRGB(234, 239, 246)
                        }):Play()
                        local inputbegan = game:GetService("UserInputService").InputBegan:wait()
                        if not blacklisted[inputbegan.KeyCode.Name] then
                            TweenService:Create(keybindLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                TextColor3 = Color3.fromRGB(157, 171, 182)
                            }):Play()
                            TweenService:Create(keybindButton, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                TextColor3 = Color3.fromRGB(157, 171, 182)
                            }):Play()
                            keybindLabel.Text = short[inputbegan.KeyCode.Name] or inputbegan.KeyCode.Name
                            oldKey = inputbegan.KeyCode.Name
                            if options.onkeychanged then
                                pcall(options.onkeychanged, oldKey)
                            end
                        else
                            TweenService:Create(keybindButton, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                TextColor3 = Color3.fromRGB(157, 171, 182)
                            }):Play()
                            TweenService:Create(keybindLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                TextColor3 = Color3.fromRGB(157, 171, 182)
                            }):Play()
                            keybindLabel.Text = short[oldKey] or oldKey
                        end
                    end)

                    -- 0.49 P13: общий диспетчер клавиш вместо личного InputBegan
                    NL_KEY_FNS[#NL_KEY_FNS + 1] = function(key)
                        if key.KeyCode.Name == oldKey then
                            options.callback(oldKey)
                        end
                    end

                    keybindLabel.Name = "keybindLabel"
                    keybindLabel.Parent = keybindButton
                    keybindLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    keybindLabel.BackgroundColor3 = Color3.fromRGB(157, 171, 182)
                    keybindLabel.BackgroundTransparency = 1.000
                    keybindLabel.Position = UDim2.new(0.910000026, 0, 0.5, 0)
                    keybindLabel.Size = UDim2.new(0, 36, 0, 22)
                    keybindLabel.Font = Enum.Font.Gotham
                    keybindLabel.Text = oldKey .. " "
                    keybindLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    keybindLabel.TextSize = 14.000
                    keybindLabel.TextXAlignment = Enum.TextXAlignment.Right
                    -- P6: объект кейбинда
                    local self = {}
                    function self:Set(k, silent)
                        local nm = typeof(k) == "EnumItem" and k.Name or tostring(k)
                        if nm ~= "" and nm ~= "nil" then
                            oldKey = nm
                            keybindLabel.Text = (short[nm] or nm) .. " "
                        end
                    end
                    function self:Get() return oldKey end
                    self.Key = self.Get
                    self.Instance = keybindButton
                    return self
                end

                return elements
            end

            return sections
        end

        return tabs
    end

    return tabsections
end

return Library
