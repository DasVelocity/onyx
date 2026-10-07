--[[
    Onyx UI Library
    ---------------
    Same API/structure as Obsidian (drop-in), styled as a blend of Obsidian + Linoria:
      * Obsidian layout: sidebar tabs with lucide icons, search, footer, tab info, dialogs
      * Linoria DNA: accent strip on the window, inset (recessed) controls, accent-edged notifications

    Usage is identical to Obsidian:
        local Library = loadstring(game:HttpGet(".../Library.lua"))()
        local Window = Library:CreateWindow({ Title = "Onyx", Footer = "v1.0" })
        local Tab = Window:AddTab("Main", "house")
        local Box = Tab:AddLeftGroupbox("Features", "sparkles")
        Box:AddToggle("MyToggle", { Text = "Enabled", Default = false })
]]

local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}

--// Public asset ids (same images Obsidian/Linoria use) \\--
local Assets = {
    TransparencyTexture = "rbxassetid://139785960036434",
    SaturationMap = "rbxassetid://4155801252",
    Shadow = "rbxassetid://6015897843",
}

local Library = {
    LocalPlayer = LocalPlayer,
    IsRobloxFocused = true,

    DevicePlatform = nil,
    IsMobile = false,

    ScreenGui = nil,
    Floats = nil,
    Overlay = nil,

    Window = nil,
    WindowContainer = nil,

    --// Search \\--
    SearchText = "",
    Searching = false,
    GlobalSearch = false,

    --// Tabs \\--
    ActiveTab = nil,
    PreviousTab = nil,
    Tabs = {},
    TabButtons = {},

    DependencyBoxes = {},

    --// Keybinds \\--
    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    --// Notifications \\--
    Notifications = {},
    NotifySide = "Right",

    Dialogues = {},
    ActiveDialog = nil,
    ActiveLoading = nil,

    OpenedFrames = {},

    --// Animations \\--
    TweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    SlowTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    SpringTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),

    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true,
    },

    --// States \\--
    Toggled = false,
    Unloaded = false,
    IsPicking = false,

    --// Elements \\--
    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    --// Options \\--
    ToggleKeybind = Enum.KeyCode.RightControl,
    ShowToggleFrameInKeybinds = true,

    NotifyOnError = false,
    ShowCustomCursor = true,
    ForceCheckbox = false,
    CantDragForced = false,

    --// Signals \\--
    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(500, 360),
    MinSize = Vector2.new(500, 360),
    DPIScale = 1,
    CornerRadius = 6,

    --// Scheme \\--
    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(11, 11, 13),
        MainColor = Color3.fromRGB(19, 19, 22),
        AccentColor = Color3.fromRGB(239, 52, 64),
        OutlineColor = Color3.fromRGB(34, 34, 40),
        FontColor = Color3.fromRGB(240, 240, 243),
        Font = Font.fromEnum(Enum.Font.BuilderSans),

        RedColor = Color3.fromRGB(255, 72, 72),
        DestructiveColor = Color3.fromRGB(220, 38, 38),
        DarkColor = Color3.new(0, 0, 0),
        WhiteColor = Color3.new(1, 1, 1),

        BackgroundImage = "",
    },

    Registry = {},
    Scales = {},
    Corners = {},

    OriginalMouseIconEnabled = UserInputService.MouseIconEnabled,
    Assets = Assets,

    Notify = nil,
    Toggle = nil,
}

if RunService:IsStudio() then
    Library.IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
end
if Library.IsMobile then
    Library.OriginalMinSize = Vector2.new(480, 240)
    Library.MinSize = Library.OriginalMinSize
end

--// Templates \\--
local Templates = {
    Frame = { BorderSizePixel = 0 },
    ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
    ImageButton = { AutoButtonColor = false, BorderSizePixel = 0 },
    ScrollingFrame = { BorderSizePixel = 0 },
    TextLabel = { BorderSizePixel = 0, FontFace = "Font", RichText = true, TextColor3 = "FontColor" },
    TextButton = { AutoButtonColor = false, BorderSizePixel = 0, FontFace = "Font", RichText = true, TextColor3 = "FontColor" },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            return Library.Scheme.FontColor:Lerp(Library.Scheme.BackgroundColor, 0.55)
        end,
        Text = "",
        TextColor3 = "FontColor",
        ClearTextOnFocus = false,
    },
    UIListLayout = { SortOrder = Enum.SortOrder.LayoutOrder },
    UIStroke = { ApplyStrokeMode = Enum.ApplyStrokeMode.Border },

    Window = {
        Title = "No Title",
        Footer = "No Footer",
        Icon = nil,

        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 560),
        IconSize = UDim2.fromOffset(22, 22),

        AutoShow = true,
        Center = true,
        Resizable = true,
        AlwaysOnTop = false,

        SearchbarSize = UDim2.fromScale(1, 1),
        GlobalSearch = false,

        CornerRadius = 6,
        NotifySide = "Right",
        ShowCustomCursor = true,
        Font = Enum.Font.BuilderSans,
        ToggleKeybind = Enum.KeyCode.RightControl,

        ShowMobileButtons = true,
        MobileButtonsSide = "Left",
        UnlockMouseWhileOpen = true,

        SidebarWidth = 184,
        SidebarCompacted = false,
        EnableCompacting = true,
        SidebarCompactWidth = 56,
        MinSidebarWidth = 128,
        MinContainerWidth = 256,

        BackgroundImage = "",

        Animations = {
            ToggleWindow = true,
            TabSwitch = true,
            Groupbox = true,
            Dropdown = true,
            KeyPicker = true,
        },
    },
    Groupbox = {
        Side = 1,
        Name = "Groupbox",
        IconName = nil,
        Description = nil,
        Visible = true,
        Collapsed = false,
        DisableCollapsing = false,
    },
    Tabbox = { Side = 1, Name = nil },
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
        FooterButtons = {},
    },
    Loading = {
        Title = "Onyx",
        Icon = nil,
        IconSize = UDim2.fromOffset(22, 22),

        LoadingIcon = "loader-circle",
        LoadingIconColor = nil,
        LoadingIconTweenTime = 1,

        CurrentStep = 0,
        TotalSteps = 10,

        ShowSidebar = false,
        AutoResizeHeight = false,
        AlwaysOnTop = true,

        WindowWidth = 420,
        WindowHeight = 250,
        ContentWidth = 420,
        SidebarWidth = 220,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,
        Callback = function() end,
        Changed = function() end,
        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        ClearTextOnBlur = false,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",
        Callback = function() end,
        Changed = function() end,
        VerifyValue = nil,
        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Prefix = "",
        Suffix = "",
        Callback = function() end,
        Changed = function() end,
        Disabled = false,
        Visible = true,
        AllowRightClickInput = true,
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        ValueImages = {},
        Multi = false,
        MaxVisibleDropdownItems = 8,
        Callback = function() end,
        Changed = function() end,
        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },
    KeyPicker = {
        Text = "KeyPicker",
        Default = "None",
        DefaultModifiers = {},
        Blacklisted = {},
        BlacklistedModifiers = {},
        Whitelisted = {},
        WhitelistedModifiers = {},
        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,
        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),
        Callback = function() end,
        Changed = function() end,
    },
}

local SideIndex = { left = 1, right = 2 }

--// Scheme lookups \\--
local SchemeAlias = { Red = "RedColor", White = "WhiteColor", Dark = "DarkColor" }

local function GetSchemeValue(Index)
    if typeof(Index) ~= "string" then
        return nil
    end
    local Scheme = Library.Scheme
    if Scheme[Index] ~= nil then
        return Scheme[Index]
    end
    local Alias = SchemeAlias[Index]
    if Alias and Scheme[Alias] ~= nil then
        return Scheme[Alias]
    end
    return nil
end

--// Small helpers \\--
local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2) and Input.UserInputState == Enum.UserInputState.Begin
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsMouseClickInput(Input: InputObject)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.MouseButton2
        or Input.UserInputType == Enum.UserInputType.MouseButton3
end
local function IsMovementInput(Input: InputObject)
    return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

local function GetTableSize(Table)
    local Size = 0
    for _ in Table do
        Size += 1
    end
    return Size
end

local function IsSequentialArray(Table)
    if typeof(Table) ~= "table" then
        return false
    end
    local Count = 0
    for _ in Table do
        Count += 1
        if Table[Count] == nil then
            return false
        end
    end
    return true
end

local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end

local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")
    if Rounding == 0 then
        return math.floor(Value + 0.5)
    end
    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

local function StopTween(T, Destroy)
    if T then
        pcall(function()
            T:Cancel()
            if Destroy then
                T:Destroy()
            end
        end)
    end
end

local function Tween(Object: Instance, Info: TweenInfo?, Properties: { [string]: any })
    local T = TweenService:Create(Object, Info or Library.TweenInfo, Properties)
    T:Play()
    return T
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local List = Players:GetPlayers()
    if ExcludeLocalPlayer then
        local Index = table.find(List, LocalPlayer)
        if Index then
            table.remove(List, Index)
        end
    end
    table.sort(List, function(A, B)
        return A.Name:lower() < B.Name:lower()
    end)
    for Index, Player in List do
        List[Index] = Player.Name
    end
    return List
end

local function GetTeams()
    local List = Teams:GetTeams()
    table.sort(List, function(A, B)
        return A.Name:lower() < B.Name:lower()
    end)
    for Index, Team in List do
        List[Index] = Team.Name
    end
    return List
end

--// Registry \\--
function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in Library.Registry do
        if not Instance.Parent and Instance ~= Library.ScreenGui then
            continue
        end
        for Property, Index in Properties do
            local SchemeValue = GetSchemeValue(Index)
            if SchemeValue ~= nil then
                pcall(function()
                    Instance[Property] = SchemeValue
                end)
            elseif typeof(Index) == "function" then
                pcall(function()
                    Instance[Property] = Index()
                end)
            end
        end
    end

    for _, Callback in Library.ThemeCallbacks do
        Library:SafeCallback(Callback)
    end
end
Library.ThemeCallbacks = {}

function Library:OnThemeChanged(Callback)
    table.insert(Library.ThemeCallbacks, Callback)
end

function Library:GiveSignal(Connection)
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
        table.insert(Library.Signals, Connection)
    end
    return Connection
end

function Library:Validate(Table, Template)
    if typeof(Table) ~= "table" then
        return Template
    end
    for Key, Value in Template do
        if typeof(Key) == "number" then
            continue
        end
        if typeof(Value) == "table" then
            Table[Key] = Library:Validate(Table[Key], Value)
        elseif Table[Key] == nil then
            Table[Key] = Value
        end
    end
    return Table
end

function Library:SafeCallback(Func, ...)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify({ Title = "Callback error", Description = tostring(Error), Time = 5, Icon = "triangle-alert" })
        end
        return Error
    end, ...))

    if not Result[1] then
        return nil
    end
    return table.unpack(Result, 2, Result.n)
end

function Library:AttemptSave()
    -- Linoria compatibility; SaveManager is opt-in.
    if Library.SaveManager and Library.SaveManager.Save then
        pcall(Library.SaveManager.Save, Library.SaveManager)
    end
end

--// Fonts \\--
local function FontWeight(Weight: Enum.FontWeight)
    return function()
        local Base = Library.Scheme.Font
        local Ok, Result = pcall(Font.new, Base.Family, Weight, Base.Style)
        return Ok and Result or Base
    end
end
local MediumFont = FontWeight(Enum.FontWeight.Medium)
local SemiBoldFont = FontWeight(Enum.FontWeight.SemiBold)
local BoldFont = FontWeight(Enum.FontWeight.Bold)
local MonoFont = function()
    return Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium)
end

--// Derived colours (functions are re-evaluated on theme change) \\--
local Colors = {
    Hover = function()
        return Library:GetBetterColor(Library.Scheme.MainColor, 7)
    end,
    Elevated = function()
        return Library:GetBetterColor(Library.Scheme.MainColor, 4)
    end,
    Recessed = function()
        return Library:GetBetterColor(Library.Scheme.BackgroundColor, -2)
    end,
    AccentLight = function()
        local H, S, V = Library.Scheme.AccentColor:ToHSV()
        return Color3.fromHSV(H, math.max(S - 0.25, 0), math.min(V + 0.2, 1))
    end,
    AccentDark = function()
        return Library.Scheme.AccentColor:Lerp(Library.Scheme.BackgroundColor, 0.55)
    end,
    Muted = function()
        return Library.Scheme.FontColor:Lerp(Library.Scheme.BackgroundColor, 0.45)
    end,
    Faint = function()
        return Library.Scheme.FontColor:Lerp(Library.Scheme.BackgroundColor, 0.65)
    end,
    OnAccent = function()
        local _, _, V = Library.Scheme.AccentColor:ToHSV()
        local R, G, B = Library.Scheme.AccentColor.R, Library.Scheme.AccentColor.G, Library.Scheme.AccentColor.B
        local Luminance = 0.2126 * R + 0.7152 * G + 0.0722 * B
        return (Luminance > 0.6 and V > 0.6) and Color3.fromRGB(14, 14, 18) or Color3.new(1, 1, 1)
    end,
}
Library.Colors = Colors

--// Creator \\--
local function FillInstance(Table, Instance)
    local ThemeProperties = Library.Registry[Instance] or {}

    for Key, Value in Table do
        if Key ~= "Text" and Key ~= "Name" and Key ~= "PlaceholderText" and Key ~= "Image" then
            local SchemeValue = GetSchemeValue(Value)
            if SchemeValue ~= nil or typeof(Value) == "function" then
                ThemeProperties[Key] = Value
                if SchemeValue ~= nil then
                    Value = SchemeValue
                else
                    Value = Value()
                end
            else
                ThemeProperties[Key] = nil
            end
        end
        Instance[Key] = Value
    end

    if next(ThemeProperties) then
        Library.Registry[Instance] = ThemeProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Object = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Object)
    end

    local Parent = Properties.Parent
    Properties.Parent = nil
    FillInstance(Properties, Object)
    Properties.Parent = Parent

    if Parent then
        if not Properties.ZIndex then
            pcall(function()
                Object.ZIndex = Parent.ZIndex
            end)
        end
        Object.Parent = Parent
    end

    return Object
end
Library.New = New

local function Corner(Parent, Radius)
    local C = New("UICorner", {
        CornerRadius = UDim.new(0, Radius or Library.CornerRadius),
        Parent = Parent,
    })
    if not Radius then
        table.insert(Library.Corners, { C, 1 })
    end
    return C
end

local function ScaledCorner(Parent, Multiplier)
    local C = New("UICorner", {
        CornerRadius = UDim.new(0, math.floor(Library.CornerRadius * Multiplier + 0.5)),
        Parent = Parent,
    })
    table.insert(Library.Corners, { C, Multiplier })
    return C
end

local function Stroke(Parent, Color, Transparency, Thickness)
    return New("UIStroke", {
        Color = Color or "OutlineColor",
        Transparency = Transparency or 0,
        Thickness = Thickness or 1,
        Parent = Parent,
    })
end

local function Padding(Parent, Top, Right, Bottom, Left)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, Top or 0),
        PaddingRight = UDim.new(0, Right or Top or 0),
        PaddingBottom = UDim.new(0, Bottom or Top or 0),
        PaddingLeft = UDim.new(0, Left or Right or Top or 0),
        Parent = Parent,
    })
end

local function List(Parent, Gap, Direction, HAlign, VAlign)
    return New("UIListLayout", {
        Padding = UDim.new(0, Gap or 0),
        FillDirection = Direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = HAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = VAlign or Enum.VerticalAlignment.Top,
        Parent = Parent,
    })
end

local function Scale(Parent, Offset)
    local S = New("UIScale", { Scale = Library.DPIScale - (Offset or 0), Parent = Parent })
    table.insert(Library.Scales, S)
    return S
end

--// Colour helpers \\--
function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetLighterColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end
    return KeyCode.Name
end

function Library:GetTextBounds(Text: string, FontFace: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = FontFace
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Ok, Bounds = pcall(TextService.GetTextBoundsAsync, TextService, Params)
    if not Ok then
        return #Text * Size * 0.5, Size
    end
    return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:IsInsideFrame(ParentFrame: GuiObject, Frame: GuiObject)
    return Frame == ParentFrame or Frame:IsDescendantOf(ParentFrame)
end

local function GetMouse(): Vector2
    return UserInputService:GetMouseLocation() - Vector2.new(0, 0)
end

--// Icons (lucide) \\--
local Icons = nil
local FetchIcons = false

function Library:SetIconModule(Module)
    FetchIcons = true
    Icons = Module
end

do
    local Ok, Module = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/notpoiu/lucide-roblox-direct/refs/heads/main/source.lua"))()
    end)
    if Ok and Module then
        Library:SetIconModule(Module)
    end
end

local function IsAssetIcon(Icon)
    return typeof(Icon) == "string"
        and (Icon:match("^rbxassetid://") or Icon:match("^rbxasset://") or Icon:match("^content://") or Icon:match("^rbxthumb://") or Icon:match("roblox%.com/asset/%?id="))
end

function Library:GetIcon(IconName: string)
    if not FetchIcons or not Icons or typeof(IconName) ~= "string" then
        return nil
    end
    local Ok, Icon = pcall(Icons.GetAsset, IconName)
    if not Ok or not Icon then
        return nil
    end
    return Icon
end

function Library:GetCustomIcon(IconName: any): any
    if IconName == nil or IconName == "" then
        return nil
    end
    if typeof(IconName) == "table" and IconName.Url then
        return IconName
    end
    if tonumber(IconName) then
        IconName = "rbxassetid://" .. tostring(IconName)
    end
    if IsAssetIcon(IconName) then
        return { Url = IconName, ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero, Custom = true }
    end
    return Library:GetIcon(IconName)
end

--// Fallback glyphs used when lucide could not be fetched (e.g. plain Studio) \\--
local IconFallbacks = {
    ["chevron-down"] = "▾",
    ["chevron-up"] = "▴",
    ["chevron-right"] = "›",
    ["check"] = "✓",
    ["x"] = "✕",
    ["search"] = "⌕",
    ["plus"] = "+",
    ["minus"] = "−",
    ["info"] = "i",
    ["triangle-alert"] = "!",
    ["move-diagonal-2"] = "⤡",
    ["keyboard"] = "⌨",
    ["loader-circle"] = "◌",
}

function Library:ApplyIcon(ImageGui: ImageLabel, IconName: any)
    if not ImageGui then
        return false
    end
    local Fallback = ImageGui:FindFirstChild("__Fallback")
    local Icon = Library:GetCustomIcon(IconName)

    if Icon then
        if Fallback then
            Fallback:Destroy()
        end
        ImageGui.Image = Icon.Url or ""
        ImageGui.ImageRectOffset = Icon.ImageRectOffset or Vector2.zero
        ImageGui.ImageRectSize = Icon.ImageRectSize or Vector2.zero
        return true
    end

    ImageGui.Image = ""
    local Glyph = typeof(IconName) == "string" and IconFallbacks[IconName]
    if Glyph then
        if not Fallback then
            Fallback = Instance.new("TextLabel")
            Fallback.Name = "__Fallback"
            Fallback.BackgroundTransparency = 1
            Fallback.Size = UDim2.fromScale(1, 1)
            Fallback.Font = Enum.Font.GothamBold
            Fallback.TextScaled = true
            Fallback.ZIndex = ImageGui.ZIndex
            Fallback.Parent = ImageGui

            local function Sync()
                Fallback.TextColor3 = ImageGui.ImageColor3
                Fallback.TextTransparency = ImageGui.ImageTransparency
            end
            Sync()
            ImageGui:GetPropertyChangedSignal("ImageColor3"):Connect(Sync)
            ImageGui:GetPropertyChangedSignal("ImageTransparency"):Connect(Sync)
        end
        Fallback.Text = Glyph
        return true
    end

    if Fallback then
        Fallback:Destroy()
    end
    return false
end

-- Obsidian compatibility alias
function Library:ApplyLucideIcon(ImageGui, Icon, Rotation)
    if Rotation then
        ImageGui.Rotation = Rotation
    end
    if typeof(Icon) == "table" then
        ImageGui.Image = Icon.Url or ImageGui.Image
        ImageGui.ImageRectOffset = Icon.ImageRectOffset or ImageGui.ImageRectOffset
        ImageGui.ImageRectSize = Icon.ImageRectSize or ImageGui.ImageRectSize
        return
    end
    Library:ApplyIcon(ImageGui, Icon)
end

local function IconLabel(Properties: { [string]: any }, IconName: any)
    Properties.BackgroundTransparency = 1
    Properties.ImageColor3 = Properties.ImageColor3 or "FontColor"
    Properties.ScaleType = Enum.ScaleType.Fit
    local Label = New("ImageLabel", Properties)
    local Applied = Library:ApplyIcon(Label, IconName)
    return Label, Applied
end

--// ScreenGui \\--
local function SafeParentUI(Object: Instance, Parent)
    local Ok = pcall(function()
        local Destination = typeof(Parent) == "function" and Parent() or Parent or CoreGui
        Object.Parent = Destination
    end)
    if not (Ok and Object.Parent) then
        local Player = LocalPlayer or Players.LocalPlayer
        if Player then
            Object.Parent = Player:WaitForChild("PlayerGui", math.huge)
        end
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end
    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local ScreenGui = New("ScreenGui", {
    Name = "Onyx",
    DisplayOrder = 999,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

local function SetAlwaysOnTop(Gui: ScreenGui, Enabled: boolean)
    Gui.DisplayOrder = Enabled and 99999 or 999
end

-- Layers (ZIndexBehavior.Sibling keeps every layer strictly above the one before it)
local WindowLayer = New("Frame", { Name = "Windows", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = ScreenGui })
local DraggableLayer = New("Frame", { Name = "Draggables", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = ScreenGui })
local Floats = New("Frame", { Name = "Floats", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50, Parent = ScreenGui })
local NotificationLayer = New("Frame", { Name = "Notifications", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 80, Parent = ScreenGui })
local TooltipLayer = New("Frame", { Name = "Tooltips", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 90, Parent = ScreenGui })
local CursorLayer = New("Frame", { Name = "Cursor", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 100, Parent = ScreenGui })
Library.Floats = Floats

-- Mouse position in the same space as GuiObject.AbsolutePosition (handles the topbar inset either way)
local function GetMouseAbs(): Vector2
    return UserInputService:GetMouseLocation() + Floats.AbsolutePosition
end
Library.GetMouseAbs = GetMouseAbs
Library.WindowContainer = WindowLayer

--// Modal button: unlocks the mouse in first person while the menu is open \\--
local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromOffset(0, 0),
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

--// Custom cursor (Obsidian cross, Linoria-style outline) \\--
local Cursor
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(17, 17),
        Visible = false,
        Parent = CursorLayer,
    })
    local Vertical = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = Cursor,
    })
    New("UIStroke", { Color = "DarkColor", ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = Vertical })
    local Horizontal = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Cursor,
    })
    New("UIStroke", { Color = "DarkColor", ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = Horizontal })
    Library.Cursor = { Frame = Cursor, Vertical = Vertical, Horizontal = Horizontal }
end

function Library:ChangeCursorCrossColor(Color: Color3)
    Library.Cursor.Vertical.BackgroundColor3 = Color
    Library.Cursor.Horizontal.BackgroundColor3 = Color
end

function Library:ResetCursorCross()
    Library:ChangeCursorCrossColor(Library.Scheme.WhiteColor)
end

--// Popups (dropdown lists, colour pickers, mode menus) \\--
--   Every popup lives in the Floats layer, follows its owner each frame, and closes on an outside click.
local Popups = {}

local function CreatePopup(Owner: GuiObject, Options: { Width: number?, Offset: Vector2?, MatchWidth: boolean?, Align: string? })
    Options = Options or {}

    local Popup = {
        Owner = Owner,
        Active = false,
        Ignore = {},
        OnClose = nil,
    }

    local Frame = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.fromOffset(Options.Width or 200, 0),
        Visible = false,
        ZIndex = 1,
        Parent = Floats,
    })
    ScaledCorner(Frame, 1)
    Stroke(Frame)
    Scale(Frame)
    Popup.Frame = Frame

    local Follow
    function Popup:Reposition()
        if not Owner.Parent then
            return
        end
        -- AbsolutePosition can be shifted by the topbar inset; convert it into the Floats layer's space
        local Pos = Owner.AbsolutePosition - Floats.AbsolutePosition
        local Size = Owner.AbsoluteSize
        local Offset = Options.Offset or Vector2.new(0, 6)
        local GuiInset = Vector2.zero

        if Options.MatchWidth then
            Frame.Size = UDim2.fromOffset(Size.X / Library.DPIScale, Frame.Size.Y.Offset)
        end

        local X = Pos.X + Offset.X
        if Options.Align == "Right" then
            X = Pos.X + Size.X - Frame.AbsoluteSize.X
        end
        local Y = Pos.Y + Size.Y + Offset.Y * Library.DPIScale

        local Viewport = workspace.CurrentCamera.ViewportSize
        if Y + Frame.AbsoluteSize.Y > Viewport.Y - 8 then
            Y = Pos.Y - Frame.AbsoluteSize.Y - Offset.Y * Library.DPIScale
        end
        X = math.clamp(X, 4, math.max(4, Viewport.X - Frame.AbsoluteSize.X - 4))
        Frame.Position = UDim2.fromOffset(X - GuiInset.X, Y - GuiInset.Y)
    end

    function Popup:Open()
        if Popup.Active or Library.Unloaded then
            return
        end
        for _, Other in Popups do
            if Other ~= Popup and Other.Active and not Other.Frame:IsAncestorOf(Owner) then
                Other:Close()
            end
        end
        Popup.Active = true
        Frame.Visible = true
        Popup:Reposition()
        Follow = RunService.RenderStepped:Connect(function()
            if not Owner.Parent or not Owner:IsDescendantOf(game) then
                Popup:Close()
                return
            end
            -- close when the owner gets hidden (tab switch, menu toggled, collapsed groupbox)
            local Visible = true
            local Node = Owner
            while Node and Node:IsA("GuiObject") do
                if not Node.Visible then
                    Visible = false
                    break
                end
                Node = Node.Parent
            end
            if not Visible then
                Popup:Close()
                return
            end
            Popup:Reposition()
        end)

        if Library.Animations.Dropdown then
            local Target = Frame.Size
            local Scaler = Frame:FindFirstChildOfClass("UIScale")
            if Scaler then
                Scaler.Scale = Library.DPIScale * 0.97
                Tween(Scaler, Library.TweenInfo, { Scale = Library.DPIScale })
            end
            Frame.Size = Target
        end
    end

    function Popup:Close()
        if not Popup.Active then
            return
        end
        Popup.Active = false
        Frame.Visible = false
        if Follow then
            Follow:Disconnect()
            Follow = nil
        end
        if Popup.OnClose then
            Library:SafeCallback(Popup.OnClose)
        end
    end

    function Popup:Toggle()
        if Popup.Active then
            Popup:Close()
        else
            Popup:Open()
        end
    end

    function Popup:SetSize(Size)
        Frame.Size = Size
    end

    function Popup:Destroy()
        Popup:Close()
        Frame:Destroy()
        local Index = table.find(Popups, Popup)
        if Index then
            table.remove(Popups, Index)
        end
    end

    table.insert(Popups, Popup)
    return Popup
end
Library.CreatePopup = CreatePopup

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
    if Library.Unloaded or not IsClickInput(Input, true) then
        return
    end
    local Mouse = GetMouseAbs()

    for _, Popup in table.clone(Popups) do
        if not Popup.Active then
            continue
        end
        if Library:MouseIsOverFrame(Popup.Frame, Mouse) or Library:MouseIsOverFrame(Popup.Owner, Mouse) then
            continue
        end
        local Inside = false
        for _, Extra in Popup.Ignore do
            if Extra.Visible and Library:MouseIsOverFrame(Extra, Mouse) then
                Inside = true
                break
            end
        end
        -- clicks inside a popup that was opened from this popup (nested) keep it alive
        for _, Other in Popups do
            if Other ~= Popup and Other.Active and Popup.Frame:IsAncestorOf(Other.Owner) and Library:MouseIsOverFrame(Other.Frame, Mouse) then
                Inside = true
                break
            end
        end
        if not Inside then
            Popup:Close()
        end
    end
end))

--// Tooltips \\--
local TooltipLabel
do
    TooltipLabel = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "MainColor",
        TextSize = 13,
        TextWrapped = false,
        Visible = false,
        ZIndex = 1,
        Parent = TooltipLayer,
    })
    New("UISizeConstraint", { MaxSize = Vector2.new(260, math.huge), Parent = TooltipLabel })
    Padding(TooltipLabel, 5, 8, 5, 8)
    ScaledCorner(TooltipLabel, 0.75)
    Stroke(TooltipLabel)
    Scale(TooltipLabel)
end

function Library:AddTooltip(InfoStr: string?, DisabledInfoStr: string?, HoverInstance: GuiObject)
    local TooltipTable = {
        Info = InfoStr,
        DisabledInfo = DisabledInfoStr,
        Disabled = false,
        Signals = {},
    }
    local Hovering = false

    local function Show()
        local Text = TooltipTable.Disabled and TooltipTable.DisabledInfo or TooltipTable.Info
        if not Text or Text == "" or Library.Unloaded then
            return
        end
        Hovering = true
        TooltipLabel.Text = Text
        TooltipLabel.TextWrapped = #Text > 40
        TooltipLabel.Visible = true

        while Hovering and Library.Toggled and HoverInstance.Parent do
            local Mouse = UserInputService:GetMouseLocation()
            TooltipLabel.Position = UDim2.fromOffset(Mouse.X + 14, Mouse.Y + 10)
            RunService.RenderStepped:Wait()
        end
        if Hovering then
            Hovering = false
        end
        TooltipLabel.Visible = false
    end

    table.insert(TooltipTable.Signals, HoverInstance.MouseEnter:Connect(function()
        task.spawn(Show)
    end))
    table.insert(TooltipTable.Signals, HoverInstance.MouseLeave:Connect(function()
        Hovering = false
        TooltipLabel.Visible = false
    end))

    function TooltipTable:Destroy()
        for _, Signal in TooltipTable.Signals do
            Signal:Disconnect()
        end
        Hovering = false
        TooltipLabel.Visible = false
        local Index = table.find(Tooltips, TooltipTable)
        if Index then
            table.remove(Tooltips, Index)
        end
    end

    table.insert(Tooltips, TooltipTable)
    return TooltipTable
end

--// Dragging & resizing \\--
function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)
    local StartPos, FramePos
    local Dragging = false
    local Changed

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or (IsMainWindow and Library.CantDragForced) then
            return
        end
        if not IgnoreToggled and not Library.Toggled then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not Dragging or not IsHoverInput(Input) then
            return
        end
        if (not IgnoreToggled and not Library.Toggled) or (IsMainWindow and Library.CantDragForced) or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
            return
        end

        local Delta = Input.Position - StartPos
        UI.Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
    end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: (() -> ())?)
    local StartPos, FrameSize
    local Dragging = false
    local Changed

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end
        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not Dragging or not IsHoverInput(Input) or not UI.Visible then
            return
        end
        local Delta = (Input.Position - StartPos) / Library.DPIScale
        UI.Size = UDim2.new(
            FrameSize.X.Scale,
            math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
            FrameSize.Y.Scale,
            math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
        )
        if Callback then
            Library:SafeCallback(Callback)
        end
    end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Place == "Bottom" and { 0, 1 } or { 1, 0 }
    return New("Frame", {
        AnchorPoint = Place == "Bottom" and Vector2.new(0, 1) or Vector2.new(1, 0),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = Place == "Bottom" and UDim2.new(1, 0, 0.5, 0) or UDim2.new(0.5, 0, 1, 0),
        Parent = Holder,
    })
end

function Library:MakeLine(Frame: GuiObject, Info)
    return New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        Position = Info.Position,
        Size = Info.Size,
        Parent = Frame,
    })
end

function Library:AddOutline(Frame: GuiObject)
    return Stroke(Frame)
end

function Library:MakeOutline(Frame: GuiObject, CornerRadius: number?)
    Stroke(Frame)
    if CornerRadius then
        Corner(Frame, CornerRadius)
    end
    return Frame
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

--// Draggable helpers (watermark, keybind list, mobile buttons) \\--
local function DraggableShell(Name: string?)
    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.fromOffset(0, 0),
        Parent = DraggableLayer,
    })
    ScaledCorner(Holder, 1)
    Stroke(Holder)
    Scale(Holder)

    -- soft accent sheen along the top edge (outside of any layout)
    local Sheen = New("Frame", {
        BackgroundColor3 = "AccentColor",
        BackgroundTransparency = 0.82,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 0,
        Parent = Holder,
    })
    ScaledCorner(Sheen, 1)
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.6, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = Sheen,
    })

    -- all content goes in here so nothing decorative ends up inside a layout
    local Content = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 1,
        Parent = Holder,
    })

    return Holder, Content
end

local function AccentTile(Parent, IconName, Size, LayoutOrder)
    -- neutral tile, the icon carries the accent
    local Tile = New("Frame", {
        BackgroundColor3 = "MainColor",
        LayoutOrder = LayoutOrder or 0,
        Size = UDim2.fromOffset(Size, Size),
        Parent = Parent,
    })
    Corner(Tile, math.floor(Size * 0.28))
    Stroke(Tile)
    local Icon, HasIcon = IconLabel({
        AnchorPoint = Vector2.new(0.5, 0.5),
        ImageColor3 = "AccentColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(math.floor(Size * 0.58), math.floor(Size * 0.58)),
        Parent = Tile,
    }, IconName)
    return Tile, Icon, HasIcon
end
Library.AccentTile = AccentTile

function Library:AddDraggableLabel(...)
    local Text, Icon, IconPosition
    local First = select(1, ...)
    if typeof(First) == "table" then
        Text, Icon, IconPosition = First.Text, First.Icon, First.IconPosition
    else
        Text, Icon, IconPosition = First, select(2, ...), select(3, ...)
    end

    local Holder, Content = DraggableShell()
    Padding(Content, 7, 12, 7, 8)
    List(Content, 9, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)

    local IconTile, IconImage = AccentTile(Content, nil, 22, IconPosition == "Right" and 2 or 0)
    IconTile.Visible = false

    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        FontFace = MediumFont,
        Size = UDim2.fromOffset(0, 22),
        Text = Text or "",
        TextSize = 14,
        LayoutOrder = 1,
        Parent = Content,
    })

    Library:MakeDraggable(Holder, Holder, true)

    local DraggableLabel = { Holder = Holder, Label = Label, Content = Content, IconTile = IconTile }

    function DraggableLabel:SetText(NewText: string)
        Label.Text = NewText
    end
    function DraggableLabel:SetIcon(NewIcon: string)
        IconTile.Visible = NewIcon ~= nil and Library:ApplyIcon(IconImage, NewIcon)
    end
    function DraggableLabel:SetIconPosition(Position: string)
        IconTile.LayoutOrder = Position == "Right" and 2 or 0
    end
    function DraggableLabel:SetVisible(Visible: boolean)
        Holder.Visible = Visible
    end
    function DraggableLabel:Destroy()
        Holder:Destroy()
    end

    if Icon then
        DraggableLabel:SetIcon(Icon)
    end
    return DraggableLabel
end

function Library:AddDraggableButton(...)
    local Text, Func, Icon
    local First = select(1, ...)
    if typeof(First) == "table" then
        Text, Func, Icon = First.Text, First.Func or First.Callback, First.Icon
    else
        Text, Func, Icon = First, select(2, ...), select(3, ...)
    end

    local Holder, Content = DraggableShell()
    local Button = New("TextButton", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        FontFace = MediumFont,
        Size = UDim2.fromOffset(0, 0),
        Text = Text or "",
        TextSize = 14,
        Parent = Content,
    })
    Padding(Button, 8, 14, 8, 14)
    Library:MakeDraggable(Holder, Button, true)

    local Moved = false
    local DownPos
    Button.InputBegan:Connect(function(Input)
        if IsClickInput(Input) then
            DownPos = Input.Position
            Moved = false
        end
    end)
    Button.InputChanged:Connect(function(Input)
        if DownPos and IsHoverInput(Input) and (Input.Position - DownPos).Magnitude > 6 then
            Moved = true
        end
    end)
    Button.MouseButton1Click:Connect(function()
        if not Moved and Func then
            Library:SafeCallback(Func)
        end
    end)

    local DraggableButton = { Holder = Holder, Button = Button }
    function DraggableButton:SetText(NewText: string)
        Button.Text = NewText
    end
    function DraggableButton:SetVisible(Visible: boolean)
        Holder.Visible = Visible
    end
    function DraggableButton:Destroy()
        Holder:Destroy()
    end
    return DraggableButton
end

function Library:AddDraggableMenu(Name: string, Icon: string?)
    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.fromOffset(200, 0),
        Parent = DraggableLayer,
    })
    ScaledCorner(Holder, 1)
    Stroke(Holder)
    Scale(Holder)

    local Top = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = Holder,
    })
    local Tile = AccentTile(Top, Icon or "keyboard", 22)
    Tile.AnchorPoint = Vector2.new(0, 0.5)
    Tile.Position = UDim2.new(0, 10, 0.5, 0)
    New("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = SemiBoldFont,
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -46, 1, 0),
        Text = Name,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Top,
    })
    New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Top,
    })

    local Container = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 38),
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Holder,
    })
    List(Container, 4)
    Padding(Container, 8, 12, 10, 12)

    Library:MakeDraggable(Holder, Top, true)
    return Holder, Container
end

--// Watermark \\--
do
    -- [icon tile]  Title  |  text
    local Watermark = Library:AddDraggableLabel("")
    Watermark:SetVisible(false)
    Library.Watermark = Watermark

    local Content = Watermark.Content
    local TitleLabel = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        FontFace = BoldFont,
        LayoutOrder = 0,
        Size = UDim2.fromOffset(0, 22),
        Text = "Onyx",
        TextSize = 14,
        Parent = Content,
    })
    local Separator = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        LayoutOrder = 0,
        Size = UDim2.fromOffset(1, 14),
        Parent = Content,
    })
    -- order: tile(-2) title(-1) separator(0) text(1)
    Watermark.IconTile.LayoutOrder = -2
    TitleLabel.LayoutOrder = -1
    Watermark.Label.TextTransparency = 0.35
    Watermark:SetIcon("zap")

    local Inset = game:GetService("GuiService"):GetGuiInset()
    Watermark.Holder.Position = UDim2.fromOffset(12, Inset.Y + 10)

    function Watermark:SetTitle(Text: string)
        TitleLabel.Text = Text
    end

    function Library:SetWatermark(Text: string)
        Watermark:SetText(Text)
        Separator.Visible = Text ~= nil and Text ~= ""
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        Watermark:SetVisible(Visible)
    end
end

--// Keybind list \\--
do
    Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds", "keyboard")
    Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
    Library.KeybindFrame.Position = UDim2.new(0, 8, 0.5, 0)
    Library.KeybindFrame.Visible = false
end


--// Keybind list entries \\--
local function CreateKeybindEntry()
    local Entry = { Loaded = true, Normal = true, State = false }

    local Holder = New("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Text = "",
        Visible = false,
        Parent = Library.KeybindContainer,
    })
    local Box = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = "MainColor",
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12),
        Visible = false,
        Parent = Holder,
    })
    Corner(Box, 3)
    local BoxStroke = Stroke(Box)
    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextSize = 13,
        TextTransparency = 0.45,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    Entry.Holder = Holder

    function Entry:Display(State)
        Entry.State = State
        Label.TextTransparency = State and 0 or 0.45
        if Entry.Normal then
            Library.Registry[Label] = Library.Registry[Label] or {}
            Library.Registry[Label].TextColor3 = State and "AccentColor" or "FontColor"
            Label.TextColor3 = State and Library.Scheme.AccentColor or Library.Scheme.FontColor
        else
            Box.BackgroundColor3 = State and Library.Scheme.AccentColor or Library.Scheme.MainColor
            Library.Registry[Box].BackgroundColor3 = State and "AccentColor" or "MainColor"
            BoxStroke.Transparency = State and 1 or 0
        end
    end
    function Entry:SetText(Text)
        Label.Text = Text
    end
    function Entry:SetVisibility(Visible)
        Holder.Visible = Visible
    end
    function Entry:SetNormal(Normal)
        Entry.Normal = Normal
        Box.Visible = not Normal
        Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(19, 0)
        Label.Size = Normal and UDim2.fromScale(1, 1) or UDim2.new(1, -19, 1, 0)
        if not Normal then
            Library.Registry[Label] = Library.Registry[Label] or {}
            Library.Registry[Label].TextColor3 = "FontColor"
            Label.TextColor3 = Library.Scheme.FontColor
        end
        Entry:Display(Entry.State)
    end

    table.insert(Library.KeybindToggles, Entry)
    return Entry
end

local BaseAddons = {}
do
    local Funcs = {}

    local SpecialKeys = {
        ["MB1"] = Enum.UserInputType.MouseButton1,
        ["MB2"] = Enum.UserInputType.MouseButton2,
        ["MB3"] = Enum.UserInputType.MouseButton3,
    }
    local SpecialKeysInput = {
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
    }
    local Modifiers = {
        ["LAlt"] = Enum.KeyCode.LeftAlt,
        ["RAlt"] = Enum.KeyCode.RightAlt,
        ["LCtrl"] = Enum.KeyCode.LeftControl,
        ["RCtrl"] = Enum.KeyCode.RightControl,
        ["LShift"] = Enum.KeyCode.LeftShift,
        ["RShift"] = Enum.KeyCode.RightShift,
        ["Tab"] = Enum.KeyCode.Tab,
        ["CapsLock"] = Enum.KeyCode.CapsLock,
    }
    local ModifiersInput = {}
    for Name, Code in Modifiers do
        ModifiersInput[Code] = Name
    end

    local function GetActiveModifiers()
        local Active = {}
        for Name, Code in Modifiers do
            if UserInputService:IsKeyDown(Code) then
                table.insert(Active, Name)
            end
        end
        return Active
    end

    local function AreModifiersHeld(Required)
        if typeof(Required) ~= "table" or #Required == 0 then
            return true
        end
        local Active = GetActiveModifiers()
        for _, Name in Required do
            if not table.find(Active, Name) then
                return false
            end
        end
        return true
    end

    local function VerifyModifiers(Current)
        if typeof(Current) ~= "table" then
            return {}
        end
        local Valid = {}
        for _, Name in Current do
            if Modifiers[Name] then
                table.insert(Valid, Name)
            end
        end
        return Valid
    end

    local function AddonHolderOf(ParentObj)
        return ParentObj.AddonHolder or ParentObj.TextLabel
    end

    function Funcs:AddKeyPicker(Idx, Info)
        if self.Destroyed then
            return nil
        end
        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local IsForButton = ParentObj.Type == "Button" or ParentObj.Type == "SubButton"
        if IsForButton then
            assert(Info.Mode == "Press", "KeyPicker on Buttons can only be applied with the 'Press' mode.")
        end

        local KeyPicker = {
            Connections = {},
            Text = Info.Text,
            Value = Info.Default,
            Modifiers = VerifyModifiers(Info.DefaultModifiers),
            DisplayValue = Info.Default,

            Blacklisted = Info.Blacklisted,
            BlacklistedModifiers = Info.BlacklistedModifiers,
            Whitelisted = Info.Whitelisted,
            WhitelistedModifiers = Info.WhitelistedModifiers,

            Toggled = false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,
            MenuVisible = Info.NoUI ~= true,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label" or IsForButton, "KeyPicker with the mode 'Press' can be only applied on Labels and Buttons.")
            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
        end
        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle", "Hold" }
            if not table.find(Info.Modes, KeyPicker.Mode) then
                KeyPicker.Mode = "Toggle"
            end
            -- start in sync with the toggle instead of forcing it off
            if ParentObj.Type == "Toggle" then
                KeyPicker.Toggled = ParentObj.Value == true
            end
        end
        if #KeyPicker.Modifiers > 0 then
            KeyPicker.DisplayValue = table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value
        end

        local Picking = false

        local Picker = New("TextButton", {
            BackgroundColor3 = "BackgroundColor",
            FontFace = MonoFont,
            Size = UDim2.fromOffset(26, 18),
            Text = KeyPicker.DisplayValue,
            TextSize = 12,
            TextTransparency = 0.25,
            LayoutOrder = 5,
            Parent = AddonHolderOf(ParentObj),
        })
        Corner(Picker, 4)
        local PickerStroke = Stroke(Picker)

        local KeybindsToggle = CreateKeybindEntry()
        KeybindsToggle.Holder.MouseButton1Click:Connect(function()
            if KeyPicker.Mode ~= "Toggle" or ParentObj.Type ~= "Toggle" or ParentObj.Disabled then
                return
            end
            KeyPicker.Toggled = not KeyPicker.Toggled
            KeyPicker:DoClick()
            KeyPicker:Update()
        end)

        --// Mode menu \\--
        local MenuTable = CreatePopup(Picker, { Width = 96, Align = "Right" })
        List(MenuTable.Frame, 2)
        Padding(MenuTable.Frame, 4)
        MenuTable.Frame.AutomaticSize = Enum.AutomaticSize.Y

        local ModeButtons = {}
        for Order, Mode in Info.Modes do
            local ModeButton = {}
            local Button = New("TextButton", {
                BackgroundColor3 = "AccentColor",
                BackgroundTransparency = 1,
                FontFace = MediumFont,
                LayoutOrder = Order,
                Size = UDim2.new(1, 0, 0, 24),
                Text = Mode,
                TextSize = 13,
                TextTransparency = 0.45,
                Parent = MenuTable.Frame,
            })
            Corner(Button, 4)

            function ModeButton:Select()
                for _, Other in ModeButtons do
                    Other:Deselect()
                end
                KeyPicker.Mode = Mode
                Button.TextTransparency = 0
                Button.BackgroundTransparency = 0.82
                MenuTable:Close()
            end
            function ModeButton:Deselect()
                KeyPicker.Mode = nil
                Button.TextTransparency = 0.45
                Button.BackgroundTransparency = 1
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
                KeyPicker:Update()
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end
            ModeButtons[Mode] = ModeButton
        end
        if not KeyPicker.Mode and ModeButtons[Info.Modes[1]] then
            ModeButtons[Info.Modes[1]]:Select()
        end

        local function SetPickingState(State)
            Picking = State
            Library.IsPicking = State
            if ParentObj.Type == "Toggle" then
                ParentObj.AnyKeyPickerPicking = State
            end
            Tween(PickerStroke, Library.TweenInfo, { Transparency = 0 })
            PickerStroke.Color = State and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
            Library.Registry[PickerStroke].Color = State and "AccentColor" or "OutlineColor"
        end

        function KeyPicker:Display(PickerText)
            if Library.Unloaded then
                return
            end
            local Text = PickerText or KeyPicker.DisplayValue
            local X = Library:GetTextBounds(Text, Picker.FontFace, Picker.TextSize, 1000)
            Picker.Text = Text
            Picker.Size = UDim2.fromOffset(math.max(X + 12, 26), 18)
        end

        function KeyPicker:Update()
            local Disabled = ParentObj.Disabled == true
            KeyPicker:Display()
            Picker.Active = not Disabled
            Picker.TextTransparency = Disabled and 0.75 or 0.25

            if Disabled and MenuTable.Active then
                MenuTable:Close()
            end
            if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                ParentObj:SetValue(State)
            end
            if Info.NoUI then
                return
            end

            KeybindsToggle:SetNormal(not ShowToggle)
            KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode or "?"))
            KeybindsToggle:SetVisibility(KeyPicker.MenuVisible ~= false)
            KeybindsToggle:Display(State)
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" or Picking or not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end
                if SpecialKeys[Key] then
                    if Library.Toggled then
                        return false
                    end
                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key]) and not UserInputService:GetFocusedTextBox()
                end
                local Ok, Code = pcall(function()
                    return Enum.KeyCode[Key]
                end)
                return Ok and UserInputService:IsKeyDown(Code) and not UserInputService:GetFocusedTextBox() or false
            end
            return KeyPicker.Toggled
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end
        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if Picking or ParentObj.Disabled then
                return
            end
            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = true
            end

            if ParentObj.Type == "Toggle" and KeyPicker.SyncToggleState == false and KeyPicker.Mode == "Toggle" then
                -- plain Obsidian behaviour: the bind only fires callbacks, the toggle keeps its own state
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
            if IsForButton then
                Library:SafeCallback(ParentObj.Func, KeyPicker.Toggled)
            end
            if Library.ToggleKeybind == KeyPicker and Library.Toggle then
                Library:Toggle()
            end
            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        local function ResolveKey(Key)
            if Key == nil or Key == "None" then
                return true, nil
            end
            if SpecialKeys[Key] then
                return true, SpecialKeys[Key]
            end
            return pcall(function()
                return Enum.KeyCode[Key]
            end)
        end

        function KeyPicker:RunChanged(IsKeyValid, KeyCode)
            if ParentObj.Disabled then
                return
            end
            if IsKeyValid == nil then
                IsKeyValid, KeyCode = ResolveKey(KeyPicker.Value)
            end
            local InputModifiers = {}
            for _, Name in KeyPicker.Modifiers do
                table.insert(InputModifiers, Modifiers[Name])
            end
            Library:SafeCallback(KeyPicker.ChangedCallback, KeyCode, InputModifiers)
            Library:SafeCallback(KeyPicker.Changed, KeyCode, InputModifiers)
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode, NewModifiers = Data[1], Data[2], Data[3]
            local IsKeyValid, KeyCode = ResolveKey(Key)

            if Key == nil or Key == "None" then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers = VerifyModifiers(typeof(NewModifiers) == "table" and NewModifiers or KeyPicker.Modifiers)
            KeyPicker.DisplayValue = #KeyPicker.Modifiers > 0 and (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value) or KeyPicker.Value

            if Mode and ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            KeyPicker:Update()
            KeyPicker:RunChanged(IsKeyValid, KeyCode)
        end

        function KeyPicker:SetText(Text)
            KeyPicker.Text = Text
            KeyPicker:Update()
        end

        function KeyPicker:SetMenuVisibility(Visible: boolean)
            KeyPicker.MenuVisible = Visible
            KeyPicker:Update()
        end

        local function IsValidInput(Input)
            if Input.KeyCode == Enum.KeyCode.Escape then
                return true
            end
            local IsMod = Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
            local KeyName
            if SpecialKeysInput[Input.UserInputType] then
                KeyName = SpecialKeysInput[Input.UserInputType]
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                KeyName = IsMod and ModifiersInput[Input.KeyCode] or Input.KeyCode.Name
            else
                return false
            end
            if IsMod then
                if #KeyPicker.WhitelistedModifiers > 0 and not table.find(KeyPicker.WhitelistedModifiers, KeyName) then
                    return false
                end
                if table.find(KeyPicker.BlacklistedModifiers, KeyName) then
                    return false
                end
            else
                if #KeyPicker.Whitelisted > 0 and not table.find(KeyPicker.Whitelisted, KeyName) then
                    return false
                end
                if table.find(KeyPicker.Blacklisted, KeyName) then
                    return false
                end
            end
            return true
        end

        table.insert(KeyPicker.Connections, Picker.MouseButton1Click:Connect(function()
            if Picking or Library.IsPicking or ParentObj.Disabled then
                return
            end
            SetPickingState(true)
            KeyPicker:Display("...")

            local ActiveModifiers = {}
            local CurrentInput

            -- skip the click that started picking
            task.wait()

            while true do
                local Input = UserInputService.InputBegan:Wait()
                if Library.Unloaded or UserInputService:GetFocusedTextBox() then
                    SetPickingState(false)
                    KeyPicker:Display()
                    return
                end
                if IsValidInput(Input) then
                    CurrentInput = Input
                    break
                end
            end

            -- modifier: wait for release (bind the modifier itself) or for a follow-up key
            while CurrentInput.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[CurrentInput.KeyCode] do
                local ModName = ModifiersInput[CurrentInput.KeyCode]
                KeyPicker:Display((#ActiveModifiers > 0 and table.concat(ActiveModifiers, " + ") .. " + " or "") .. ModName .. " + ...")

                local NextInput, Released
                local Began = UserInputService.InputBegan:Connect(function(Input)
                    if IsValidInput(Input) then
                        NextInput = Input
                    end
                end)
                local Ended = UserInputService.InputEnded:Connect(function(Input)
                    if Input.KeyCode == CurrentInput.KeyCode then
                        Released = true
                    end
                end)
                repeat
                    task.wait()
                until Released or NextInput or Library.Unloaded
                Began:Disconnect()
                Ended:Disconnect()

                if Released or Library.Unloaded then
                    break
                end
                if not table.find(ActiveModifiers, ModName) then
                    table.insert(ActiveModifiers, ModName)
                end
                CurrentInput = NextInput
                if CurrentInput.KeyCode == Enum.KeyCode.Escape then
                    break
                end
            end

            local Key = "Unknown"
            if SpecialKeysInput[CurrentInput.UserInputType] then
                Key = SpecialKeysInput[CurrentInput.UserInputType]
            elseif CurrentInput.UserInputType == Enum.UserInputType.Keyboard then
                Key = CurrentInput.KeyCode == Enum.KeyCode.Escape and "None" or CurrentInput.KeyCode.Name
            end
            if Key == "None" or Key == "Unknown" then
                ActiveModifiers = {}
            end

            KeyPicker.Toggled = ParentObj.Type == "Toggle" and ParentObj.Value or false
            KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

            -- wait for the bound key to be released so it doesn't immediately fire
            repeat
                task.wait()
            until Library.Unloaded
                or not (
                    (SpecialKeysInput[CurrentInput.UserInputType] and UserInputService:IsMouseButtonPressed(CurrentInput.UserInputType))
                    or (CurrentInput.UserInputType == Enum.UserInputType.Keyboard and UserInputService:IsKeyDown(CurrentInput.KeyCode))
                )
            SetPickingState(false)
        end))

        table.insert(KeyPicker.Connections, Picker.MouseButton2Click:Connect(function()
            if ParentObj.Disabled then
                return
            end
            MenuTable:Toggle()
        end))

        Picker.MouseEnter:Connect(function()
            if not ParentObj.Disabled then
                Tween(Picker, Library.TweenInfo, { TextTransparency = 0 })
            end
        end)
        Picker.MouseLeave:Connect(function()
            if not ParentObj.Disabled then
                Tween(Picker, Library.TweenInfo, { TextTransparency = 0.25 })
            end
        end)

        local HoldConnection
        table.insert(KeyPicker.Connections, UserInputService.InputBegan:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end
            local IsMouse = IsMouseClickInput(Input)
            if
                ParentObj.Disabled
                or KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or Library.IsPicking
                or UserInputService:GetFocusedTextBox()
                or (IsMouse and Library.Toggled)
            then
                return
            end

            local Key = KeyPicker.Value
            local Matches = SpecialKeysInput[Input.UserInputType] == Key
                or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
            if not (Matches and AreModifiersHeld(KeyPicker.Modifiers)) then
                return
            end

            if KeyPicker.Mode == "Toggle" then
                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
            elseif KeyPicker.Mode == "Press" then
                KeyPicker:DoClick()
            elseif KeyPicker.Mode == "Hold" then
                if HoldConnection then
                    HoldConnection:Disconnect()
                end
                HoldConnection = Input.Changed:Connect(function()
                    if KeyPicker:GetState() then
                        return
                    end
                    KeyPicker:Update()
                    if HoldConnection then
                        HoldConnection:Disconnect()
                        HoldConnection = nil
                    end
                end)
            end
            KeyPicker:Update()
        end))

        table.insert(KeyPicker.Connections, UserInputService.InputEnded:Connect(function(Input)
            if Library.Unloaded or KeyPicker.Mode ~= "Hold" then
                return
            end
            task.defer(KeyPicker.Update, KeyPicker)
        end))

        KeyPicker:Update()

        ParentObj.Addons = ParentObj.Addons or {}
        table.insert(ParentObj.Addons, KeyPicker)

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers)

        function KeyPicker:Destroy()
            KeyPicker.Destroyed = true
            for _, Connection in KeyPicker.Connections do
                Connection:Disconnect()
            end
            if HoldConnection then
                HoldConnection:Disconnect()
            end
            KeybindsToggle.Holder:Destroy()
            local Index = table.find(Library.KeybindToggles, KeybindsToggle)
            if Index then
                table.remove(Library.KeybindToggles, Index)
            end
            MenuTable:Destroy()
            Picker:Destroy()
            if ParentObj.Addons then
                local AddonIndex = table.find(ParentObj.Addons, KeyPicker)
                if AddonIndex then
                    table.remove(ParentObj.Addons, AddonIndex)
                end
            end
            Options[Idx] = nil
        end

        Options[Idx] = KeyPicker
        if ParentObj.RefreshAddons then
            ParentObj:RefreshAddons()
        end
        return self
    end

    --// Colour picker \\--
    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end

    function Funcs:AddColorPicker(Idx, Info)
        if self.Destroyed then
            return nil
        end
        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ColorPicker = {
            Connections = {},
            Destroyed = false,
            Value = Info.Default,
            Transparency = Info.Transparency or 0,
            Title = Info.Title,
            Callback = Info.Callback,
            Changed = Info.Changed,
            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local Holder = New("TextButton", {
            BackgroundColor3 = ColorPicker.Value,
            Size = UDim2.fromOffset(28, 16),
            Text = "",
            LayoutOrder = 4,
            Parent = AddonHolderOf(ParentObj),
        })
        Corner(Holder, 4)
        local HolderStroke = New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Library:GetDarkerColor(ColorPicker.Value),
            Parent = Holder,
        })
        local HolderTransparency = New("ImageLabel", {
            Image = Assets.TransparencyTexture,
            ImageTransparency = 1 - ColorPicker.Transparency,
            ScaleType = Enum.ScaleType.Tile,
            TileSize = UDim2.fromOffset(8, 8),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })
        Corner(HolderTransparency, 4)

        --// Popup \\--
        local Menu = CreatePopup(Holder, { Width = 236, Align = "Right" })
        local MenuFrame = Menu.Frame
        MenuFrame.AutomaticSize = Enum.AutomaticSize.Y
        Padding(MenuFrame, 10)
        List(MenuFrame, 8)

        New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = SemiBoldFont,
            Size = UDim2.new(1, 0, 0, 14),
            Text = ColorPicker.Title or ParentObj.Text or "Color",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
            Parent = MenuFrame,
        })

        local Maps = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 150),
            LayoutOrder = 1,
            Parent = MenuFrame,
        })

        local SatVibMap = New("ImageButton", {
            BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1),
            Image = Assets.SaturationMap,
            Size = UDim2.new(1, Info.Transparency and -44 or -22, 1, 0),
            Parent = Maps,
        })
        Corner(SatVibMap, 4)
        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            Size = UDim2.fromOffset(10, 10),
            Parent = SatVibMap,
        })
        Corner(SatVibCursor, 5)
        New("UIStroke", { Color = "DarkColor", Thickness = 1.5, Parent = SatVibCursor })

        local HueSelector = New("ImageButton", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.new(1, Info.Transparency and -22 or 0, 0, 0),
            Size = UDim2.new(0, 14, 1, 0),
            Parent = Maps,
        })
        Corner(HueSelector, 4)
        New("UIGradient", { Color = ColorSequence.new(HueSequenceTable), Rotation = 90, Parent = HueSelector })
        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 4, 0, 3),
            Parent = HueSelector,
        })
        Corner(HueCursor, 2)
        New("UIStroke", { Color = "DarkColor", Parent = HueCursor })

        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                AnchorPoint = Vector2.new(1, 0),
                Image = Assets.TransparencyTexture,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.fromOffset(8, 8),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 14, 1, 0),
                Parent = Maps,
            })
            Corner(TransparencySelector, 4)
            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            Corner(TransparencyColor, 4)
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
                Parent = TransparencyColor,
            })
            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "WhiteColor",
                Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                Size = UDim2.new(1, 4, 0, 3),
                Parent = TransparencySelector,
            })
            Corner(TransparencyCursor, 2)
            New("UIStroke", { Color = "DarkColor", Parent = TransparencyCursor })
        end

        local InfoRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            LayoutOrder = 2,
            Parent = MenuFrame,
        })
        List(InfoRow, 6, Enum.FillDirection.Horizontal)

        local function InfoBox(Width, Order)
            local Box = New("TextBox", {
                BackgroundColor3 = "BackgroundColor",
                FontFace = MonoFont,
                LayoutOrder = Order,
                Size = Width,
                TextSize = 12,
                Parent = InfoRow,
            })
            Corner(Box, 4)
            local BoxStroke = Stroke(Box)
            Box.Focused:Connect(function()
                BoxStroke.Color = Library.Scheme.AccentColor
            end)
            Box.FocusLost:Connect(function()
                BoxStroke.Color = Library.Scheme.OutlineColor
            end)
            return Box
        end
        local HexBox = InfoBox(UDim2.new(0.42, -3, 1, 0), 1)
        local RgbBox = InfoBox(UDim2.new(0.58, -3, 1, 0), 2)

        --// End popup \\--

        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            if TransparencyColor then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value
                TransparencyCursor.Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
            end
            SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)

            HexBox.Text = "#" .. ColorPicker.Value:ToHex():upper()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255 + 0.5),
                math.floor(ColorPicker.Value.G * 255 + 0.5),
                math.floor(ColorPicker.Value.B * 255 + 0.5),
            }, ", ")

            local Disabled = ParentObj.Disabled == true
            Holder.BackgroundColor3 = Disabled and ColorPicker.Value:Lerp(Library.Scheme.BackgroundColor, 0.5) or ColorPicker.Value
            HolderStroke.Color = Library:GetDarkerColor(ColorPicker.Value)
            HolderTransparency.ImageTransparency = 1 - ColorPicker.Transparency
        end

        function ColorPicker:RunChanged()
            if ParentObj.Disabled then
                return
            end
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:Update()
            ColorPicker:Display()
            if ParentObj.Disabled and Menu.Active then
                Menu:Close()
            end
            ColorPicker:RunChanged()
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color3.fromHSV(HSV[1], HSV[2], HSV[3]))
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Info.Transparency and (Transparency or 0) or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        table.insert(ColorPicker.Connections, Holder.MouseButton1Click:Connect(function()
            if ParentObj.Disabled then
                return
            end
            Menu:Toggle()
        end))

        -- right click copies / pastes the colour (Linoria-style)
        table.insert(ColorPicker.Connections, Holder.MouseButton2Click:Connect(function()
            if ParentObj.Disabled then
                return
            end
            Library.ColorClipboard = ColorPicker.Value
            if setclipboard then
                pcall(setclipboard, "#" .. ColorPicker.Value:ToHex())
            end
            Library:Notify({ Title = "Color copied", Description = "#" .. ColorPicker.Value:ToHex():upper(), Time = 2, Icon = "clipboard-check" })
        end))

        local function TrackDrag(Target: GuiObject, OnMove: (Vector2) -> ())
            table.insert(ColorPicker.Connections, Target.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end
                local function Step()
                    local Mouse = GetMouseAbs()
                    local Pos, Size = Target.AbsolutePosition, Target.AbsoluteSize
                    OnMove(Vector2.new(
                        math.clamp((Mouse.X - Pos.X) / Size.X, 0, 1),
                        math.clamp((Mouse.Y - Pos.Y) / Size.Y, 0, 1)
                    ))
                    ColorPicker:Display()
                end
                Step()
                while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or Input.UserInputState ~= Enum.UserInputState.End and Input.UserInputType == Enum.UserInputType.Touch do
                    RunService.RenderStepped:Wait()
                    if Library.Unloaded then
                        return
                    end
                    Step()
                end
                ColorPicker:RunChanged()
            end))
        end

        TrackDrag(SatVibMap, function(Pos)
            ColorPicker.Sat = Pos.X
            ColorPicker.Vib = 1 - Pos.Y
        end)
        TrackDrag(HueSelector, function(Pos)
            ColorPicker.Hue = Pos.Y
        end)
        if TransparencySelector then
            TrackDrag(TransparencySelector, function(Pos)
                ColorPicker.Transparency = Pos.Y
            end)
        end

        table.insert(ColorPicker.Connections, HexBox.FocusLost:Connect(function(Enter)
            if not Enter then
                ColorPicker:Display()
                return
            end
            local Ok, Color = pcall(Color3.fromHex, HexBox.Text)
            if Ok and typeof(Color) == "Color3" then
                ColorPicker:SetHSVFromRGB(Color)
            end
            ColorPicker:Update()
        end))
        table.insert(ColorPicker.Connections, RgbBox.FocusLost:Connect(function(Enter)
            if not Enter then
                ColorPicker:Display()
                return
            end
            local R, G, B = RgbBox.Text:match("(%d+)%D+(%d+)%D+(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(math.clamp(tonumber(R), 0, 255), math.clamp(tonumber(G), 0, 255), math.clamp(tonumber(B), 0, 255)))
            end
            ColorPicker:Update()
        end))

        ColorPicker:Display()
        ColorPicker.Default = ColorPicker.Value

        ParentObj.Addons = ParentObj.Addons or {}
        table.insert(ParentObj.Addons, ColorPicker)

        function ColorPicker:Destroy()
            ColorPicker.Destroyed = true
            for _, Connection in ColorPicker.Connections do
                Connection:Disconnect()
            end
            Menu:Destroy()
            Holder:Destroy()
            if ParentObj.Addons then
                local Index = table.find(ParentObj.Addons, ColorPicker)
                if Index then
                    table.remove(ParentObj.Addons, Index)
                end
            end
            Options[Idx] = nil
        end

        Options[Idx] = ColorPicker
        if ParentObj.RefreshAddons then
            ParentObj:RefreshAddons()
        end
        return self
    end

    BaseAddons.__index = Funcs
end


--// Shared element plumbing \\--
local function AttachAddonHolder(Element, Row: GuiObject, Label: GuiObject, LeftInset: number?, Extra: GuiObject?)
    local Holder = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.new(0, 0, 1, 0),
        Parent = Row,
    })
    List(Holder, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

    if Extra then
        Extra.LayoutOrder = 100
        Extra.Parent = Holder
    end

    local function Refresh()
        local Width = Holder.AbsoluteSize.X / Library.DPIScale
        local Inset = LeftInset or 0
        Label.Position = UDim2.new(0, Inset, Label.Position.Y.Scale, Label.Position.Y.Offset)
        Label.Size = UDim2.new(1, -(Width + Inset + (Width > 0 and 8 or 0)), Label.Size.Y.Scale, Label.Size.Y.Offset)
    end
    Holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(Refresh)
    Refresh()

    Element.AddonHolder = Holder
    Element.RefreshAddons = function()
        task.defer(Refresh)
    end
    return Holder
end

local function RegisterElement(Groupbox, Element, Holder)
    Element.Holder = Holder
    table.insert(Groupbox.Elements, Element)
    Groupbox:Resize()
end

local function RemoveElement(Groupbox, Element)
    local Index = table.find(Groupbox.Elements, Element)
    if Index then
        table.remove(Groupbox.Elements, Index)
    end
    Groupbox:Resize()
end

local function HoverTween(Target: GuiObject, Property: string, Normal: any, Hover: any, Guard: (() -> boolean)?)
    Target.MouseEnter:Connect(function()
        if Guard and not Guard() then
            return
        end
        Tween(Target, Library.TweenInfo, { [Property] = typeof(Hover) == "function" and Hover() or Hover })
    end)
    Target.MouseLeave:Connect(function()
        if Guard and not Guard() then
            return
        end
        Tween(Target, Library.TweenInfo, { [Property] = typeof(Normal) == "function" and Normal() or Normal })
    end)
end

local BaseGroupbox = {}
do
    local Funcs = {}

    --// Divider \\--
    function Funcs:AddDivider(...)
        if self.Destroyed then
            return nil
        end
        local Params = select(1, ...)
        local Text
        local MarginTop, MarginBottom = 0, 0
        if typeof(Params) == "table" then
            Text = Params.Text
            MarginTop = Params.MarginTop or Params.Margin or 0
            MarginBottom = Params.MarginBottom or Params.Margin or 0
        elseif typeof(Params) == "string" then
            Text = Params
        end

        local Groupbox = self
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, (Text and 16 or 8) + MarginTop + MarginBottom),
            Parent = Groupbox.Container,
        })
        Padding(Holder, MarginTop, 0, MarginBottom, 0)

        local Inner = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = Holder })
        local LeftLine = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = "OutlineColor",
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.new(1, 0, 0, 1),
            Parent = Inner,
        })
        local TextLabel, RightLine
        local function Layout()
            if not TextLabel then
                LeftLine.Size = UDim2.new(1, 0, 0, 1)
                return
            end
            local X = Library:GetTextBounds(TextLabel.Text, TextLabel.FontFace, TextLabel.TextSize, 1000)
            local Half = (X / 2) + 8
            LeftLine.Size = UDim2.new(0.5, -Half, 0, 1)
            RightLine.Size = UDim2.new(0.5, -Half, 0, 1)
        end
        if Text then
            TextLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                FontFace = MediumFont,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Text = Text,
                TextSize = 12,
                TextTransparency = 0.45,
                Parent = Inner,
            })
            RightLine = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "OutlineColor",
                Position = UDim2.fromScale(1, 0.5),
                Parent = Inner,
            })
        end
        Layout()

        local Divider = { Type = "Divider", Text = Text, Visible = true, Holder = Holder, Destroyed = false }
        function Divider:SetText(NewText)
            if TextLabel then
                TextLabel.Text = NewText
                Divider.Text = NewText
                Layout()
            end
        end
        function Divider:SetVisible(Value)
            Divider.Visible = Value
            Holder.Visible = Value
            Groupbox:Resize()
        end
        function Divider:Destroy()
            Divider.Destroyed = true
            Holder:Destroy()
            RemoveElement(Groupbox, Divider)
        end

        RegisterElement(Groupbox, Divider, Holder)
        return Divider
    end

    --// Label \\--
    function Funcs:AddLabel(...)
        if self.Destroyed then
            return nil
        end
        local Data = {}
        local First, Second = select(1, ...), select(2, ...)
        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second
            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = if typeof(Params.Visible) == "boolean" then Params.Visible else true
            Data.Idx = typeof(Second) == "table" and First or nil
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Groupbox = self
        local Label = {
            Connections = {},
            Destroyed = false,
            Text = Data.Text,
            DoesWrap = Data.DoesWrap,
            Addons = {},
            Visible = Data.Visible,
            Type = "Label",
            Parent = Groupbox,
        }

        local Row = New("Frame", {
            AutomaticSize = Data.DoesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Visible = Label.Visible,
            Parent = Groupbox.Container,
        })
        local TextLabel = New("TextLabel", {
            AutomaticSize = Data.DoesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, Data.DoesWrap and 0 or 1, Data.DoesWrap and 20 or 0),
            Text = Label.Text,
            TextSize = Data.Size,
            TextTransparency = 0.1,
            TextTruncate = Data.DoesWrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = Row,
        })
        Label.TextLabel = TextLabel
        Label.Container = Row
        AttachAddonHolder(Label, Row, TextLabel)
        Label.AddonHolder.AnchorPoint = Vector2.new(1, 0)
        Label.AddonHolder.Position = UDim2.fromScale(1, 0)
        Label.AddonHolder.Size = UDim2.new(0, 0, 0, 20)

        function Label:Display() end
        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible
            Row.Visible = Visible
            Groupbox:Resize()
        end
        function Label:SetText(Text: string)
            Label.Text = Text
            TextLabel.Text = Text
            Groupbox:Resize()
        end
        function Label:Destroy()
            Label.Destroyed = true
            for _, Addon in table.clone(Label.Addons) do
                if Addon.Destroy then
                    Addon:Destroy()
                end
            end
            Row:Destroy()
            RemoveElement(Groupbox, Label)
            if Data.Idx then
                Labels[Data.Idx] = nil
            end
        end

        RegisterElement(Groupbox, Label, Row)
        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end
        return setmetatable(Label, BaseAddons)
    end

    --// Button \\--
    function Funcs:AddButton(...)
        if self.Destroyed then
            return nil
        end
        local function GetInfo(...)
            local Info = {}
            local First, Second = select(1, ...), select(2, ...)
            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second
                Info.Text = Params.Text or ""
                Info.Func = Params.Func or Params.Callback or function() end
                Info.DoubleClick = Params.DoubleClick
                Info.Icon = Params.Icon or Params.IconName
                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip
                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = if typeof(Params.Visible) == "boolean" then Params.Visible else true
                Info.Idx = typeof(Second) == "table" and First or nil
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false
                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end
            return Info
        end

        local Info = GetInfo(...)
        local Groupbox = self

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            Visible = Info.Visible,
            Parent = Groupbox.Container,
        })
        List(Holder, 6, Enum.FillDirection.Horizontal)

        local Members = {}
        local function Relayout()
            local Visible = {}
            for _, Member in Members do
                if Member.Visible and not Member.Destroyed then
                    table.insert(Visible, Member)
                end
            end
            local Count = math.max(#Visible, 1)
            for _, Member in Visible do
                Member.Base.Size = UDim2.new(1 / Count, -(6 * (Count - 1)) / Count, 1, 0)
            end
        end

        local function CreateButtonBase(Object, ButtonInfo)
            local Base = New("TextButton", {
                Active = not ButtonInfo.Disabled,
                BackgroundColor3 = Library.Colors.Elevated,
                ClipsDescendants = true,
                Text = "",
                Visible = ButtonInfo.Visible,
                Parent = Holder,
            })
            ScaledCorner(Base, 0.75)
            local BaseStroke = Stroke(Base)

            local Content = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(0, 0, 1, 0),
                Parent = Base,
            })
            List(Content, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

            local IconImage = IconLabel({ Size = UDim2.fromOffset(15, 15), Visible = false, LayoutOrder = 0, Parent = Content }, nil)
            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                FontFace = MediumFont,
                LayoutOrder = 1,
                Size = UDim2.new(0, 0, 1, 0),
                Text = ButtonInfo.Text,
                TextSize = 14,
                TextTransparency = 0.15,
                Parent = Content,
            })
            New("UISizeConstraint", { MaxSize = Vector2.new(400, 30), Parent = Label })

            Object.Base = Base
            Object.TextLabel = Label
            Object.AddonHolder = Content
            Object.IconImage = IconImage

            local function Colors()
                local Risky = Object.Risky
                Library.Registry[Label] = Library.Registry[Label] or {}
                Library.Registry[Label].TextColor3 = Risky and "RedColor" or "FontColor"
                Label.TextColor3 = Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                Library.Registry[IconImage] = Library.Registry[IconImage] or {}
                Library.Registry[IconImage].ImageColor3 = Risky and "RedColor" or "FontColor"
                IconImage.ImageColor3 = Label.TextColor3
                Base.BackgroundTransparency = Object.Disabled and 0.5 or 0
                Label.TextTransparency = Object.Disabled and 0.7 or 0.15
                IconImage.ImageTransparency = Label.TextTransparency
                BaseStroke.Transparency = Object.Disabled and 0.5 or 0
            end
            Object.UpdateColors = Colors

            Base.MouseEnter:Connect(function()
                if Object.Disabled then
                    return
                end
                Tween(Base, Library.TweenInfo, { BackgroundColor3 = Library.Colors.Hover() })
                Tween(Label, Library.TweenInfo, { TextTransparency = 0 })
            end)
            Base.MouseLeave:Connect(function()
                if Object.Disabled then
                    return
                end
                Tween(Base, Library.TweenInfo, { BackgroundColor3 = Library.Colors.Elevated() })
                Tween(Label, Library.TweenInfo, { TextTransparency = 0.15 })
            end)

            -- ripple-free press feedback: quick accent stroke flash
            local function Flash()
                BaseStroke.Color = Library.Scheme.AccentColor
                Tween(BaseStroke, Library.SlowTweenInfo, { Color = Library.Scheme.OutlineColor })
            end

            local Confirming = false
            Base.MouseButton1Click:Connect(function()
                if Object.Disabled or Object.Locked then
                    return
                end
                if Object.DoubleClick then
                    if not Confirming then
                        Confirming = true
                        Label.Text = "Are you sure?"
                        Library.Registry[Label].TextColor3 = "AccentColor"
                        Label.TextColor3 = Library.Scheme.AccentColor
                        task.delay(1.25, function()
                            if Confirming then
                                Confirming = false
                                Label.Text = Object.Text
                                Colors()
                            end
                        end)
                        return
                    end
                    Confirming = false
                    Label.Text = Object.Text
                    Colors()
                end
                Flash()
                Library:SafeCallback(Object.Func)
            end)

            if typeof(ButtonInfo.Tooltip) == "string" or typeof(ButtonInfo.DisabledTooltip) == "string" then
                Object.TooltipTable = Library:AddTooltip(ButtonInfo.Tooltip, ButtonInfo.DisabledTooltip, Base)
                Object.TooltipTable.Disabled = Object.Disabled
            end

            function Object:SetDisabled(Disabled: boolean)
                Object.Disabled = Disabled
                Base.Active = not Disabled
                if Object.TooltipTable then
                    Object.TooltipTable.Disabled = Disabled
                end
                Colors()
                for _, Addon in Object.Addons or {} do
                    if Addon.Update then
                        Addon:Update()
                    end
                end
            end
            function Object:SetVisible(Visible: boolean)
                Object.Visible = Visible
                Base.Visible = Visible
                Relayout()
            end
            function Object:SetText(Text: string)
                Object.Text = Text
                Label.Text = Text
            end
            function Object:SetIcon(Icon: string?)
                Object.Icon = Icon
                IconImage.Visible = Icon ~= nil and Library:ApplyIcon(IconImage, Icon) or false
            end

            Object:SetIcon(ButtonInfo.Icon)
            Colors()
            return Base
        end

        local Button = {
            Connections = {},
            Destroyed = false,
            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,
            Icon = Info.Icon,
            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = true,
            Locked = false,
            Addons = {},
            SubButtons = {},
            Type = "Button",
        }
        CreateButtonBase(Button, Info)
        table.insert(Members, Button)

        function Button:AddButton(...)
            local SubInfo = GetInfo(...)
            local SubButton = {
                Connections = {},
                Destroyed = false,
                Text = SubInfo.Text,
                Func = SubInfo.Func,
                DoubleClick = SubInfo.DoubleClick,
                Icon = SubInfo.Icon,
                Tooltip = SubInfo.Tooltip,
                DisabledTooltip = SubInfo.DisabledTooltip,
                Risky = SubInfo.Risky,
                Disabled = SubInfo.Disabled,
                Visible = SubInfo.Visible,
                Locked = false,
                Addons = {},
                Type = "SubButton",
                Parent = Button,
            }
            CreateButtonBase(SubButton, SubInfo)
            table.insert(Members, SubButton)
            table.insert(Button.SubButtons, SubButton)
            Relayout()

            function SubButton:Destroy()
                SubButton.Destroyed = true
                if SubButton.TooltipTable then
                    SubButton.TooltipTable:Destroy()
                end
                SubButton.Base:Destroy()
                local Index = table.find(Members, SubButton)
                if Index then
                    table.remove(Members, Index)
                end
                Relayout()
                if SubInfo.Idx then
                    Buttons[SubInfo.Idx] = nil
                end
            end

            if SubInfo.Idx then
                Buttons[SubInfo.Idx] = SubButton
            end
            return setmetatable(SubButton, BaseAddons)
        end

        -- Button visibility hides the whole row (sub buttons included), like Obsidian
        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible
            Holder.Visible = Visible
            Groupbox:Resize()
        end

        function Button:Destroy()
            Button.Destroyed = true
            for _, Sub in table.clone(Button.SubButtons) do
                Sub:Destroy()
            end
            if Button.TooltipTable then
                Button.TooltipTable:Destroy()
            end
            Holder:Destroy()
            RemoveElement(Groupbox, Button)
            if Info.Idx then
                Buttons[Info.Idx] = nil
            end
        end

        Relayout()
        RegisterElement(Groupbox, Button, Holder)
        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end
        return setmetatable(Button, BaseAddons)
    end

    --// Toggle shared logic \\--
    local function BuildToggle(Groupbox, Idx, Info, Variant: string)
        local Toggle = {
            Connections = {},
            Destroyed = false,
            Text = Info.Text,
            Value = Info.Default,
            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            Callback = Info.Callback,
            Changed = Info.Changed,
            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},
            AnyKeyPickerPicking = false,
            Variant = Variant,
            Type = "Toggle",
            Parent = Groupbox,
        }

        local Row = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Groupbox.Container,
        })
        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Row,
        })

        local Indicator, Knob, IndicatorStroke, Check
        if Variant == "Switch" then
            Indicator = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.fromOffset(32, 18),
            })
            Corner(Indicator, 9)
            IndicatorStroke = Stroke(Indicator)
            Knob = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "FontColor",
                BackgroundTransparency = 0.5,
                Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.fromOffset(12, 12),
                Parent = Indicator,
            })
            Corner(Knob, 6)
            AttachAddonHolder(Toggle, Row, Label, 0, Indicator)
        else
            Indicator = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(16, 16),
                Parent = Row,
            })
            Corner(Indicator, 4)
            IndicatorStroke = Stroke(Indicator)
            Check = IconLabel({
                AnchorPoint = Vector2.new(0.5, 0.5),
                ImageColor3 = Library.Colors.OnAccent,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(12, 12),
                Parent = Indicator,
            }, "check")
            New("UIScale", { Scale = 0, Parent = Check })
            AttachAddonHolder(Toggle, Row, Label, 24)
        end
        Toggle.TextLabel = Label
        Toggle.Container = Row

        local function ApplyLabelColor()
            Library.Registry[Label] = Library.Registry[Label] or {}
            Library.Registry[Label].TextColor3 = Toggle.Risky and "RedColor" or "FontColor"
            Label.TextColor3 = Toggle.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
        end

        function Toggle:UpdateColors()
            ApplyLabelColor()
            Toggle:Display(true)
        end

        function Toggle:Display(Instant: boolean?)
            if Library.Unloaded then
                return
            end
            local On = Toggle.Value == true
            local Info_ = (Instant or not Library.Animations.Groupbox) and TweenInfo.new(0) or Library.TweenInfo
            local Fade = Toggle.Disabled and 0.5 or 0

            Tween(Label, Info_, { TextTransparency = Toggle.Disabled and 0.75 or (On and 0 or 0.4) })

            Library.Registry[Indicator].BackgroundColor3 = On and "AccentColor" or "BackgroundColor"
            Tween(Indicator, Info_, {
                BackgroundColor3 = On and Library.Scheme.AccentColor or Library.Scheme.BackgroundColor,
                BackgroundTransparency = Fade,
            })
            Tween(IndicatorStroke, Info_, { Transparency = On and 1 or Fade })

            if Variant == "Switch" then
                Library.Registry[Knob].BackgroundColor3 = On and Library.Colors.OnAccent or "FontColor"
                Tween(Knob, Library.Animations.Groupbox and not Instant and Library.SpringTweenInfo or TweenInfo.new(0), {
                    Position = On and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                })
                Tween(Knob, Info_, {
                    BackgroundColor3 = On and Library.Colors.OnAccent() or Library.Scheme.FontColor,
                    BackgroundTransparency = Toggle.Disabled and 0.7 or (On and 0 or 0.5),
                })
            else
                local CheckScale = Check:FindFirstChildOfClass("UIScale")
                Tween(CheckScale, Library.Animations.Groupbox and not Instant and Library.SpringTweenInfo or TweenInfo.new(0), { Scale = On and 1 or 0 })
                Check.ImageTransparency = Toggle.Disabled and 0.5 or 0
            end
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:RunChanged()
            if Toggle.Disabled then
                return
            end
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetValue(Value)
            Toggle.Value = Value == true
            Toggle:Display()
            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end
            if not Toggle.Disabled then
                Library:UpdateDependencyBoxes()
            end
            if not Toggle.AnyKeyPickerPicking then
                Toggle:RunChanged()
            end
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled
            Row.Active = not Disabled
            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Disabled
            end
            for _, Addon in Toggle.Addons do
                if Addon.Update then
                    Addon:Update()
                end
            end
            Toggle:Display()
            Library:UpdateDependencyBoxes()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible
            Row.Visible = Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        function Toggle:SetRisky(Risky: boolean)
            Toggle.Risky = Risky
            ApplyLabelColor()
        end

        table.insert(Toggle.Connections, Row.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end
            Toggle:SetValue(not Toggle.Value)
        end))
        table.insert(Toggle.Connections, Row.MouseEnter:Connect(function()
            if not Toggle.Disabled and not Toggle.Value then
                Tween(Label, Library.TweenInfo, { TextTransparency = 0.15 })
                Tween(IndicatorStroke, Library.TweenInfo, { Color = Library.Colors.Muted() })
            end
        end))
        table.insert(Toggle.Connections, Row.MouseLeave:Connect(function()
            Tween(IndicatorStroke, Library.TweenInfo, { Color = Library.Scheme.OutlineColor })
            if not Toggle.Disabled and not Toggle.Value then
                Tween(Label, Library.TweenInfo, { TextTransparency = 0.4 })
            end
        end))

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Row)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        ApplyLabelColor()
        Toggle:Display(true)
        RegisterElement(Groupbox, Toggle, Row)

        function Toggle:Destroy()
            Toggle.Destroyed = true
            for _, Connection in Toggle.Connections do
                Connection:Disconnect()
            end
            if Toggle.TooltipTable then
                Toggle.TooltipTable:Destroy()
            end
            for Index = #Toggle.Addons, 1, -1 do
                local Addon = table.remove(Toggle.Addons, Index)
                if Addon and Addon.Destroy then
                    Addon:Destroy()
                end
            end
            Row:Destroy()
            RemoveElement(Groupbox, Toggle)
            Toggles[Idx] = nil
        end

        Toggle.Default = Toggle.Value
        Toggles[Idx] = Toggle
        return setmetatable(Toggle, BaseAddons)
    end

    function Funcs:AddCheckbox(Idx, Info)
        if self.Destroyed then
            return nil
        end
        Info = Library:Validate(Info, Templates.Toggle)
        return BuildToggle(self, Idx, Info, "Checkbox")
    end

    function Funcs:AddToggle(Idx, Info)
        if self.Destroyed then
            return nil
        end
        if Library.ForceCheckbox then
            return Funcs.AddCheckbox(self, Idx, Info)
        end
        Info = Library:Validate(Info, Templates.Toggle)
        return BuildToggle(self, Idx, Info, "Switch")
    end

    --// Input \\--
    function Funcs:AddInput(Idx, Info)
        if self.Destroyed then
            return nil
        end
        if typeof(Info) == "table" and typeof(Info.VerifyValue) == "function" and Info.Finished ~= true then
            Info.Finished = true
        end
        Info = Library:Validate(Info, Templates.Input)

        local Groupbox = self
        local Input = {
            Connections = {},
            Destroyed = false,
            Text = Info.Text,
            Value = Info.Default,
            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            ClearTextOnBlur = Info.ClearTextOnBlur,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,
            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            Callback = Info.Callback,
            Changed = Info.Changed,
            VerifyValue = Info.VerifyValue,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Type = "Input",
        }

        local HasLabel = Input.Text ~= nil and Input.Text ~= ""
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, HasLabel and 50 or 30),
            Visible = Input.Visible,
            Parent = Groupbox.Container,
        })
        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Text = Input.Text or "",
            TextSize = 14,
            TextTransparency = 0.1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = HasLabel,
            Parent = Holder,
        })
        local BoxFrame = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 30),
            Parent = Holder,
        })
        ScaledCorner(BoxFrame, 0.75)
        local BoxStroke = Stroke(BoxFrame)

        local Box = New("TextBox", {
            BackgroundTransparency = 1,
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            ClipsDescendants = true,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = BoxFrame,
        })
        Input.TextLabel = Label
        Input.Box = Box

        function Input:UpdateColors()
            Label.TextTransparency = Input.Disabled and 0.7 or 0.1
            Box.TextTransparency = Input.Disabled and 0.6 or 0
            BoxFrame.BackgroundTransparency = Input.Disabled and 0.5 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:RunChanged()
            if Input.Disabled then
                return
            end
            Library:SafeCallback(Input.Callback, Input.Value)
            Library:SafeCallback(Input.Changed, Input.Value)
        end

        function Input:SetValue(Text)
            Text = tostring(Text or "")
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end
            if Input.Numeric and #Text > 0 and not tonumber(Text) then
                Text = Input.Value
            end
            if typeof(Info.VerifyValue) == "function" and Text ~= Input.EmptyReset and Info.VerifyValue(Text) ~= true then
                Text = Input.EmptyReset
            end
            Input.Value = Text
            Box.Text = Text
            Input:RunChanged()
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled
            Box.ClearTextOnFocus = not Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Disabled
            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Disabled
            end
            Input:UpdateColors()
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible
            Holder.Visible = Visible
            Groupbox:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        function Input:SetPlaceholder(Text: string)
            Input.Placeholder = Text
            Box.PlaceholderText = Text
        end

        if Input.Finished then
            table.insert(Input.Connections, Box.FocusLost:Connect(function(Enter)
                if not Enter then
                    if Input.ClearTextOnBlur then
                        Box.Text = Input.Value
                    end
                    return
                end
                Input:SetValue(Box.Text)
            end))
        else
            table.insert(Input.Connections, Box:GetPropertyChangedSignal("Text"):Connect(function()
                if Box.Text == Input.Value then
                    return
                end
                Input:SetValue(Box.Text)
            end))
        end

        table.insert(Input.Connections, Box.Focused:Connect(function()
            if Input.Disabled then
                Box:ReleaseFocus()
                return
            end
            Library.Registry[BoxStroke].Color = "AccentColor"
            Tween(BoxStroke, Library.TweenInfo, { Color = Library.Scheme.AccentColor })
        end))
        table.insert(Input.Connections, Box.FocusLost:Connect(function()
            Library.Registry[BoxStroke].Color = "OutlineColor"
            Tween(BoxStroke, Library.TweenInfo, { Color = Library.Scheme.OutlineColor })
        end))
        HoverTween(BoxFrame, "BackgroundColor3", function()
            return Library.Scheme.BackgroundColor
        end, Library.Colors.Recessed)

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Input:UpdateColors()
        RegisterElement(Groupbox, Input, Holder)
        Input.Default = Input.Value
        Options[Idx] = Input

        function Input:Destroy()
            Input.Destroyed = true
            for _, Connection in Input.Connections do
                Connection:Disconnect()
            end
            if Input.TooltipTable then
                Input.TooltipTable:Destroy()
            end
            Holder:Destroy()
            RemoveElement(Groupbox, Input)
            Options[Idx] = nil
        end

        return Input
    end

    --// Slider \\--
    function Funcs:AddSlider(Idx, Info)
        if self.Destroyed then
            return nil
        end
        Info = Library:Validate(Info, Templates.Slider)
        assert(Info.Max > Info.Min, "Slider Max must be greater than Min.")

        local Groupbox = self
        local Slider = {
            Connections = {},
            Destroyed = false,
            Text = Info.Text,
            Value = Info.Default,
            Min = Info.Min,
            Max = Info.Max,
            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,
            HideMax = Info.HideMax,
            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            Callback = Info.Callback,
            Changed = Info.Changed,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            AllowRightClickInput = Info.AllowRightClickInput,
            Type = "Slider",
        }

        local Compact = Info.Compact == true
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Compact and 22 or 38),
            Visible = Slider.Visible,
            Parent = Groupbox.Container,
        })

        local Label, ValueLabel
        if not Compact then
            Label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 0, 16),
                Text = Slider.Text,
                TextSize = 14,
                TextTransparency = 0.1,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            ValueLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                FontFace = MediumFont,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0.4, 0, 0, 16),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = Holder,
            })
        end

        local Bar = New("TextButton", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, Compact and 22 or 8),
            Text = "",
            Parent = Holder,
        })
        Corner(Bar, Compact and math.max(4, Library.CornerRadius - 2) or 4)
        Stroke(Bar)

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            BackgroundTransparency = Compact and 0.35 or 0,
            Size = UDim2.fromScale(0, 1),
            Parent = Bar,
        })
        Corner(Fill, Compact and math.max(4, Library.CornerRadius - 2) or 4)
        New("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(130, 130, 130), Color3.new(1, 1, 1)),
            Parent = Fill,
        })

        local Knob
        if not Compact then
            Knob = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "WhiteColor",
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(12, 12),
                ZIndex = 2,
                Parent = Bar,
            })
            Corner(Knob, 6)
            New("UIStroke", { Color = "AccentColor", Thickness = 2, Parent = Knob })
        else
            ValueLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = MediumFont,
                Size = UDim2.fromScale(1, 1),
                TextSize = 13,
                ZIndex = 2,
                Parent = Bar,
            })
        end
        Slider.TextLabel = Label or ValueLabel

        local function FormatNumber(N)
            if Slider.Rounding == 0 then
                return tostring(math.floor(N + 0.5))
            end
            return string.format("%." .. Slider.Rounding .. "f", N)
        end

        function Slider:UpdateColors()
            local Disabled = Slider.Disabled
            if Label then
                Label.TextTransparency = Disabled and 0.7 or 0.1
            end
            ValueLabel.TextTransparency = Disabled and 0.7 or 0
            Fill.BackgroundTransparency = Disabled and 0.7 or (Compact and 0.35 or 0)
            if Knob then
                Knob.Visible = not Disabled
            end
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end
            local Custom = Info.FormatDisplayValue and Info.FormatDisplayValue(Slider, Slider.Value)
            local ValueText = Slider.Prefix .. FormatNumber(Slider.Value) .. Slider.Suffix
            if Custom then
                ValueLabel.Text = tostring(Custom)
            elseif Compact then
                ValueLabel.Text = string.format("%s: %s", Slider.Text, ValueText)
            elseif Slider.HideMax then
                ValueLabel.Text = ValueText
            else
                ValueLabel.Text = string.format(
                    '%s<font transparency="0.55"> / %s%s%s</font>',
                    ValueText,
                    Slider.Prefix,
                    FormatNumber(Slider.Max),
                    Slider.Suffix
                )
            end

            local X = math.clamp((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
            Fill.Size = UDim2.fromScale(X, 1)
            if Knob then
                Knob.Position = UDim2.fromScale(X, 0.5)
            end
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")
            Slider.Max = Value
            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value))
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")
            Slider.Min = Value
            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max))
            Slider:Display()
        end

        function Slider:RunChanged()
            if Slider.Disabled then
                return
            end
            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetValue(Str)
            local Num = tonumber(Str)
            if not Num then
                return
            end
            Num = math.clamp(Round(Num, Slider.Rounding), Slider.Min, Slider.Max)
            if Num == Slider.Value then
                Slider:Display()
                return
            end
            Slider.Value = Num
            Slider:Display()
            Slider:RunChanged()
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled
            Bar.Active = not Disabled
            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Disabled
            end
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible
            Holder.Visible = Visible
            Groupbox:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if Label then
                Label.Text = Text
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        local Dragging = false
        local function ValueFromMouse()
            local Mouse = GetMouseAbs()
            local Scale_ = math.clamp((Mouse.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            return Slider.Min + (Slider.Max - Slider.Min) * Scale_
        end

        table.insert(Slider.Connections, Bar.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) or Slider.Disabled then
                return
            end
            for _, Side in Library.ActiveTab and Library.ActiveTab.Sides or {} do
                Side.ScrollingEnabled = false
            end
            Dragging = true
            if Knob then
                Tween(Knob, Library.TweenInfo, { Size = UDim2.fromOffset(15, 15) })
            end

            local Before = Slider.Value
            while Dragging and not Library.Unloaded do
                local Raw = ValueFromMouse()
                local Rounded = math.clamp(Round(Raw, Slider.Rounding), Slider.Min, Slider.Max)
                if Rounded ~= Slider.Value then
                    Slider.Value = Rounded
                    Slider:Display()
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end
                if not (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or (Input.UserInputType == Enum.UserInputType.Touch and Input.UserInputState ~= Enum.UserInputState.End)) then
                    break
                end
                RunService.RenderStepped:Wait()
            end
            Dragging = false
            if Knob then
                Tween(Knob, Library.TweenInfo, { Size = UDim2.fromOffset(12, 12) })
            end
            for _, Side in Library.ActiveTab and Library.ActiveTab.Sides or {} do
                Side.ScrollingEnabled = true
            end
            local _ = Before
        end))

        -- Right click: type an exact value
        local TypeBox
        if Slider.AllowRightClickInput then
            table.insert(Slider.Connections, Bar.MouseButton2Click:Connect(function()
                if Slider.Disabled or TypeBox then
                    return
                end
                TypeBox = New("TextBox", {
                    BackgroundColor3 = "BackgroundColor",
                    FontFace = MonoFont,
                    Position = Compact and UDim2.fromScale(0, 0) or UDim2.new(0.6, 0, 0, -1),
                    Size = Compact and UDim2.fromScale(1, 1) or UDim2.new(0.4, 0, 0, 18),
                    Text = FormatNumber(Slider.Value),
                    TextSize = 12,
                    TextXAlignment = Compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Right,
                    ZIndex = 5,
                    Parent = Compact and Bar or Holder,
                })
                Corner(TypeBox, 4)
                Stroke(TypeBox, "AccentColor")
                Padding(TypeBox, 0, 6, 0, 6)
                TypeBox:CaptureFocus()
                TypeBox.FocusLost:Connect(function()
                    local Number = tonumber(TypeBox.Text)
                    TypeBox:Destroy()
                    TypeBox = nil
                    if Number then
                        Slider:SetValue(Number)
                    end
                end)
            end))
        end

        Bar.MouseEnter:Connect(function()
            if Knob and not Slider.Disabled and not Dragging then
                Tween(Knob, Library.TweenInfo, { Size = UDim2.fromOffset(14, 14) })
            end
        end)
        Bar.MouseLeave:Connect(function()
            if Knob and not Dragging then
                Tween(Knob, Library.TweenInfo, { Size = UDim2.fromOffset(12, 12) })
            end
        end)

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider.Value = math.clamp(Round(tonumber(Slider.Value) or Slider.Min, Slider.Rounding), Slider.Min, Slider.Max)
        Slider:UpdateColors()
        Slider:Display()
        RegisterElement(Groupbox, Slider, Holder)
        Slider.Default = Slider.Value
        Options[Idx] = Slider

        function Slider:Destroy()
            Slider.Destroyed = true
            for _, Connection in Slider.Connections do
                Connection:Disconnect()
            end
            if Slider.TooltipTable then
                Slider.TooltipTable:Destroy()
            end
            Holder:Destroy()
            RemoveElement(Groupbox, Slider)
            Options[Idx] = nil
        end

        return Slider
    end

    --// Dropdown \\--
    function Funcs:AddDropdown(Idx, Info)
        if self.Destroyed then
            return nil
        end
        Info = Library:Validate(Info, Templates.Dropdown)

        local Groupbox = self
        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end

        local Dropdown = {
            Connections = {},
            Destroyed = false,
            Text = typeof(Info.Text) == "string" and Info.Text or nil,
            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            ValueImages = Info.ValueImages,
            Multi = Info.Multi,
            AllowNull = Info.AllowNull,
            Searchable = Info.Searchable,
            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,
            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            Callback = Info.Callback,
            Changed = Info.Changed,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Type = "Dropdown",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Dropdown.Text and 50 or 30),
            Visible = Dropdown.Visible,
            Parent = Groupbox.Container,
        })
        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Text = Dropdown.Text or "",
            TextSize = 14,
            TextTransparency = 0.1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = Dropdown.Text ~= nil,
            Parent = Holder,
        })
        local Display = New("TextButton", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 30),
            Text = "",
            Parent = Holder,
        })
        ScaledCorner(Display, 0.75)
        local DisplayStroke = Stroke(Display)

        local DisplayImage = IconLabel({
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            Visible = false,
            Parent = Display,
        }, nil)
        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -36, 1, 0),
            Text = "---",
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Display,
        })
        local Arrow = IconLabel({
            AnchorPoint = Vector2.new(1, 0.5),
            ImageTransparency = 0.4,
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            Parent = Display,
        }, "chevron-down")
        Dropdown.TextLabel = Label
        Dropdown.DisplayFrame = Display

        --// List popup \\--
        local Popup = CreatePopup(Display, { MatchWidth = true })
        local ListFrame = Popup.Frame
        ListFrame.ClipsDescendants = true

        local SearchBox
        if Info.Searchable then
            local SearchHolder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 32),
                Parent = ListFrame,
            })
            IconLabel({
                AnchorPoint = Vector2.new(0, 0.5),
                ImageTransparency = 0.5,
                Position = UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                Parent = SearchHolder,
            }, "search")
            SearchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -38, 1, 0),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SearchHolder,
            })
            New("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = "OutlineColor",
                Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1),
                Parent = SearchHolder,
            })
        end
        local SearchHeight = SearchBox and 32 or 0

        local Scroller = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0, 0),
            Position = UDim2.fromOffset(0, SearchHeight),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = 3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Size = UDim2.new(1, 0, 1, -SearchHeight),
            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
            Parent = ListFrame,
        })
        List(Scroller, 2)
        Padding(Scroller, 4)

        local EmptyLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            Text = "No results",
            TextSize = 13,
            TextTransparency = 0.55,
            Visible = false,
            LayoutOrder = 999999,
            Parent = Scroller,
        })

        Popup.OnClose = function()
            Tween(Arrow, Library.TweenInfo, { Rotation = 0 })
            Library.Registry[DisplayStroke].Color = "OutlineColor"
            DisplayStroke.Color = Library.Scheme.OutlineColor
        end

        local function IsDictionary()
            return not IsSequentialArray(Dropdown.Values)
        end

        local function ValueExists(Value)
            if Value == nil then
                return false
            end
            if IsDictionary() then
                return Dropdown.Values[Value] ~= nil
            end
            return table.find(Dropdown.Values, Value) ~= nil
        end

        local function DisplayTextOf(Key, Raw)
            local Text = tostring(Raw)
            if Info.FormatDisplayValue then
                Text = tostring(Info.FormatDisplayValue(Raw))
            end
            return Text
        end

        local function GetValueImage(Value)
            local Image = Dropdown.ValueImages and Dropdown.ValueImages[Value]
            if Image then
                return Image
            end
            if Info.SpecialType == "Player" and Info.EnablePlayerImages then
                local Player = Players:FindFirstChild(tostring(Value))
                if Player then
                    return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", Player.UserId)
                end
            end
            return nil
        end

        function Dropdown:Display()
            if Library.Unloaded then
                return
            end
            local Parts = {}
            local Image
            local Dict = IsDictionary()
            if Info.Multi then
                for Key, Raw in Dropdown.Values do
                    local Value = Dict and Key or Raw
                    if Dropdown.Value[Value] then
                        Image = Image or GetValueImage(Value)
                        table.insert(Parts, DisplayTextOf(Value, Raw))
                    end
                end
            elseif Dropdown.Value ~= nil then
                local Raw = Dict and Dropdown.Values[Dropdown.Value] or Dropdown.Value
                Image = GetValueImage(Dropdown.Value)
                table.insert(Parts, DisplayTextOf(Dropdown.Value, Raw))
            end

            local Str = table.concat(Parts, ", ")
            DisplayLabel.Text = Str == "" and "---" or Str
            DisplayLabel.TextTransparency = Str == "" and 0.55 or (Dropdown.Disabled and 0.6 or 0)

            if Image and Library:ApplyIcon(DisplayImage, Image) then
                DisplayImage.Visible = true
                DisplayLabel.Position = UDim2.fromOffset(32, 0)
                DisplayLabel.Size = UDim2.new(1, -58, 1, 0)
            else
                DisplayImage.Visible = false
                DisplayLabel.Position = UDim2.fromOffset(10, 0)
                DisplayLabel.Size = UDim2.new(1, -36, 1, 0)
            end
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end

        function Dropdown:GetActiveValues(ReturnCount)
            local Table = {}
            if Info.Multi then
                for Value in Dropdown.Value do
                    table.insert(Table, Value)
                end
            elseif Dropdown.Value ~= nil then
                table.insert(Table, Dropdown.Value)
            end
            return ReturnCount == true and #Table or Table
        end

        function Dropdown:RunChanged()
            if Dropdown.Disabled then
                return
            end
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end

        local Rows = {}
        local RowHeight = 28

        function Dropdown:RecalculateListSize(Count)
            local Visible = Count or 0
            if not Count then
                for _, Row in Rows do
                    if Row.Frame.Visible then
                        Visible += 1
                    end
                end
            end
            Visible = math.max(Visible, 1)
            local Shown = math.min(Visible, Info.MaxVisibleDropdownItems)
            local Height = Shown * RowHeight + (Shown - 1) * 2 + 8 + SearchHeight
            Popup:SetSize(UDim2.fromOffset(ListFrame.Size.X.Offset, Height))
        end

        function Dropdown:RefreshPool()
            for _, Row in Rows do
                Row:UpdateButton()
            end
        end

        function Dropdown:UpdateColors()
            Label.TextTransparency = Dropdown.Disabled and 0.7 or 0.1
            Display.BackgroundTransparency = Dropdown.Disabled and 0.5 or 0
            Arrow.ImageTransparency = Dropdown.Disabled and 0.8 or 0.4
            Dropdown:Display()
        end

        function Dropdown:BuildDropdownList()
            for _, Row in Rows do
                Row.Frame:Destroy()
            end
            table.clear(Rows)

            local Dict = IsDictionary()
            local Query = SearchBox and SearchBox.Text:lower() or ""
            local Entries = {}
            for Key, Raw in Dropdown.Values do
                table.insert(Entries, { Value = Dict and Key or Raw, Raw = Raw })
            end
            if Dict then
                table.sort(Entries, function(A, B)
                    return tostring(A.Raw) < tostring(B.Raw)
                end)
            end

            local Count = 0
            for Order, Entry in Entries do
                local Value, Raw = Entry.Value, Entry.Raw
                local Text = DisplayTextOf(Value, Raw)
                local Matches = Query == "" or Text:lower():find(Query, 1, true) ~= nil
                local IsDisabled = table.find(Dropdown.DisabledValues, Value) ~= nil

                local Row = {}
                local Frame = New("TextButton", {
                    BackgroundColor3 = "AccentColor",
                    BackgroundTransparency = 1,
                    LayoutOrder = IsDisabled and not Info.KeepDisabledValuePosition and 100000 + Order or Order,
                    Size = UDim2.new(1, 0, 0, RowHeight),
                    Text = "",
                    Visible = Matches,
                    Parent = Scroller,
                })
                Corner(Frame, 4)

                local Image = GetValueImage(Value)
                local RowImage
                if Image then
                    RowImage = IconLabel({
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 8, 0.5, 0),
                        Size = UDim2.fromOffset(16, 16),
                        Parent = Frame,
                    }, Image)
                end
                local RowLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(Image and 30 or 10, 0),
                    Size = UDim2.new(1, Image and -56 or -36, 1, 0),
                    Text = Text,
                    TextSize = 14,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Frame,
                })
                local CheckIcon = IconLabel({
                    AnchorPoint = Vector2.new(1, 0.5),
                    ImageColor3 = "AccentColor",
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    Visible = false,
                    Parent = Frame,
                }, "check")

                local Hovering = false
                function Row:IsSelected()
                    if Info.Multi then
                        return Dropdown.Value[Value] == true
                    end
                    return Dropdown.Value == Value
                end
                function Row:UpdateButton()
                    local Selected = Row:IsSelected()
                    CheckIcon.Visible = Selected
                    Library.Registry[RowLabel].TextColor3 = Selected and "AccentColor" or "FontColor"
                    RowLabel.TextColor3 = Selected and Library.Scheme.AccentColor or Library.Scheme.FontColor
                    RowLabel.TextTransparency = IsDisabled and 0.75 or ((Selected or Hovering) and 0 or 0.35)
                    if RowImage then
                        RowImage.ImageTransparency = IsDisabled and 0.75 or 0
                    end
                    Frame.BackgroundTransparency = Selected and 0.88 or (Hovering and not IsDisabled and 0.94 or 1)
                end

                Frame.MouseEnter:Connect(function()
                    Hovering = true
                    Row:UpdateButton()
                end)
                Frame.MouseLeave:Connect(function()
                    Hovering = false
                    Row:UpdateButton()
                end)
                Frame.MouseButton1Click:Connect(function()
                    if IsDisabled or Dropdown.Disabled then
                        return
                    end
                    if Info.Multi then
                        if Dropdown.Value[Value] then
                            Dropdown.Value[Value] = nil
                        else
                            Dropdown.Value[Value] = true
                        end
                    else
                        if Dropdown.Value == Value then
                            if Info.AllowNull then
                                Dropdown.Value = nil
                            end
                        else
                            Dropdown.Value = Value
                        end
                        Popup:Close()
                    end
                    Dropdown:Display()
                    for _, Other in Rows do
                        Other:UpdateButton()
                    end
                    Library:UpdateDependencyBoxes()
                    Dropdown:RunChanged()
                end)

                Row.Frame = Frame
                Row:UpdateButton()
                table.insert(Rows, Row)
                if Matches then
                    Count += 1
                end
            end

            EmptyLabel.Visible = Count == 0
            Dropdown:RecalculateListSize(Count)
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                if typeof(Value) == "string" then
                    Value = Value == "" and {} or { [Value] = true }
                end
                local Table = {}
                for Key, Active in Value or {} do
                    if typeof(Active) ~= "boolean" then
                        if ValueExists(Active) then
                            Table[Active] = true
                        end
                    elseif Active and ValueExists(Key) then
                        Table[Key] = true
                    end
                end
                Dropdown.Value = Table
            else
                if ValueExists(Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end
            Dropdown:Display()
            Dropdown:RefreshPool()
            if not Dropdown.Disabled then
                Library:UpdateDependencyBoxes()
            end
            Dropdown:RunChanged()
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values or {}
            local Changed = false
            if Info.Multi then
                for Value in table.clone(Dropdown.Value) do
                    if not ValueExists(Value) then
                        Dropdown.Value[Value] = nil
                        Changed = true
                    end
                end
            elseif Dropdown.Value ~= nil and not ValueExists(Dropdown.Value) then
                Dropdown.Value = nil
                Changed = true
            end
            Dropdown:BuildDropdownList()
            Dropdown:Display()
            if Changed then
                if not Dropdown.Disabled then
                    Library:UpdateDependencyBoxes()
                end
                Dropdown:RunChanged()
            end
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) == "string" then
                Values = { Values }
            elseif typeof(Values) ~= "table" then
                return
            end
            local NewValues = table.clone(Dropdown.Values)
            for _, Value in Values do
                if not table.find(NewValues, Value) then
                    table.insert(NewValues, Value)
                end
            end
            Dropdown:SetValues(NewValues)
        end

        function Dropdown:SetDisabledValues(DisabledValues)
            Dropdown.DisabledValues = DisabledValues or {}
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "string" then
                DisabledValues = { DisabledValues }
            end
            for _, Value in DisabledValues or {} do
                table.insert(Dropdown.DisabledValues, Value)
            end
            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetValueImages(ValueImages)
            Dropdown.ValueImages = ValueImages or {}
            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end

        function Dropdown:AddValueImages(ValueImages)
            for Key, Image in ValueImages or {} do
                Dropdown.ValueImages[Key] = Image
            end
            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end

        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled
            Display.Active = not Disabled
            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Disabled
            end
            if Disabled then
                Popup:Close()
            end
            Dropdown:UpdateColors()
        end

        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible
            Holder.Visible = Visible
            Groupbox:Resize()
        end

        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text
            Label.Text = Text or ""
            Label.Visible = Text ~= nil
            Holder.Size = UDim2.new(1, 0, 0, Text and 50 or 30)
        end

        function Dropdown:SetDragSelect() end

        function Dropdown:OpenDropdown()
            Popup:Open()
        end
        function Dropdown:CloseDropdown()
            Popup:Close()
        end

        table.insert(Dropdown.Connections, Display.MouseButton1Click:Connect(function()
            if Dropdown.Disabled then
                return
            end
            Popup:Toggle()
            if Popup.Active then
                Tween(Arrow, Library.TweenInfo, { Rotation = 180 })
                Library.Registry[DisplayStroke].Color = "AccentColor"
                DisplayStroke.Color = Library.Scheme.AccentColor
                if SearchBox then
                    SearchBox.Text = ""
                    task.defer(function()
                        SearchBox:CaptureFocus()
                    end)
                end
                Dropdown:RecalculateListSize()
            end
        end))
        HoverTween(Display, "BackgroundColor3", function()
            return Library.Scheme.BackgroundColor
        end, Library.Colors.Recessed, function()
            return not Dropdown.Disabled
        end)

        if SearchBox then
            table.insert(Dropdown.Connections, SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local Query = SearchBox.Text:lower()
                local Count = 0
                for _, Row in Rows do
                    local Text = Row.Frame:FindFirstChildOfClass("TextLabel").Text:lower()
                    local Match = Query == "" or Text:find(Query, 1, true) ~= nil
                    Row.Frame.Visible = Match
                    if Match then
                        Count += 1
                    end
                end
                EmptyLabel.Visible = Count == 0
                Dropdown:RecalculateListSize(Count)
            end))
        end

        --// Defaults \\--
        local Defaults = {}
        do
            local Default = Info.Default
            local Dict = IsDictionary()
            local function ResolveOne(Candidate)
                if Dict then
                    return Dropdown.Values[Candidate] ~= nil and Candidate or nil
                end
                return table.find(Dropdown.Values, Candidate) and Candidate or nil
            end
            if typeof(Default) == "string" then
                local Value = ResolveOne(Default)
                if Value ~= nil then
                    table.insert(Defaults, Value)
                end
            elseif typeof(Default) == "table" then
                for _, Candidate in Default do
                    local Value = ResolveOne(Candidate)
                    if Value ~= nil then
                        table.insert(Defaults, Value)
                    end
                end
            elseif Default ~= nil and Dropdown.Values[Default] ~= nil then
                table.insert(Defaults, Dict and Default or Dropdown.Values[Default])
            end
        end
        for _, Value in Defaults do
            if Info.Multi then
                Dropdown.Value[Value] = true
            else
                Dropdown.Value = Value
                break
            end
        end

        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, Display)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        Dropdown:BuildDropdownList()
        Dropdown:UpdateColors()
        RegisterElement(Groupbox, Dropdown, Holder)

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values
        Options[Idx] = Dropdown

        function Dropdown:Destroy()
            Dropdown.Destroyed = true
            for _, Connection in Dropdown.Connections do
                Connection:Disconnect()
            end
            if Dropdown.TooltipTable then
                Dropdown.TooltipTable:Destroy()
            end
            Popup:Destroy()
            Holder:Destroy()
            RemoveElement(Groupbox, Dropdown)
            Options[Idx] = nil
        end

        return Dropdown
    end

    --// Media / passthrough \\--
    local function MediaFrame(Groupbox, Height, Visible)
        local Holder = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 0, Height),
            Visible = Visible,
            Parent = Groupbox.Container,
        })
        ScaledCorner(Holder, 0.75)
        Stroke(Holder)
        return Holder
    end

    local function MediaCommon(Object, Groupbox, Holder, Idx)
        function Object:SetHeight(Height: number)
            Object.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end
        function Object:SetVisible(Visible: boolean)
            Object.Visible = Visible
            Holder.Visible = Visible
            Groupbox:Resize()
        end
        local Extra = Object.Destroy
        function Object:Destroy()
            Object.Destroyed = true
            if Extra then
                Extra(Object)
            end
            Holder:Destroy()
            RemoveElement(Groupbox, Object)
            Options[Idx] = nil
        end
        RegisterElement(Groupbox, Object, Holder)
        Options[Idx] = Object
    end

    function Funcs:AddImage(Idx, Info)
        if self.Destroyed then
            return nil
        end
        Info = Library:Validate(Info, Templates.Image)
        local Groupbox = self
        local Holder = MediaFrame(Groupbox, Info.Height, Info.Visible)
        Holder.BackgroundTransparency = Info.BackgroundTransparency

        local Image = { Type = "Image", Height = Info.Height, Visible = Info.Visible, Destroyed = false }
        local ImageLabel = New("ImageLabel", {
            ImageColor3 = Info.Color,
            ImageTransparency = Info.Transparency,
            ScaleType = Info.ScaleType,
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })
        ScaledCorner(ImageLabel, 0.75)
        Image.ImageLabel = ImageLabel

        function Image:SetImage(NewImage: string)
            local Icon = Library:GetCustomIcon(NewImage)
            if Icon then
                ImageLabel.Image = Icon.Url
                ImageLabel.ImageRectOffset = Icon.ImageRectOffset or Vector2.zero
                ImageLabel.ImageRectSize = Icon.ImageRectSize or Vector2.zero
            else
                ImageLabel.Image = tostring(NewImage)
            end
            if Info.RectSize ~= Vector2.zero then
                ImageLabel.ImageRectOffset = Info.RectOffset
                ImageLabel.ImageRectSize = Info.RectSize
            end
        end
        function Image:SetColor(Color: Color3)
            ImageLabel.ImageColor3 = Color
        end
        function Image:SetRectOffset(Offset: Vector2)
            ImageLabel.ImageRectOffset = Offset
        end
        function Image:SetRectSize(Size: Vector2)
            ImageLabel.ImageRectSize = Size
        end
        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            ImageLabel.ScaleType = ScaleType
        end
        function Image:SetTransparency(Transparency: number)
            ImageLabel.ImageTransparency = Transparency
        end

        Image:SetImage(Info.Image)
        MediaCommon(Image, Groupbox, Holder, Idx)
        return Image
    end

    function Funcs:AddVideo(Idx, Info)
        if self.Destroyed then
            return nil
        end
        Info = Library:Validate(Info, Templates.Video)
        local Groupbox = self
        local Holder = MediaFrame(Groupbox, Info.Height, Info.Visible)

        local VideoFrame = New("VideoFrame", {
            BackgroundTransparency = 1,
            Looped = Info.Looped,
            Size = UDim2.fromScale(1, 1),
            Video = Info.Video,
            Volume = Info.Volume,
            Parent = Holder,
        })
        local Video = { Type = "Video", Height = Info.Height, Visible = Info.Visible, Destroyed = false, VideoFrame = VideoFrame }
        function Video:SetVideo(NewVideo: string)
            VideoFrame.Video = NewVideo
        end
        function Video:SetLooped(Looped: boolean)
            VideoFrame.Looped = Looped
        end
        function Video:SetVolume(Volume: number)
            VideoFrame.Volume = Volume
        end
        function Video:SetPlaying(Playing: boolean)
            VideoFrame.Playing = Playing
        end
        function Video:Play()
            VideoFrame.Playing = true
        end
        function Video:Pause()
            VideoFrame.Playing = false
        end
        VideoFrame.Playing = Info.Playing
        MediaCommon(Video, Groupbox, Holder, Idx)
        return Video
    end

    function Funcs:AddUIPassthrough(Idx, Info)
        if self.Destroyed then
            return nil
        end
        Info = Library:Validate(Info, Templates.UIPassthrough)
        local Groupbox = self
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Info.Visible,
            Parent = Groupbox.Container,
        })
        local Passthrough = { Type = "UIPassthrough", Height = Info.Height, Visible = Info.Visible, Destroyed = false }
        function Passthrough:SetInstance(Object: Instance)
            if Passthrough.Instance and Passthrough.Instance.Parent == Holder then
                Passthrough.Instance.Parent = nil
            end
            Passthrough.Instance = Object
            if Object then
                Object.Parent = Holder
            end
        end
        Passthrough:SetInstance(Info.Instance)
        MediaCommon(Passthrough, Groupbox, Holder, Idx)
        return Passthrough
    end

    function Funcs:AddViewport(Idx, Info)
        if self.Destroyed then
            return nil
        end
        Info = Library:Validate(Info, Templates.Viewport)
        local Groupbox = self
        local Holder = MediaFrame(Groupbox, Info.Height, Info.Visible)

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })
        local Camera = Info.Camera or Instance.new("Camera")
        Camera.Parent = ViewportFrame
        ViewportFrame.CurrentCamera = Camera

        local Viewport = {
            Type = "Viewport",
            Height = Info.Height,
            Visible = Info.Visible,
            Destroyed = false,
            Interactive = Info.Interactive,
            Object = nil,
            Camera = Camera,
            ViewportFrame = ViewportFrame,
        }

        local Yaw, Pitch, Distance = math.pi, -0.15, 10
        local Focus = Vector3.zero
        local function UpdateCamera()
            local Rotation = CFrame.Angles(0, Yaw, 0) * CFrame.Angles(Pitch, 0, 0)
            Camera.CFrame = CFrame.new(Focus) * Rotation * CFrame.new(0, 0, Distance)
        end

        function Viewport:Focus()
            local Object = Viewport.Object
            if not Object then
                return
            end
            local CF, Size
            if Object:IsA("Model") then
                CF, Size = Object:GetBoundingBox()
            elseif Object:IsA("BasePart") then
                CF, Size = Object.CFrame, Object.Size
            else
                return
            end
            Focus = CF.Position
            -- face the model's front
            local Look = (Object:IsA("Model") and Object:GetPivot() or CF).LookVector
            Yaw = math.atan2(Look.X, Look.Z)
            Distance = Size.Magnitude * 1.1 / math.tan(math.rad(Camera.FieldOfView / 2)) / 2 + 1
            UpdateCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            if Viewport.Object then
                Viewport.Object:Destroy()
            end
            if Object then
                if Clone ~= false and Info.Clone ~= false then
                    local Archivable = Object.Archivable
                    Object.Archivable = true
                    Object = Object:Clone()
                    Object.Archivable = Archivable
                end
                Object.Parent = ViewportFrame
            end
            Viewport.Object = Object
            if Info.AutoFocus then
                Viewport:Focus()
            end
        end

        function Viewport:SetCamera(NewCamera: Camera)
            Camera = NewCamera
            Viewport.Camera = NewCamera
            NewCamera.Parent = ViewportFrame
            ViewportFrame.CurrentCamera = NewCamera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
        end

        local Dragging = false
        local Last
        Holder.InputBegan:Connect(function(Input)
            if Viewport.Interactive and IsClickInput(Input) then
                Dragging = true
                Last = Input.Position
            end
        end)
        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input)
            if Dragging and IsHoverInput(Input) then
                local Delta = Input.Position - Last
                Last = Input.Position
                Yaw -= Delta.X * 0.01
                Pitch = math.clamp(Pitch - Delta.Y * 0.01, -1.4, 1.4)
                UpdateCamera()
            elseif Viewport.Interactive and Input.UserInputType == Enum.UserInputType.MouseWheel and Library:MouseIsOverFrame(Holder, GetMouseAbs()) then
                Distance = math.max(1, Distance * (1 - Input.Position.Z * 0.1))
                UpdateCamera()
            end
        end))
        Library:GiveSignal(UserInputService.InputEnded:Connect(function(Input)
            if IsMouseInput(Input) then
                Dragging = false
            end
        end))

        Viewport:SetObject(Info.Object, Info.Clone)
        MediaCommon(Viewport, Groupbox, Holder, Idx)
        return Viewport
    end

    --// Dependency boxes \\--
    local function EvaluateDependencies(Dependencies)
        for _, Dependency in Dependencies do
            local Element, Expected = Dependency[1], Dependency[2]
            if Element.Disabled then
                return false
            end
            if Element.Type == "Toggle" and Element.Value ~= Expected then
                return false
            elseif Element.Type == "Dropdown" then
                if typeof(Element.Value) == "table" then
                    if not Element.Value[Expected] then
                        return false
                    end
                elseif Element.Value ~= Expected then
                    return false
                end
            end
        end
        return true
    end

    function Funcs:AddDependencyBox()
        if self.Destroyed then
            return nil
        end
        local Groupbox = self
        local Container = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = Groupbox.Container,
        })
        List(Container, 8)

        local Depbox = {
            Connections = {},
            Destroyed = false,
            Visible = false,
            Dependencies = {},
            Holder = Container,
            Container = Container,
            Elements = {},
            DependencyBoxes = {},
            Tab = Groupbox.Tab,
            IsDepbox = true,
            Parent = Groupbox,
        }

        function Depbox:Resize()
            Groupbox:Resize()
        end

        function Depbox:Update()
            local Visible = EvaluateDependencies(Depbox.Dependencies)
            Depbox.Visible = Visible
            Container.Visible = Visible
            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end
            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        function Depbox:Destroy()
            Depbox.Destroyed = true
            for _, Element in table.clone(Depbox.Elements) do
                if Element.Destroy then
                    Element:Destroy()
                end
            end
            Container:Destroy()
            local Index = table.find(Library.DependencyBoxes, Depbox)
            if Index then
                table.remove(Library.DependencyBoxes, Index)
            end
            Index = table.find(Groupbox.DependencyBoxes, Depbox)
            if Index then
                table.remove(Groupbox.DependencyBoxes, Index)
            end
        end

        setmetatable(Depbox, BaseGroupbox)
        table.insert(Groupbox.DependencyBoxes, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)
        return Depbox
    end

    function Funcs:AddDependencyGroupbox()
        if self.Destroyed then
            return nil
        end
        local Groupbox = self
        local Tab = Groupbox.Tab
        assert(Tab and Tab.AddGroupbox, "AddDependencyGroupbox must be called on a groupbox inside a tab.")

        local DepGroupbox = Tab:AddGroupbox({
            Side = Groupbox.Side or 1,
            Name = "",
            HideHeader = true,
            DisableCollapsing = true,
            After = Groupbox,
        })
        DepGroupbox.Dependencies = {}
        DepGroupbox.IsDepbox = true
        DepGroupbox:SetVisible(false)

        function DepGroupbox:Update()
            local Visible = EvaluateDependencies(DepGroupbox.Dependencies)
            DepGroupbox.Visible = Visible
            DepGroupbox.BoxHolder.Visible = Visible
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        local OldDestroy = DepGroupbox.Destroy
        function DepGroupbox:Destroy()
            local Index = table.find(Library.DependencyBoxes, DepGroupbox)
            if Index then
                table.remove(Library.DependencyBoxes, Index)
            end
            OldDestroy(DepGroupbox)
        end

        table.insert(Library.DependencyBoxes, DepGroupbox)
        return DepGroupbox
    end

    BaseGroupbox.__index = Funcs
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in Library.DependencyBoxes do
        if Depbox.Update then
            Depbox:Update(true)
        end
    end
end

function Library:UpdateAddons() end


--// Search \\--
local function ElementMatches(Element, Query)
    local Text = Element.Text
    if typeof(Text) ~= "string" then
        return false
    end
    Text = Text:gsub("<[^>]->", ""):lower()
    if Text:find(Query, 1, true) then
        return true
    end
    if Element.Type == "Dropdown" then
        for Key, Value in Element.Values do
            if tostring(Value):lower():find(Query, 1, true) then
                return true
            end
        end
    end
    return false
end

local function SearchGroupbox(Groupbox, Query)
    local GroupMatches = typeof(Groupbox.Name) == "string" and Groupbox.Name ~= "" and Groupbox.Name:lower():find(Query, 1, true) ~= nil
    local Any = false

    local function Walk(Box)
        for _, Element in Box.Elements do
            if not Element.Holder then
                continue
            end
            local Visible = Element.Visible ~= false
            if Query == "" or GroupMatches then
                Element.Holder.Visible = Visible
                Any = Any or Visible
            else
                local Match = Visible and ElementMatches(Element, Query)
                Element.Holder.Visible = Match
                Any = Any or Match
            end
        end
        for _, Depbox in Box.DependencyBoxes or {} do
            Walk(Depbox)
        end
    end
    Walk(Groupbox)
    return Any or GroupMatches
end

function Library:UpdateSearch(SearchText: string)
    Library.SearchText = SearchText or ""
    local Query = Trim(Library.SearchText):lower()
    Library.Searching = Query ~= ""

    for _, Tab in Library.Tabs do
        if Tab.IsKeyTab then
            continue
        end
        for _, Groupbox in Tab.GroupboxList or {} do
            local Show = SearchGroupbox(Groupbox, Query)
            local Base = Groupbox.Visible ~= false
            if Query == "" then
                Groupbox.BoxHolder.Visible = Base
            else
                Groupbox.BoxHolder.Visible = Base and Show
            end
        end
        for _, Tabbox in Tab.TabboxList or {} do
            local AnyTab = false
            for _, SubTab in Tabbox.Tabs do
                local Show = SearchGroupbox(SubTab, Query)
                SubTab.SearchHit = Show
                AnyTab = AnyTab or Show
            end
            Tabbox.BoxHolder.Visible = Query == "" or AnyTab
            if Query ~= "" and Tabbox.ActiveTab and not Tabbox.ActiveTab.SearchHit then
                for _, SubTab in Tabbox.Tabs do
                    if SubTab.SearchHit then
                        SubTab:Show()
                        break
                    end
                end
            end
        end
    end
end

--// Window \\--
function Library:CreateWindow(WindowInfo)
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)

    local Camera = workspace.CurrentCamera
    local ViewportSize: Vector2 = Camera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5
    end

    local MaxX, MaxY = ViewportSize.X - 64, ViewportSize.Y - 64
    Library.MinSize = Vector2.new(math.min(math.max(WindowInfo.MinContainerWidth + WindowInfo.SidebarWidth, Library.OriginalMinSize.X), MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, math.max(MaxX, Library.MinSize.X)),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, math.max(MaxY, Library.MinSize.Y))
    )
    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
    end
    if WindowInfo.Compact ~= nil then
        WindowInfo.SidebarCompacted = WindowInfo.Compact
    end

    Library.CornerRadius = math.clamp(WindowInfo.CornerRadius, 0, 20)
    Library:SetNotifySide(WindowInfo.NotifySide)
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    Library.ToggleKeybind = WindowInfo.ToggleKeybind
    Library.GlobalSearch = WindowInfo.GlobalSearch
    for Key, Value in WindowInfo.Animations do
        Library.Animations[Key] = Value
    end
    if WindowInfo.BackgroundImage ~= "" then
        Library.Scheme.BackgroundImage = WindowInfo.BackgroundImage
    end
    SetAlwaysOnTop(ScreenGui, WindowInfo.AlwaysOnTop)

    local SidebarWidth = WindowInfo.SidebarWidth
    local Compacted = false
    local TopHeight = 48
    local FooterHeight = 26

    local Window = {
        Tabs = Library.Tabs,
        Info = WindowInfo,
    }

    --// Shell \\--
    local Holder = New("Frame", {
        AnchorPoint = WindowInfo.Center and Vector2.new(0.5, 0.5) or Vector2.zero,
        BackgroundTransparency = 1,
        Position = WindowInfo.Center and UDim2.fromScale(0.5, 0.5) or WindowInfo.Position,
        Size = WindowInfo.Size,
        Visible = false,
        Parent = WindowLayer,
    })
    local WindowScale = Scale(Holder)

    -- convert a centred anchor into an absolute offset so dragging behaves
    task.defer(function()
        if WindowInfo.Center then
            local Abs = Holder.AbsolutePosition
            Holder.AnchorPoint = Vector2.zero
            Holder.Position = UDim2.fromOffset(
                math.floor((ViewportSize.X - WindowInfo.Size.X.Offset * Library.DPIScale) / 2),
                math.floor((ViewportSize.Y - WindowInfo.Size.Y.Offset * Library.DPIScale) / 2)
            )
            local _ = Abs
        end
    end)

    local Shadow = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = Assets.Shadow,
        ImageColor3 = "DarkColor",
        ImageTransparency = 0.45,
        Position = UDim2.fromScale(0.5, 0.5),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 60, 1, 60),
        ZIndex = 0,
        Parent = Holder,
    })

    local Main = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1,
        Parent = Holder,
    })
    ScaledCorner(Main, 1)
    Stroke(Main)
    Window.Main = Main

    local BackgroundImage = New("ImageLabel", {
        Image = Library.Scheme.BackgroundImage or "",
        ImageTransparency = 0.85,
        ScaleType = Enum.ScaleType.Crop,
        Size = UDim2.fromScale(1, 1),
        Parent = Main,
    })
    ScaledCorner(BackgroundImage, 1)

    -- Linoria accent strip (soft-faded at the corners)
    local AccentStrip = New("Frame", {
        BackgroundColor3 = "AccentColor",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 3,
        Parent = Main,
    })
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0.55),
            NumberSequenceKeypoint.new(0.5, 0.35),
            NumberSequenceKeypoint.new(0.7, 0.55),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = AccentStrip,
    })

    --// Top bar \\--
    local TopBar = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, TopHeight),
        ZIndex = 2,
        Parent = Main,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = TopBar,
    })

    local TitleRow = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -260, 1, 0),
        ClipsDescendants = true,
        Parent = TopBar,
    })
    List(TitleRow, 10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)

    -- Logo: solid accent tile with the icon knocked out in white (custom images fill the tile)
    local LogoTile = New("Frame", {
        BackgroundColor3 = "AccentColor",
        LayoutOrder = 0,
        Size = UDim2.fromOffset(26, 26),
        Visible = false,
        Parent = TitleRow,
    })
    Corner(LogoTile, 7)
    local WindowIcon = IconLabel({
        AnchorPoint = Vector2.new(0.5, 0.5),
        ImageColor3 = Library.Colors.OnAccent,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(15, 15),
        Parent = LogoTile,
    }, nil)
    if WindowInfo.Icon then
        local Icon = Library:GetCustomIcon(WindowInfo.Icon)
        if Icon then
            LogoTile.Visible = true
            Library:ApplyIcon(WindowIcon, WindowInfo.Icon)
            if Icon.Custom or tonumber(WindowInfo.Icon) then
                WindowIcon.ImageColor3 = Color3.new(1, 1, 1)
                WindowIcon.Size = UDim2.fromScale(1, 1)
                Library.Registry[WindowIcon] = nil
                LogoTile.BackgroundTransparency = 1
            end
        end
    end

    local TitleLabel = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        FontFace = BoldFont,
        LayoutOrder = 1,
        Size = UDim2.new(0, 0, 1, 0),
        Text = WindowInfo.Title,
        TextSize = 17,
        Parent = TitleRow,
    })
    Library.Watermark:SetTitle(WindowInfo.Title)
    if WindowInfo.Icon and not tonumber(WindowInfo.Icon) then
        Library.Watermark:SetIcon(WindowInfo.Icon)
    end

    local TitleDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        LayoutOrder = 2,
        Size = UDim2.fromOffset(1, 18),
        Visible = false,
        Parent = TitleRow,
    })
    local TabInfoHolder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Size = UDim2.new(0, 0, 1, 0),
        Visible = false,
        Parent = TitleRow,
    })
    List(TabInfoHolder, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local TabInfoName = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        FontFace = MediumFont,
        Size = UDim2.new(0, 0, 1, 0),
        Text = "",
        TextSize = 14,
        Parent = TabInfoHolder,
    })
    local TabInfoDescription = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Size = UDim2.new(0, 0, 1, 0),
        Text = "",
        TextSize = 13,
        TextTransparency = 0.5,
        Parent = TabInfoHolder,
    })

    -- Search
    local SearchFrame = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = "MainColor",
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(220, 30),
        Parent = TopBar,
    })
    ScaledCorner(SearchFrame, 0.75)
    local SearchStroke = Stroke(SearchFrame)
    IconLabel({
        AnchorPoint = Vector2.new(0, 0.5),
        ImageTransparency = 0.5,
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(15, 15),
        Parent = SearchFrame,
    }, "search")
    local SearchBox = New("TextBox", {
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        PlaceholderText = WindowInfo.GlobalSearch and "Search everything..." or "Search...",
        Position = UDim2.fromOffset(32, 0),
        Size = UDim2.new(1, -60, 1, 0),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = SearchFrame,
    })
    local SearchClear = New("ImageButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        ImageColor3 = "FontColor",
        ImageTransparency = 0.5,
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Visible = false,
        Parent = SearchFrame,
    })
    Library:ApplyIcon(SearchClear, "x")

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        SearchClear.Visible = SearchBox.Text ~= ""
        Library:UpdateSearch(SearchBox.Text)
    end)
    SearchBox.Focused:Connect(function()
        Library.Registry[SearchStroke].Color = "AccentColor"
        Tween(SearchStroke, Library.TweenInfo, { Color = Library.Scheme.AccentColor })
    end)
    SearchBox.FocusLost:Connect(function()
        Library.Registry[SearchStroke].Color = "OutlineColor"
        Tween(SearchStroke, Library.TweenInfo, { Color = Library.Scheme.OutlineColor })
    end)
    SearchClear.MouseButton1Click:Connect(function()
        SearchBox.Text = ""
    end)

    --// Footer \\--
    local Footer = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, FooterHeight),
        ZIndex = 2,
        Parent = Main,
    })
    New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Footer,
    })
    local FooterLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Text = WindowInfo.Footer,
        TextSize = 12,
        TextTransparency = 0.55,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Footer,
    })

    local ResizeGrip
    if WindowInfo.Resizable then
        ResizeGrip = New("ImageButton", {
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            ImageColor3 = "FontColor",
            ImageTransparency = 0.6,
            Position = UDim2.new(1, -6, 1, -6),
            Size = UDim2.fromOffset(14, 14),
            Parent = Footer,
        })
        Library:ApplyIcon(ResizeGrip, "move-diagonal-2")
        ResizeGrip.Rotation = 0
        HoverTween(ResizeGrip, "ImageTransparency", 0.6, 0.1)
    end

    --// Sidebar \\--
    local Sidebar = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, TopHeight),
        Size = UDim2.new(0, SidebarWidth, 1, -(TopHeight + FooterHeight)),
        ZIndex = 2,
        Parent = Main,
    })
    local SidebarLine = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = Sidebar,
    })
    local TabsList = New("ScrollingFrame", {
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        CanvasSize = UDim2.fromScale(0, 0),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Size = UDim2.new(1, -1, 1, -60),
        Parent = Sidebar,
    })
    List(TabsList, 3)
    Padding(TabsList, 12, 8, 10, 8)

    local NavLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = SemiBoldFont,
        LayoutOrder = -100000,
        Size = UDim2.new(1, 0, 0, 20),
        Text = "NAVIGATION",
        TextSize = 11,
        TextTransparency = 0.6,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TabsList,
    })
    Padding(NavLabel, 0, 0, 4, 10)

    -- Profile card pinned to the bottom of the sidebar
    local Profile = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = "MainColor",
        Position = UDim2.new(0, 8, 1, -8),
        Size = UDim2.new(1, -17, 0, 44),
        Parent = Sidebar,
    })
    ScaledCorner(Profile, 1)
    Stroke(Profile)
    local Player = LocalPlayer or Players.LocalPlayer
    local Avatar = New("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = "BackgroundColor",
        BackgroundTransparency = 0,
        Image = Player and string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", Player.UserId) or "",
        Position = UDim2.new(0, 7, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        Parent = Profile,
    })
    Corner(Avatar, 15)
    New("UIStroke", { Color = "OutlineColor", Thickness = 1, Parent = Avatar })
    local StatusDot = New("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(46, 204, 113),
        Position = UDim2.new(1, 1, 1, 1),
        Size = UDim2.fromOffset(9, 9),
        Parent = Avatar,
    })
    Corner(StatusDot, 5)
    New("UIStroke", { Color = "MainColor", Thickness = 2, Parent = StatusDot })
    local ProfileName = New("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = SemiBoldFont,
        Position = UDim2.fromOffset(45, 7),
        Size = UDim2.new(1, -52, 0, 16),
        Text = Player and Player.DisplayName or "Player",
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Profile,
    })
    local ProfileUser = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(45, 22),
        Size = UDim2.new(1, -52, 0, 14),
        Text = Player and ("@" .. Player.Name) or "",
        TextSize = 12,
        TextTransparency = 0.55,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Profile,
    })
    Window.Profile = Profile

    --// Content \\--
    local Content = New("Frame", {
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(SidebarWidth, TopHeight),
        Size = UDim2.new(1, -SidebarWidth, 1, -(TopHeight + FooterHeight)),
        ZIndex = 2,
        Parent = Main,
    })

    local function ApplySidebarWidth(Width)
        Sidebar.Size = UDim2.new(0, Width, 1, -(TopHeight + FooterHeight))
        Content.Position = UDim2.fromOffset(Width, TopHeight)
        Content.Size = UDim2.new(1, -Width, 1, -(TopHeight + FooterHeight))
    end

    Library:MakeDraggable(Holder, TopBar, false, true)
    if ResizeGrip then
        Library:MakeResizable(Holder, ResizeGrip)
    end

    --// Window API \\--
    function Window:ChangeTitle(Title)
        TitleLabel.Text = tostring(Title)
    end

    function Window:SetFooter(Text: string)
        FooterLabel.Text = tostring(Text)
    end

    function Window:SetBackgroundImage(Image: string)
        Library:SetBackgroundImage(Image)
    end
    Window.BackgroundImageLabel = BackgroundImage

    function Window:SetAlwaysOnTop(Enabled: boolean)
        SetAlwaysOnTop(ScreenGui, Enabled)
    end

    function Window:SetSnapping() end

    function Window:SetCornerRadius(Radius: number)
        Library.CornerRadius = math.clamp(Radius, 0, 20)
        for _, Data in Library.Corners do
            local C, Multiplier = Data[1], Data[2]
            if C.Parent then
                C.CornerRadius = UDim.new(0, math.floor(Library.CornerRadius * Multiplier + 0.5))
            end
        end
    end

    function Window:SetAnimations(Animations, TabTransitionTime)
        for Key, Value in Animations or {} do
            Library.Animations[Key] = Value
        end
    end

    function Window:IsSidebarCompacted()
        return Compacted
    end

    function Window:SetCompact(State: boolean)
        if not WindowInfo.EnableCompacting and State then
            return
        end
        Compacted = State
        ApplySidebarWidth(State and WindowInfo.SidebarCompactWidth or SidebarWidth)
        NavLabel.Visible = not State
        ProfileName.Visible = not State
        ProfileUser.Visible = not State
        Profile.BackgroundTransparency = State and 1 or 0
        Profile:FindFirstChildOfClass("UIStroke").Enabled = not State
        for _, Tab in Library.Tabs do
            if Tab.SetCompact then
                Tab:SetCompact(State)
            end
        end
    end

    function Window:GetSidebarWidth()
        return Compacted and WindowInfo.SidebarCompactWidth or SidebarWidth
    end

    function Window:SetSidebarWidth(Width: number)
        SidebarWidth = math.max(WindowInfo.MinSidebarWidth, Width)
        if not Compacted then
            ApplySidebarWidth(SidebarWidth)
        end
    end

    function Window:ShowTabInfo(Name, Description)
        TabInfoName.Text = Name or ""
        TabInfoDescription.Text = Description or ""
        TabInfoDescription.Visible = Description ~= nil and Description ~= ""
        TitleDivider.Visible = true
        TabInfoHolder.Visible = true
    end

    function Window:HideTabInfo()
        TitleDivider.Visible = false
        TabInfoHolder.Visible = false
    end

    --// Tabs \\--
    local TabOrderCounter = 0

    local function CreateTabButton(Name, Icon, Order)
        local Button = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 1,
            LayoutOrder = Order,
            Size = UDim2.new(1, 0, 0, 34),
            Text = "",
            Parent = TabsList,
        })
        ScaledCorner(Button, 0.75)

        -- active state: neutral raised surface; only the icon + indicator use the accent
        local Highlight = New("Frame", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Button,
        })
        ScaledCorner(Highlight, 0.75)
        local HighlightStroke = New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = "OutlineColor",
            Transparency = 1,
            Parent = Highlight,
        })

        local Indicator = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = "AccentColor",
            Position = UDim2.new(0, -8, 0.5, 0),
            Size = UDim2.fromOffset(3, 0),
            Parent = Button,
        })
        Corner(Indicator, 2)
        Highlight.Name = "Highlight"
        HighlightStroke.Name = "HighlightStroke"

        local IconImage, HasIcon = IconLabel({
            AnchorPoint = Vector2.new(0, 0.5),
            ImageTransparency = 0.5,
            Position = UDim2.new(0, 11, 0.5, 0),
            Size = UDim2.fromOffset(17, 17),
            Parent = Button,
        }, Icon)
        IconImage.Visible = HasIcon

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = MediumFont,
            Position = UDim2.fromOffset(HasIcon and 38 or 12, 0),
            Size = UDim2.new(1, HasIcon and -44 or -18, 1, 0),
            Text = Name,
            TextSize = 14,
            TextTransparency = 0.5,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        return Button, Indicator, IconImage, Label, HasIcon
    end

    local function BuildTabCore(Tab, Name, Icon, Description, Order, IsKeyTab)
        local Button, Indicator, IconImage, Label, HasIcon = CreateTabButton(Name, Icon, Order)
        Tab.Button = Button

        local Container = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            Parent = Content,
        })
        Tab.Container = Container

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end
            Tween(Button, Library.TweenInfo, { BackgroundTransparency = Hovering and 0.5 or 1 })
            Tween(Label, Library.TweenInfo, { TextTransparency = Hovering and 0.2 or 0.5 })
            Tween(IconImage, Library.TweenInfo, { ImageTransparency = Hovering and 0.2 or 0.5 })
        end

        function Tab:SetCompact(State)
            Label.Visible = not State
            IconImage.Position = State and UDim2.new(0.5, -8, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)
        end

        local Highlight = Button:FindFirstChild("Highlight")
        local HighlightStroke = Highlight:FindFirstChild("HighlightStroke")

        local function SetActiveVisual(Active)
            Library.Registry[IconImage].ImageColor3 = Active and "AccentColor" or "FontColor"
            Tween(Button, Library.TweenInfo, { BackgroundTransparency = 1 })
            Tween(Highlight, Library.SlowTweenInfo, { BackgroundTransparency = Active and 0 or 1 })
            Tween(HighlightStroke, Library.SlowTweenInfo, { Transparency = Active and 0 or 1 })
            Tween(Label, Library.TweenInfo, { TextTransparency = Active and 0 or 0.5 })
            Tween(IconImage, Library.TweenInfo, {
                ImageTransparency = Active and 0 or 0.5,
                ImageColor3 = Active and Library.Scheme.AccentColor or Library.Scheme.FontColor,
            })
            Tween(Indicator, Library.SpringTweenInfo, { Size = UDim2.fromOffset(3, Active and 16 or 0) })
        end

        function Tab:Show()
            if Library.ActiveTab == Tab then
                return
            end
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end
            Library.PreviousTab = Library.ActiveTab
            Library.ActiveTab = Tab
            SetActiveVisual(true)
            Container.Visible = true

            if Description and Description ~= "" then
                Window:ShowTabInfo(Name, Description)
            else
                Window:ShowTabInfo(Name, nil)
            end

            if Library.Animations.TabSwitch and Tab.AnimatedFrame then
                local Frame = Tab.AnimatedFrame
                local Target = Tab.AnimatedTarget or UDim2.fromOffset(0, 0)
                Frame.Position = Target + UDim2.fromOffset(0, 10)
                Tween(Frame, Library.SlowTweenInfo, { Position = Target })
            end

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            SetActiveVisual(false)
            Container.Visible = false
            if Library.ActiveTab == Tab then
                Library.ActiveTab = nil
            end
        end

        function Tab:SetVisible(Visible: boolean)
            Tab.Visible = Visible
            Button.Visible = Visible
            if not Visible and Library.ActiveTab == Tab then
                for _, Other in Library.Tabs do
                    if Other ~= Tab and Other.Visible ~= false then
                        Other:Show()
                        break
                    end
                end
            end
        end

        function Tab:SetOrder(NewOrder: number)
            Button.LayoutOrder = NewOrder
        end

        function Tab:SetTooltip(Text: string?)
            if Tab.TooltipTable then
                Tab.TooltipTable:Destroy()
                Tab.TooltipTable = nil
            end
            if Text then
                Tab.TooltipTable = Library:AddTooltip(Text, nil, Button)
            end
        end

        function Tab:SetName(NewName)
            Label.Text = NewName
        end

        Button.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        Button.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        Button.MouseButton1Click:Connect(function()
            Tab:Show()
        end)

        if Compacted then
            Tab:SetCompact(true)
        end
        return Container
    end

    local function ParseTabArgs(...)
        local Name, Icon, Description, Tooltip, Order
        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name, Icon, Description, Tooltip, Order = Info.Name or "Tab", Info.Icon, Info.Description, Info.Tooltip, Info.Order
        else
            Name, Icon, Description, Order = select(1, ...), select(2, ...), select(3, ...), select(4, ...)
        end
        Name = Name or "Tab"
        if not tonumber(Order) then
            TabOrderCounter += 1
            Order = TabOrderCounter
        end
        return Name, Icon, Description, Tooltip, Order
    end

    function Window:AddTab(...)
        local Name, Icon, Description, Tooltip, Order = ParseTabArgs(...)

        local Tab = {
            Name = Name,
            Groupboxes = {},
            Tabboxes = {},
            GroupboxList = {},
            TabboxList = {},
            DependencyGroupboxes = {},
            Sides = {},
            Visible = true,
            Destroyed = false,
        }

        local Container = BuildTabCore(Tab, Name, Icon, Description, Order, false)

        -- Warning box
        local WarningBox = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "RedColor",
            BackgroundTransparency = 0.88,
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.new(1, -24, 0, 0),
            Visible = false,
            Parent = Container,
        })
        ScaledCorner(WarningBox, 0.75)
        local WarningStroke = Stroke(WarningBox, "RedColor", 0.5)
        Padding(WarningBox, 10, 12, 10, 12)
        List(WarningBox, 4)
        local WarningTitleRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Parent = WarningBox,
        })
        local WarningIcon = IconLabel({
            ImageColor3 = "RedColor",
            Size = UDim2.fromOffset(16, 16),
            Parent = WarningTitleRow,
        }, "triangle-alert")
        local WarningTitle = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = SemiBoldFont,
            Position = UDim2.fromOffset(24, 0),
            Size = UDim2.new(1, -24, 1, 0),
            Text = "",
            TextColor3 = "RedColor",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = WarningTitleRow,
        })
        local WarningText = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Text = "",
            TextSize = 13,
            TextTransparency = 0.15,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = WarningBox,
        })

        local Columns = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Container,
        })
        Tab.AnimatedFrame = Columns

        local function MakeSide(Index)
            local Side = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = Index == 1 and UDim2.fromOffset(0, 0) or UDim2.fromScale(0.5, 0),
                ScrollBarImageColor3 = "OutlineColor",
                ScrollBarThickness = 2,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(0.5, 0, 1, 0),
                VerticalScrollBarInset = Enum.ScrollBarInset.None,
                Parent = Columns,
            })
            List(Side, 10)
            Padding(Side, 12, Index == 1 and 6 or 12, 12, Index == 1 and 12 or 6)
            return Side
        end
        local Left, Right = MakeSide(1), MakeSide(2)
        Tab.Sides = { Left, Right }

        local function Relayout()
            local Offset = WarningBox.Visible and (WarningBox.AbsoluteSize.Y / Library.DPIScale + 12) or 0
            Columns.Size = UDim2.new(1, 0, 1, -Offset)
            Columns.Position = UDim2.fromOffset(0, Offset)
            Tab.AnimatedFrame = Columns
            Tab.AnimatedTarget = Columns.Position
        end
        WarningBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(Relayout)
        WarningBox:GetPropertyChangedSignal("Visible"):Connect(Relayout)

        -- the slide animation tweens Position, so keep the warning offset applied on top

        function Tab:UpdateWarningBox(Info)
            Info = Info or {}
            if typeof(Info.Visible) == "boolean" then
                WarningBox.Visible = Info.Visible
            end
            if Info.Title ~= nil then
                WarningTitle.Text = tostring(Info.Title)
            end
            if Info.Text ~= nil then
                WarningText.Text = tostring(Info.Text)
            end
            local Key = Info.IsNormal and "AccentColor" or "RedColor"
            Library.Registry[WarningBox].BackgroundColor3 = Key
            Library.Registry[WarningStroke].Color = Key
            Library.Registry[WarningTitle].TextColor3 = Key
            Library.Registry[WarningIcon].ImageColor3 = Key
            WarningBox.BackgroundColor3 = Library.Scheme[Key]
            WarningStroke.Color = Library.Scheme[Key]
            WarningTitle.TextColor3 = Library.Scheme[Key]
            WarningIcon.ImageColor3 = Library.Scheme[Key]
            Library:ApplyIcon(WarningIcon, Info.IsNormal and "info" or "triangle-alert")
            Relayout()
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end

        local GroupboxOrder = 0

        --// Groupbox \\--
        function Tab:AddGroupbox(Info)
            Info = Library:Validate(Info, Templates.Groupbox)
            if typeof(Info.Side) == "string" then
                local Lower = Info.Side:lower()
                assert(SideIndex[Lower], "Invalid side: " .. tostring(Info.Side))
                Info.Side = SideIndex[Lower]
            end

            GroupboxOrder += 10
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = Info.After and Info.After.BoxHolder and (Info.After.BoxHolder.LayoutOrder + 1) or GroupboxOrder,
                Size = UDim2.new(1, 0, 0, 0),
                Visible = Info.Visible,
                Parent = Info.Side == 1 and Left or Right,
            })

            local Box = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = "MainColor",
                Size = UDim2.new(1, 0, 0, 0),
                Parent = BoxHolder,
            })
            ScaledCorner(Box, 1)
            Stroke(Box)
            List(Box, 0)

            local Groupbox = {
                Name = Info.Name,
                Side = Info.Side,
                Tab = Tab,
                BoxHolder = BoxHolder,
                Holder = Box,
                Elements = {},
                DependencyBoxes = {},
                Visible = Info.Visible,
                Collapsed = false,
                Destroyed = false,
                PopOutEnabled = false,
                PoppedOut = false,
            }

            local Header, Chevron, DescriptionLabel
            if not Info.HideHeader then
                Header = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 46),
                    Text = "",
                    Parent = Box,
                })

                local HeaderIcon, HasIcon = IconLabel({
                    AnchorPoint = Vector2.new(0, 0.5),
                    ImageColor3 = "AccentColor",
                    Position = UDim2.new(0, 14, 0, 23),
                    Size = UDim2.fromOffset(16, 16),
                    Parent = Header,
                }, Info.IconName)
                HeaderIcon.Visible = HasIcon == true

                local TextX = HasIcon and 40 or 14
                local NameLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    FontFace = SemiBoldFont,
                    Position = UDim2.fromOffset(TextX, 0),
                    Size = UDim2.new(1, -(TextX + 34), 0, 46),
                    Text = Info.Name,
                    TextSize = 15,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Header,
                })
                Groupbox.NameLabel = NameLabel

                DescriptionLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(TextX, 24),
                    Size = UDim2.new(1, -(TextX + 34), 0, 14),
                    Text = "",
                    TextSize = 12,
                    TextTransparency = 0.5,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Visible = false,
                    Parent = Header,
                })

                if not Info.DisableCollapsing then
                    Chevron = IconLabel({
                        AnchorPoint = Vector2.new(1, 0.5),
                        ImageTransparency = 0.55,
                        Position = UDim2.new(1, -14, 0, 23),
                        Size = UDim2.fromOffset(16, 16),
                        Parent = Header,
                    }, "chevron-down")
                end

                New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundColor3 = "OutlineColor",
                    Name = "Line",
                    Position = UDim2.fromScale(0.5, 1),
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = Header,
                })
            end

            local Container = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = Box,
            })
            List(Container, 8)
            Padding(Container, 12, 12, 12, 12)
            Groupbox.Container = Container

            function Groupbox:Resize() end

            function Groupbox:SetDescription(Text: string?)
                if not DescriptionLabel then
                    return
                end
                DescriptionLabel.Text = Text or ""
                DescriptionLabel.Visible = Text ~= nil and Text ~= ""
                local NameLabel = Groupbox.NameLabel
                local Width = NameLabel.Size.X
                if DescriptionLabel.Visible then
                    NameLabel.Position = UDim2.fromOffset(NameLabel.Position.X.Offset, 6)
                    NameLabel.Size = UDim2.new(Width.Scale, Width.Offset, 0, 18)
                else
                    NameLabel.Position = UDim2.fromOffset(NameLabel.Position.X.Offset, 0)
                    NameLabel.Size = UDim2.new(Width.Scale, Width.Offset, 0, 46)
                end
            end

            function Groupbox:SetCollapsed(Collapsed: boolean)
                if Info.DisableCollapsing then
                    return
                end
                Groupbox.Collapsed = Collapsed
                Container.Visible = not Collapsed
                if Header then
                    Header.Line.Visible = not Collapsed
                end
                if Chevron then
                    Tween(Chevron, Library.Animations.Groupbox and Library.SpringTweenInfo or TweenInfo.new(0), { Rotation = Collapsed and -90 or 0 })
                end
            end

            function Groupbox:ToggleCollapsed()
                Groupbox:SetCollapsed(not Groupbox.Collapsed)
            end

            function Groupbox:SetVisible(Visible: boolean)
                Groupbox.Visible = Visible
                BoxHolder.Visible = Visible
            end
            function Groupbox:Show()
                Groupbox:SetVisible(true)
            end
            function Groupbox:Hide()
                Groupbox:SetVisible(false)
            end

            function Groupbox:SetName(Name)
                Groupbox.Name = Name
                if Groupbox.NameLabel then
                    Groupbox.NameLabel.Text = Name
                end
            end

            -- pop-out windows are not part of Onyx; keep the API surface so SaveManager & scripts don't break
            function Groupbox:SetPoppedOut() end
            function Groupbox:TogglePoppedOut() end
            function Groupbox:RefreshPopOutPlaceholder() end
            function Groupbox:SetMaxPopOutHeight() end
            function Groupbox:SetPopOutWidth() end

            function Groupbox:Destroy()
                Groupbox.Destroyed = true
                for _, Element in table.clone(Groupbox.Elements) do
                    if Element.Destroy then
                        Element:Destroy()
                    end
                end
                for _, Depbox in table.clone(Groupbox.DependencyBoxes) do
                    Depbox:Destroy()
                end
                BoxHolder:Destroy()
                if Tab.Groupboxes[Info.Name] == Groupbox then
                    Tab.Groupboxes[Info.Name] = nil
                end
                local Index = table.find(Tab.GroupboxList, Groupbox)
                if Index then
                    table.remove(Tab.GroupboxList, Index)
                end
            end

            if Header and not Info.DisableCollapsing then
                Header.MouseButton1Click:Connect(function()
                    Groupbox:ToggleCollapsed()
                end)
                Header.MouseEnter:Connect(function()
                    Tween(Chevron, Library.TweenInfo, { ImageTransparency = 0.1 })
                end)
                Header.MouseLeave:Connect(function()
                    Tween(Chevron, Library.TweenInfo, { ImageTransparency = 0.55 })
                end)
            end

            if Info.Description then
                Groupbox:SetDescription(Info.Description)
            end
            if Info.Collapsed then
                Groupbox:SetCollapsed(true)
            end

            setmetatable(Groupbox, BaseGroupbox)
            if not Info.HideHeader then
                Tab.Groupboxes[Info.Name] = Groupbox
            end
            table.insert(Tab.GroupboxList, Groupbox)
            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name, IconName, Visible, Collapsed, DisableCollapsing)
            return Tab:AddGroupbox({ Side = 1, Name = Name, IconName = IconName, Visible = Visible, Collapsed = Collapsed, DisableCollapsing = DisableCollapsing })
        end

        function Tab:AddRightGroupbox(Name, IconName, Visible, Collapsed, DisableCollapsing)
            return Tab:AddGroupbox({ Side = 2, Name = Name, IconName = IconName, Visible = Visible, Collapsed = Collapsed, DisableCollapsing = DisableCollapsing })
        end

        --// Tabbox \\--
        function Tab:AddTabbox(Info)
            Info = Library:Validate(Info, Templates.Tabbox)
            if typeof(Info.Side) == "string" then
                Info.Side = SideIndex[Info.Side:lower()] or 1
            end

            GroupboxOrder += 10
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = GroupboxOrder,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = Info.Side == 1 and Left or Right,
            })
            local Box = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = "MainColor",
                Size = UDim2.new(1, 0, 0, 0),
                Parent = BoxHolder,
            })
            ScaledCorner(Box, 1)
            Stroke(Box)
            List(Box, 0)

            -- Header row holds a segmented control; decorations live outside the layout
            local HeaderRow = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 46),
                Parent = Box,
            })
            New("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = "OutlineColor",
                Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1),
                Parent = HeaderRow,
            })
            local ButtonsRow = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(10, 8),
                Size = UDim2.new(1, -20, 0, 30),
                Parent = HeaderRow,
            })
            ScaledCorner(ButtonsRow, 0.75)
            Stroke(ButtonsRow)
            Padding(ButtonsRow, 3)
            List(ButtonsRow, 3, Enum.FillDirection.Horizontal)

            local Tabbox = {
                Name = Info.Name,
                Tabs = {},
                TabList = {},
                ActiveTab = nil,
                BoxHolder = BoxHolder,
                Holder = Box,
                Destroyed = false,
                PopOutEnabled = false,
                PoppedOut = false,
            }

            local function ResizeButtons()
                local Count = math.max(#Tabbox.TabList, 1)
                for _, SubTab in Tabbox.TabList do
                    SubTab.Button.Size = UDim2.new(1 / Count, -3 * (Count - 1) / Count, 1, 0)
                end
            end

            function Tabbox:AddTab(Name, IconName)
                local SubTab = {
                    Name = Name,
                    Elements = {},
                    DependencyBoxes = {},
                    Tab = Tab,
                    Side = Info.Side,
                    Tabbox = Tabbox,
                    Destroyed = false,
                    Visible = true,
                }

                local Button = New("TextButton", {
                    BackgroundColor3 = Library.Colors.Elevated,
                    BackgroundTransparency = 1,
                    LayoutOrder = #Tabbox.TabList + 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ButtonsRow,
                })
                Corner(Button, math.max(Library.CornerRadius - 2, 3))
                local ButtonStroke = New("UIStroke", {
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Color = "OutlineColor",
                    Transparency = 1,
                    Parent = Button,
                })
                local Inner = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.new(0, 0, 1, 0),
                    Parent = Button,
                })
                List(Inner, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
                local IconImage, HasIcon = IconLabel({ Size = UDim2.fromOffset(15, 15), ImageTransparency = 0.5, Parent = Inner }, IconName)
                IconImage.Visible = HasIcon
                local ButtonLabel = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    FontFace = MediumFont,
                    LayoutOrder = 1,
                    Size = UDim2.new(0, 0, 1, 0),
                    Text = Name,
                    TextSize = 14,
                    TextTransparency = 0.5,
                    Parent = Inner,
                })

                local Container = New("Frame", {
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    Parent = Box,
                })
                List(Container, 8)
                Padding(Container, 12, 12, 12, 12)

                SubTab.Button = Button
                SubTab.Container = Container

                function SubTab:Show()
                    if Tabbox.ActiveTab and Tabbox.ActiveTab ~= SubTab then
                        Tabbox.ActiveTab:Hide()
                    end
                    Tabbox.ActiveTab = SubTab
                    Container.Visible = true
                    Library.Registry[IconImage].ImageColor3 = "AccentColor"
                    IconImage.ImageColor3 = Library.Scheme.AccentColor
                    Tween(ButtonLabel, Library.TweenInfo, { TextTransparency = 0 })
                    Tween(IconImage, Library.TweenInfo, { ImageTransparency = 0 })
                    Tween(Button, Library.TweenInfo, { BackgroundTransparency = 0 })
                    Tween(ButtonStroke, Library.TweenInfo, { Transparency = 0 })
                end
                function SubTab:Hide()
                    Container.Visible = false
                    Library.Registry[IconImage].ImageColor3 = "FontColor"
                    IconImage.ImageColor3 = Library.Scheme.FontColor
                    Tween(ButtonLabel, Library.TweenInfo, { TextTransparency = 0.5 })
                    Tween(IconImage, Library.TweenInfo, { ImageTransparency = 0.5 })
                    Tween(Button, Library.TweenInfo, { BackgroundTransparency = 1 })
                    Tween(ButtonStroke, Library.TweenInfo, { Transparency = 1 })
                end
                function SubTab:Resize() end
                function SubTab:UpdateCorners() end
                function SubTab:SetVisible(Visible)
                    SubTab.Visible = Visible
                    Button.Visible = Visible
                end
                function SubTab:Destroy()
                    SubTab.Destroyed = true
                    for _, Element in table.clone(SubTab.Elements) do
                        if Element.Destroy then
                            Element:Destroy()
                        end
                    end
                    Button:Destroy()
                    Container:Destroy()
                    Tabbox.Tabs[Name] = nil
                    local Index = table.find(Tabbox.TabList, SubTab)
                    if Index then
                        table.remove(Tabbox.TabList, Index)
                    end
                    ResizeButtons()
                    if Tabbox.ActiveTab == SubTab then
                        Tabbox.ActiveTab = nil
                        if Tabbox.TabList[1] then
                            Tabbox.TabList[1]:Show()
                        end
                    end
                end

                Button.MouseButton1Click:Connect(function()
                    SubTab:Show()
                end)
                Button.MouseEnter:Connect(function()
                    if Tabbox.ActiveTab ~= SubTab then
                        Tween(ButtonLabel, Library.TweenInfo, { TextTransparency = 0.2 })
                    end
                end)
                Button.MouseLeave:Connect(function()
                    if Tabbox.ActiveTab ~= SubTab then
                        Tween(ButtonLabel, Library.TweenInfo, { TextTransparency = 0.5 })
                    end
                end)

                Tabbox.Tabs[Name] = SubTab
                table.insert(Tabbox.TabList, SubTab)
                ResizeButtons()
                if not Tabbox.ActiveTab then
                    SubTab:Show()
                end
                return setmetatable(SubTab, BaseGroupbox)
            end

            function Tabbox:Resize() end
            function Tabbox:UpdateCorners() end
            function Tabbox:SetPoppedOut() end
            function Tabbox:TogglePoppedOut() end
            function Tabbox:SetVisible(Visible)
                BoxHolder.Visible = Visible
            end
            function Tabbox:Destroy()
                Tabbox.Destroyed = true
                for _, SubTab in table.clone(Tabbox.TabList) do
                    SubTab:Destroy()
                end
                BoxHolder:Destroy()
                if Info.Name and Tab.Tabboxes[Info.Name] == Tabbox then
                    Tab.Tabboxes[Info.Name] = nil
                end
                local Index = table.find(Tab.TabboxList, Tabbox)
                if Index then
                    table.remove(Tab.TabboxList, Index)
                end
            end

            if Info.Name then
                Tab.Tabboxes[Info.Name] = Tabbox
            end
            table.insert(Tab.TabboxList, Tabbox)
            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Side = 1, Name = Name })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Side = 2, Name = Name })
        end

        function Tab:Destroy()
            Tab.Destroyed = true
            for _, Groupbox in table.clone(Tab.GroupboxList) do
                Groupbox:Destroy()
            end
            for _, Tabbox in table.clone(Tab.TabboxList) do
                Tabbox:Destroy()
            end
            if Tab.TooltipTable then
                Tab.TooltipTable:Destroy()
            end
            if Library.ActiveTab == Tab then
                Library.ActiveTab = nil
            end
            Tab.Button:Destroy()
            Container:Destroy()
            Library.Tabs[Name] = nil
        end

        if Tooltip then
            Tab:SetTooltip(Tooltip)
        end

        Library.Tabs[Name] = Tab
        table.insert(Library.TabButtons, Tab.Button)
        if not Library.ActiveTab then
            Tab:Show()
        end
        return Tab
    end

    --// Key tab (single centred column for key systems) \\--
    function Window:AddKeyTab(...)
        local Name, Icon, Description, Tooltip, Order = ParseTabArgs(...)
        Icon = Icon or "key"

        local Tab = {
            Name = Name,
            Elements = {},
            DependencyBoxes = {},
            IsKeyTab = true,
            Visible = true,
            Destroyed = false,
            Groupboxes = {},
            Tabboxes = {},
        }

        local Container = BuildTabCore(Tab, Name, Icon, Description, Order, true)
        local Scroller = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = "OutlineColor",
            Size = UDim2.fromScale(1, 1),
            Parent = Container,
        })
        Tab.AnimatedFrame = Scroller
        local Column = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0.7, 0, 0, 0),
            Parent = Scroller,
        })
        List(Column, 10, nil, Enum.HorizontalAlignment.Center)
        Padding(Column, 28, 0, 20, 0)
        Tab.Container = Column
        Tab.Sides = { Scroller }

        function Tab:Resize() end
        function Tab:RefreshSides() end
        function Tab:UpdateCorners() end

        function Tab:AddKeyBox(Callback)
            assert(typeof(Callback) == "function", "Callback must be a function")
            local Row = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 32),
                Parent = Column,
            })
            local BoxFrame = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.new(1, -96, 1, 0),
                Parent = Row,
            })
            ScaledCorner(BoxFrame, 0.75)
            local BoxStroke = Stroke(BoxFrame)
            IconLabel({
                AnchorPoint = Vector2.new(0, 0.5),
                ImageTransparency = 0.5,
                Position = UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.fromOffset(15, 15),
                Parent = BoxFrame,
            }, "key-round")
            local Box = New("TextBox", {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                PlaceholderText = "Enter key...",
                Position = UDim2.fromOffset(32, 0),
                Size = UDim2.new(1, -42, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = BoxFrame,
            })
            Box.Focused:Connect(function()
                BoxStroke.Color = Library.Scheme.AccentColor
            end)
            Box.FocusLost:Connect(function()
                BoxStroke.Color = Library.Scheme.OutlineColor
            end)

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "AccentColor",
                FontFace = SemiBoldFont,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 88, 1, 0),
                Text = "Submit",
                TextColor3 = Library.Colors.OnAccent,
                TextSize = 14,
                Parent = Row,
            })
            ScaledCorner(Button, 0.75)
            HoverTween(Button, "BackgroundColor3", function()
                return Library.Scheme.AccentColor
            end, Library.Colors.AccentLight)
            Button.MouseButton1Click:Connect(function()
                Library:SafeCallback(Callback, Box.Text)
            end)
            Box.FocusLost:Connect(function(Enter)
                if Enter then
                    Library:SafeCallback(Callback, Box.Text)
                end
            end)
            return Box
        end

        function Tab:Destroy()
            Tab.Destroyed = true
            for _, Element in table.clone(Tab.Elements) do
                if Element.Destroy then
                    Element:Destroy()
                end
            end
            Tab.Button:Destroy()
            Container:Destroy()
            Library.Tabs[Name] = nil
        end

        if Tooltip then
            Tab:SetTooltip(Tooltip)
        end

        setmetatable(Tab, BaseGroupbox)
        Library.Tabs[Name] = Tab
        if not Library.ActiveTab then
            Tab:Show()
        end
        return Tab
    end

    --// Dialogs \\--
    local DialogOverlay = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = "DarkColor",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Visible = false,
        ZIndex = 10,
        Parent = Main,
    })
    ScaledCorner(DialogOverlay, 1)

    local VariantStyles = {
        Primary = { Background = "AccentColor", Text = Library.Colors.OnAccent, Stroke = nil },
        Secondary = { Background = Library.Colors.Elevated, Text = "FontColor", Stroke = "OutlineColor" },
        Outline = { Background = "BackgroundColor", Text = "FontColor", Stroke = "OutlineColor" },
        Ghost = { Background = nil, Text = "FontColor", Stroke = nil },
        Destructive = { Background = "DestructiveColor", Text = "WhiteColor", Stroke = nil },
    }

    function Window:AddDialog(Idx, Info)
        if typeof(Idx) == "table" and Info == nil then
            Info = Idx
            Idx = tostring(os.clock())
        end
        Info = Library:Validate(Info, Templates.Dialog)

        if Library.ActiveDialog then
            Library.ActiveDialog:Dismiss()
        end

        local Dialog = {
            Idx = Idx,
            Elements = {},
            DependencyBoxes = {},
            FooterButtons = {},
            Destroyed = false,
            Tab = nil,
        }

        local Card = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            AutoButtonColor = false,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(380, 0),
            Text = "",
            ZIndex = 11,
            Parent = DialogOverlay,
        })
        ScaledCorner(Card, 1)
        Stroke(Card)
        Padding(Card, 18, 18, 16, 18)
        List(Card, 10)
        local CardScale = New("UIScale", { Scale = 0.95, Parent = Card })

        local Title = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            FontFace = BoldFont,
            Size = UDim2.new(1, 0, 0, 18),
            Text = Info.Title,
            TextSize = 17,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
            Parent = Card,
        })
        local Description = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Text = Info.Description,
            TextSize = 14,
            TextTransparency = 0.4,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
            Parent = Card,
        })
        local Container = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 11,
            Parent = Card,
        })
        List(Container, 8)
        Dialog.Container = Container

        local FooterRow = New("Frame", {
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            Size = UDim2.new(1, 0, 0, 32),
            ZIndex = 11,
            Parent = Card,
        })
        List(FooterRow, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
        Padding(FooterRow, 6, 0, 0, 0)

        function Dialog:Resize() end

        function Dialog:SetTitle(Text)
            Title.Text = Text
        end
        function Dialog:SetDescription(Text)
            Description.Text = Text
        end

        function Dialog:Dismiss()
            if Dialog.Destroyed then
                return
            end
            Dialog.Destroyed = true
            Library.Dialogues[Idx] = nil
            if Library.ActiveDialog == Dialog then
                Library.ActiveDialog = nil
            end
            Tween(CardScale, Library.TweenInfo, { Scale = 0.95 })
            Tween(DialogOverlay, Library.TweenInfo, { BackgroundTransparency = 1 })
            task.delay(Library.TweenInfo.Time, function()
                Card:Destroy()
                if not Library.ActiveDialog then
                    DialogOverlay.Visible = false
                end
            end)
        end
        Dialog.Destroy = Dialog.Dismiss

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            ButtonInfo = ButtonInfo or {}
            local Style = VariantStyles[ButtonInfo.Variant or "Secondary"] or VariantStyles.Secondary

            local Button = New("TextButton", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Style.Background or "MainColor",
                BackgroundTransparency = Style.Background and 0 or 1,
                FontFace = MediumFont,
                LayoutOrder = ButtonInfo.Order or 0,
                Size = UDim2.fromOffset(0, 30),
                Text = ButtonInfo.Title or ButtonInfo.Text or tostring(ButtonIdx),
                TextColor3 = Style.Text,
                TextSize = 14,
                ZIndex = 11,
                Parent = FooterRow,
            })
            Padding(Button, 0, 14, 0, 14)
            ScaledCorner(Button, 0.75)
            if Style.Stroke then
                Stroke(Button, Style.Stroke)
            end

            local Entry = { Button = Button, Info = ButtonInfo, Disabled = ButtonInfo.Disabled == true }
            local function Refresh()
                Button.TextTransparency = Entry.Disabled and 0.6 or 0
                Button.Active = not Entry.Disabled
            end
            Refresh()

            Button.MouseEnter:Connect(function()
                if Entry.Disabled then
                    return
                end
                if Style.Background then
                    local Base = GetSchemeValue(Style.Background) or (typeof(Style.Background) == "function" and Style.Background())
                    Tween(Button, Library.TweenInfo, { BackgroundColor3 = Library:GetLighterColor(Base) })
                else
                    Tween(Button, Library.TweenInfo, { BackgroundTransparency = 0.6 })
                end
            end)
            Button.MouseLeave:Connect(function()
                if Style.Background then
                    local Base = GetSchemeValue(Style.Background) or (typeof(Style.Background) == "function" and Style.Background())
                    Tween(Button, Library.TweenInfo, { BackgroundColor3 = Base })
                else
                    Tween(Button, Library.TweenInfo, { BackgroundTransparency = 1 })
                end
            end)
            Button.MouseButton1Click:Connect(function()
                if Entry.Disabled or Dialog.Destroyed then
                    return
                end
                Library:SafeCallback(ButtonInfo.Callback, Dialog)
                if Info.AutoDismiss then
                    Dialog:Dismiss()
                end
            end)

            Dialog.FooterButtons[ButtonIdx] = Entry
            return Entry
        end

        function Dialog:RemoveFooterButton(ButtonIdx)
            local Entry = Dialog.FooterButtons[ButtonIdx]
            if Entry then
                Entry.Button:Destroy()
                Dialog.FooterButtons[ButtonIdx] = nil
            end
        end

        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            local Entry = Dialog.FooterButtons[ButtonIdx]
            if Entry then
                Entry.Disabled = Disabled
                Entry.Button.TextTransparency = Disabled and 0.6 or 0
                Entry.Button.Active = not Disabled
            end
        end

        function Dialog:SetButtonOrder(ButtonIdx, Order)
            local Entry = Dialog.FooterButtons[ButtonIdx]
            if Entry then
                Entry.Button.LayoutOrder = Order
            end
        end

        for ButtonIdx, ButtonInfo in Info.FooterButtons do
            Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
        end

        local OverlayClick = DialogOverlay.MouseButton1Click:Connect(function()
            if Info.OutsideClickDismiss and Library.ActiveDialog == Dialog then
                local Mouse = GetMouseAbs()
                if not Library:MouseIsOverFrame(Card, Mouse) then
                    Dialog:Dismiss()
                end
            end
        end)
        Card.Destroying:Connect(function()
            OverlayClick:Disconnect()
        end)

        DialogOverlay.Visible = true
        Tween(DialogOverlay, Library.TweenInfo, { BackgroundTransparency = 0.45 })
        Tween(CardScale, Library.SpringTweenInfo, { Scale = 1 })

        setmetatable(Dialog, BaseGroupbox)
        Library.Dialogues[Idx] = Dialog
        Library.ActiveDialog = Dialog
        return Dialog
    end

    --// Toggle \\--
    local ToggleTween
    function Window:Toggle(Value: boolean?)
        if Library.Unloaded then
            return
        end
        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        local Open = Library.Toggled
        ModalElement.Modal = Open and WindowInfo.UnlockMouseWhileOpen

        if ToggleTween then
            ToggleTween:Cancel()
        end

        if Open then
            Holder.Visible = true
            if Library.Animations.ToggleWindow then
                WindowScale.Scale = Library.DPIScale * 0.96
                ToggleTween = Tween(WindowScale, Library.SlowTweenInfo, { Scale = Library.DPIScale })
            else
                WindowScale.Scale = Library.DPIScale
            end
        else
            for _, Popup in Popups do
                Popup:Close()
            end
            TooltipLabel.Visible = false
            if Library.Animations.ToggleWindow then
                ToggleTween = Tween(WindowScale, Library.TweenInfo, { Scale = Library.DPIScale * 0.96 })
                local Pending = ToggleTween
                Pending.Completed:Connect(function(State)
                    if State == Enum.PlaybackState.Completed and not Library.Toggled then
                        Holder.Visible = false
                        WindowScale.Scale = Library.DPIScale
                    end
                end)
            else
                Holder.Visible = false
            end
        end

        -- custom cursor
        if Open and Library.ShowCustomCursor then
            task.spawn(function()
                local Binding = "OnyxCursor"
                pcall(RunService.UnbindFromRenderStep, RunService, Binding)
                local Ok = pcall(function()
                    RunService:BindToRenderStep(Binding, Enum.RenderPriority.Last.Value, function()
                        if not Library.Toggled or not Library.ShowCustomCursor or Library.Unloaded then
                            Cursor.Visible = false
                            UserInputService.MouseIconEnabled = Library.OriginalMouseIconEnabled
                            pcall(RunService.UnbindFromRenderStep, RunService, Binding)
                            return
                        end
                        UserInputService.MouseIconEnabled = false
                        local Mouse = UserInputService:GetMouseLocation()
                        Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                        Cursor.Visible = true
                    end)
                end)
                if not Ok then
                    Cursor.Visible = false
                end
            end)
        end
    end

    function Library:Toggle(Value: boolean?)
        Window:Toggle(Value)
    end

    --// Mobile toggle button \\--
    if Library.IsMobile and WindowInfo.ShowMobileButtons then
        local MobileButton = Library:AddDraggableButton("Menu", function()
            Library:Toggle()
        end)
        MobileButton.Holder.Position = WindowInfo.MobileButtonsSide == "Right" and UDim2.new(1, -90, 0, 8) or UDim2.fromOffset(8, 8)
        Library.MobileButton = MobileButton
    end

    --// Menu keybind \\--
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject, Processed)
        if Library.Unloaded then
            return
        end
        local Bind = Library.ToggleKeybind
        if typeof(Bind) == "EnumItem" and Input.KeyCode == Bind and not UserInputService:GetFocusedTextBox() then
            task.spawn(Library.Toggle, Library)
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    if WindowInfo.SidebarCompacted then
        Window:SetCompact(true)
    end

    if WindowInfo.AutoShow then
        task.spawn(Library.Toggle, Library, true)
    end

    Window.Holder = Holder
    Window.TabsList = TabsList
    Window.Content = Content
    Library.WindowObject = Window
    Library.Window = Window
    return Window
end


--// Theme setters \\--
function Library:SetFont(FontFace)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace)
    end
    Library.Scheme.Font = FontFace
    Library:UpdateColorsUsingRegistry()
end

function Library:SetBackgroundImage(Image: string | number)
    if tonumber(Image) then
        Image = "rbxassetid://" .. tostring(Image)
    end
    Library.Scheme.BackgroundImage = Image or ""
    local Window = Library.WindowObject
    if Window and Window.BackgroundImageLabel then
        Window.BackgroundImageLabel.Image = Library.Scheme.BackgroundImage
    end
end

function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize = Library.OriginalMinSize * Library.DPIScale
    for _, UIScale in Library.Scales do
        if UIScale.Parent then
            UIScale.Scale = Library.DPIScale
        end
    end
    for _, Option in Options do
        if Option.Type == "Dropdown" and Option.RecalculateListSize then
            Option:RecalculateListSize()
        end
    end
end

--// Notifications \\--
local NotificationArea = New("Frame", {
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -12, 0, 12),
    Size = UDim2.new(0, 300, 1, -24),
    Parent = NotificationLayer,
})
local NotificationList = List(NotificationArea, 8, nil, Enum.HorizontalAlignment.Right)
Scale(NotificationArea)

function Library:UpdateNotificationPositions() end

function Library:SetNotifySide(Side: string)
    Library.NotifySide = Side
    local Left = tostring(Side):lower() == "left"
    NotificationArea.AnchorPoint = Left and Vector2.new(0, 0) or Vector2.new(1, 0)
    NotificationArea.Position = Left and UDim2.fromOffset(12, 12) or UDim2.new(1, -12, 0, 12)
    NotificationList.HorizontalAlignment = Left and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)
    if typeof(Info) == "table" then
        Data.Title = Info.Title and tostring(Info.Title) or nil
        Data.Description = Info.Description and tostring(Info.Description) or ""
        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Steps = Info.Steps
        Data.Persist = Info.Persist
        Data.Callback = typeof(Info.Callback) == "function" and Info.Callback or nil
        Data.Closable = Info.Closable == true
        Data.Icon = Info.Icon
        Data.BigIcon = Info.BigIcon
        Data.IconColor = Info.IconColor
        Data.TitleColor = Info.TitleColor
        Data.DescriptionColor = Info.DescriptionColor
        Data.Volume = tonumber(Info.Volume) or 3
    else
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
        Data.Volume = select(4, ...) or 3
    end
    Data.Destroyed = false
    Data.CurrentStep = 0

    local Left = Library.NotifySide:lower() == "left"

    local Slot = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(300, 0),
        Parent = NotificationArea,
    })
    local Card = New("TextButton", {
        AutoButtonColor = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        ClipsDescendants = true,
        Position = UDim2.fromOffset(Left and -320 or 320, 0),
        Size = UDim2.new(1, 0, 0, 0),
        Text = "",
        Parent = Slot,
    })
    ScaledCorner(Card, 1)
    Stroke(Card)

    -- slim accent pill on the left (Linoria's accent edge)
    local Edge = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Position = UDim2.fromOffset(0, 10),
        Size = UDim2.new(0, 2, 1, -20),
        Parent = Card,
    })
    Corner(Edge, 1)

    local Body = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Card,
    })
    Padding(Body, 12, 12, 14, 14)

    local IconSize = Data.BigIcon and 36 or 30
    local IconTile, IconImage, HasIcon = AccentTile(Body, Data.Icon, IconSize)
    if Data.IconColor then
        Library.Registry[IconImage].ImageColor3 = nil
        IconImage.ImageColor3 = Data.IconColor
    end
    IconTile.Visible = HasIcon == true and Data.Icon ~= nil
    local TextX = IconTile.Visible and IconSize + 11 or 0

    local TextHolder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(TextX, 0),
        Size = UDim2.new(1, -TextX - (Data.Closable and 20 or 0), 0, 0),
        Parent = Body,
    })
    List(TextHolder, 3)

    local TitleLabel = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        FontFace = SemiBoldFont,
        Size = UDim2.new(1, 0, 0, 16),
        Text = Data.Title or "",
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = Data.Title ~= nil and Data.Title ~= "",
        Parent = TextHolder,
    })
    if Data.TitleColor then
        TitleLabel.TextColor3 = Data.TitleColor
        Library.Registry[TitleLabel].TextColor3 = nil
    end
    local DescriptionLabel = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Text = Data.Description,
        TextSize = 13,
        TextTransparency = (Data.Title and Data.Title ~= "") and 0.35 or 0,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = Data.Description ~= "",
        Parent = TextHolder,
    })
    if Data.DescriptionColor then
        DescriptionLabel.TextColor3 = Data.DescriptionColor
        Library.Registry[DescriptionLabel].TextColor3 = nil
    end

    if Data.Closable then
        local Close = New("ImageButton", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            ImageColor3 = "FontColor",
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.fromOffset(14, 14),
            Parent = Body,
        })
        Library:ApplyIcon(Close, "x")
        Close.MouseButton1Click:Connect(function()
            Data:Destroy()
        end)
    end

    local Progress = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = "AccentColor",
        BackgroundTransparency = 0.2,
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = Card,
    })

    function Data:Resize() end
    function Data:ChangeTitle(Text)
        Data.Title = tostring(Text)
        TitleLabel.Text = Data.Title
        TitleLabel.Visible = Data.Title ~= ""
    end
    function Data:ChangeDescription(Text)
        Data.Description = tostring(Text)
        DescriptionLabel.Text = Data.Description
        DescriptionLabel.Visible = Data.Description ~= ""
    end
    function Data:ChangeStep(NewStep)
        if Data.Steps then
            Data.CurrentStep = math.clamp(NewStep or 0, 0, Data.Steps)
            Tween(Progress, Library.TweenInfo, { Size = UDim2.new(Data.CurrentStep / Data.Steps, 0, 0, 2) })
        end
    end
    function Data:Destroy()
        if Data.Destroyed then
            return
        end
        Data.Destroyed = true
        local Index = table.find(Library.Notifications, Data)
        if Index then
            table.remove(Library.Notifications, Index)
        end
        Tween(Card, Library.NotifyTweenInfo, { Position = UDim2.fromOffset(Left and -320 or 320, 0) })
        task.delay(Library.NotifyTweenInfo.Time, function()
            Slot:Destroy()
        end)
    end

    Card.MouseButton1Click:Connect(function()
        if Data.Callback then
            Library:SafeCallback(Data.Callback, Data)
        end
    end)

    if Data.SoundId then
        local Sound = New("Sound", {
            SoundId = tonumber(Data.SoundId) and "rbxassetid://" .. Data.SoundId or tostring(Data.SoundId),
            Volume = Data.Volume,
            PlayOnRemove = true,
            Parent = SoundService,
        })
        Sound:Destroy()
    end

    table.insert(Library.Notifications, Data)
    Tween(Card, Library.NotifyTweenInfo, { Position = UDim2.fromOffset(0, 0) })

    task.spawn(function()
        if typeof(Data.Time) == "Instance" then
            Progress.Visible = false
            repeat
                task.wait(0.1)
            until Data.Destroyed or not Data.Time.Parent
        elseif Data.Steps then
            Data:ChangeStep(0)
            repeat
                task.wait(0.1)
            until Data.Destroyed or (not Data.Persist and Data.CurrentStep >= Data.Steps)
        elseif Data.Persist then
            Progress.Visible = false
            repeat
                task.wait(0.1)
            until Data.Destroyed
        else
            Tween(Progress, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
            task.wait(Data.Time)
        end
        Data:Destroy()
    end)

    return Data
end

--// Loading screen \\--
function Library:CreateLoading(LoadingInfo)
    if Library.ActiveLoading then
        return Library.ActiveLoading
    end
    LoadingInfo = Library:Validate(LoadingInfo, Templates.Loading)

    local Loading = {
        CurrentStep = LoadingInfo.CurrentStep,
        TotalSteps = LoadingInfo.TotalSteps,
        ShowSidebar = LoadingInfo.ShowSidebar,
        IsError = false,
        Destroyed = false,
    }

    local Gui = New("ScreenGui", {
        Name = "OnyxLoading",
        DisplayOrder = LoadingInfo.AlwaysOnTop and 100000 or 1000,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    ParentUI(Gui)

    local Holder = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(LoadingInfo.WindowWidth, 0),
        Parent = Gui,
    })
    ScaledCorner(Holder, 1)
    Stroke(Holder)
    Scale(Holder)
    local Strip = New("Frame", { BackgroundColor3 = "AccentColor", Size = UDim2.new(1, 0, 0, 2), Parent = Holder })
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.1, 0),
            NumberSequenceKeypoint.new(0.9, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = Strip,
    })

    local Inner = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Holder,
    })
    Padding(Inner, 18, 20, 18, 20)
    List(Inner, 12)

    local Header = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Parent = Inner })
    List(Header, 10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local HeaderIcon, HasIcon = IconLabel({ ImageColor3 = "AccentColor", Size = LoadingInfo.IconSize, Parent = Header }, LoadingInfo.Icon)
    HeaderIcon.Visible = HasIcon
    if tonumber(LoadingInfo.Icon) then
        Library.Registry[HeaderIcon] = nil
        HeaderIcon.ImageColor3 = Color3.new(1, 1, 1)
    end
    New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        FontFace = BoldFont,
        LayoutOrder = 1,
        Size = UDim2.new(0, 0, 1, 0),
        Text = LoadingInfo.Title,
        TextSize = 17,
        Parent = Header,
    })

    local Row = New("Frame", { BackgroundTransparency = 1, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 40), Parent = Inner })
    local Spinner = IconLabel({
        AnchorPoint = Vector2.new(0, 0.5),
        ImageColor3 = LoadingInfo.LoadingIconColor or "AccentColor",
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(26, 26),
        Parent = Row,
    }, LoadingInfo.LoadingIcon)
    local MessageLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = SemiBoldFont,
        Position = UDim2.fromOffset(38, 2),
        Size = UDim2.new(1, -38, 0, 18),
        Text = "Loading...",
        TextSize = 15,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })
    local DescriptionLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(38, 21),
        Size = UDim2.new(1, -38, 0, 16),
        Text = "",
        TextSize = 13,
        TextTransparency = 0.45,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })

    local Track = New("Frame", { BackgroundColor3 = "MainColor", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 6), Parent = Inner })
    Corner(Track, 3)
    Stroke(Track)
    local Fill = New("Frame", { BackgroundColor3 = "AccentColor", Size = UDim2.fromScale(0, 1), Parent = Track })
    Corner(Fill, 3)
    local StepLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Size = UDim2.new(1, 0, 0, 14),
        Text = "",
        TextSize = 12,
        TextTransparency = 0.55,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Inner,
    })

    -- Sidebar page: a groupbox-like area scripts can add elements to
    local SidebarBox = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        LayoutOrder = 4,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        Parent = Inner,
    })
    ScaledCorner(SidebarBox, 0.75)
    Stroke(SidebarBox)
    List(SidebarBox, 6)
    Padding(SidebarBox, 10, 12, 10, 12)
    Loading.Sidebar = setmetatable({
        Container = SidebarBox,
        Elements = {},
        DependencyBoxes = {},
        Resize = function() end,
    }, BaseGroupbox)

    -- Error page
    local ErrorBox = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 5,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        Parent = Inner,
    })
    List(ErrorBox, 10)
    local ErrorLabel = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Text = "",
        TextColor3 = "RedColor",
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ErrorBox,
    })
    local ErrorButtons = New("Frame", { BackgroundTransparency = 1, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 30), Parent = ErrorBox })
    List(ErrorButtons, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)

    local Spin = TweenService:Create(Spinner, TweenInfo.new(LoadingInfo.LoadingIconTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
    Spin:Play()

    function Loading:UpdateLayout() end
    function Loading:RecalculateLoadingHeight() end
    function Loading:RecalculateErrorHeight() end
    function Loading:SetMessage(Text)
        MessageLabel.Text = tostring(Text)
    end
    function Loading:SetDescription(Text)
        DescriptionLabel.Text = tostring(Text)
    end
    function Loading:SetLoadingIcon(Icon)
        Library:ApplyIcon(Spinner, Icon)
    end
    function Loading:SetLoadingIconTweenTime(Time)
        Spin:Cancel()
        Spinner.Rotation = 0
        Spin = TweenService:Create(Spinner, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
        Spin:Play()
    end
    function Loading:SetLoadingIconColor(Color)
        Library.Registry[Spinner].ImageColor3 = nil
        Spinner.ImageColor3 = Color
    end
    function Loading:SetCurrentStep(Step)
        Loading.CurrentStep = math.clamp(Step, 0, Loading.TotalSteps)
        Tween(Fill, Library.SlowTweenInfo, { Size = UDim2.fromScale(Loading.TotalSteps > 0 and Loading.CurrentStep / Loading.TotalSteps or 0, 1) })
        StepLabel.Text = string.format("%d / %d", Loading.CurrentStep, Loading.TotalSteps)
    end
    function Loading:SetTotalSteps(Steps)
        Loading.TotalSteps = Steps
        Loading:SetCurrentStep(Loading.CurrentStep)
    end
    function Loading:SetWindowHeight() end
    function Loading:SetWindowWidth(Width)
        Holder.Size = UDim2.fromOffset(Width, 0)
    end
    function Loading:SetContentWidth() end
    function Loading:SetSidebarWidth() end
    function Loading:ShowSidebarPage(Bool)
        Loading.ShowSidebar = Bool
        SidebarBox.Visible = Bool
    end
    function Loading:ShowErrorPage(Enabled)
        Loading.IsError = Enabled
        ErrorBox.Visible = Enabled
        Track.Visible = not Enabled
        StepLabel.Visible = not Enabled
        Spinner.Visible = not Enabled
    end
    function Loading:SetErrorMessage(Text)
        ErrorLabel.Text = tostring(Text)
    end
    function Loading:SetErrorButtons(ButtonsInfo)
        for _, Child in ErrorButtons:GetChildren() do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
        for Index, ButtonInfo in ButtonsInfo or {} do
            local Primary = ButtonInfo.Variant == "Primary" or Index == 1
            local Button = New("TextButton", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Primary and "AccentColor" or "MainColor",
                FontFace = MediumFont,
                LayoutOrder = Index,
                Size = UDim2.fromOffset(0, 30),
                Text = ButtonInfo.Title or ButtonInfo.Text or "Button",
                TextColor3 = Primary and Library.Colors.OnAccent or "FontColor",
                TextSize = 14,
                Parent = ErrorButtons,
            })
            Padding(Button, 0, 14, 0, 14)
            ScaledCorner(Button, 0.75)
            Button.MouseButton1Click:Connect(function()
                if ButtonInfo.Callback then
                    Library:SafeCallback(ButtonInfo.Callback, Loading)
                end
            end)
        end
    end
    function Loading:Destroy()
        if Loading.Destroyed then
            return
        end
        Loading.Destroyed = true
        Spin:Cancel()
        Gui:Destroy()
        Library.ActiveLoading = nil
        if Library.WindowObject and not Library.Toggled and not Library.Unloaded then
            Library:Toggle(true)
        end
    end
    Loading.Continue = Loading.Destroy

    if Library.WindowObject and Library.Toggled then
        Library:Toggle(false)
    end
    Loading:ShowSidebarPage(Loading.ShowSidebar)
    Loading:SetCurrentStep(Loading.CurrentStep)
    Library.ActiveLoading = Loading
    return Loading
end

--// Player / team dropdowns \\--
local function OnPlayerChange()
    if Library.Unloaded then
        return
    end
    local All, Excluded = GetPlayers(), GetPlayers(true)
    for _, Option in Options do
        if Option.Type == "Dropdown" and Option.SpecialType == "Player" then
            Option:SetValues(Option.ExcludeLocalPlayer and Excluded or All)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end
    local TeamList = GetTeams()
    for _, Option in Options do
        if Option.Type == "Dropdown" and Option.SpecialType == "Team" then
            Option:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))
Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

--// Unload \\--
function Library:Unload()
    if Library.Unloaded then
        return
    end
    Library.Unloaded = true

    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    for _ = 1, #Library.UnloadSignals do
        local Callback = table.remove(Library.UnloadSignals, 1)
        if Callback then
            Library:SafeCallback(Callback)
        end
    end

    for _, Option in Options do
        if Option.Type == "KeyPicker" and Option.Destroy then
            pcall(Option.Destroy, Option)
        end
    end
    for _, Tooltip in table.clone(Tooltips) do
        pcall(Tooltip.Destroy, Tooltip)
    end
    if Library.ActiveLoading then
        Library.ActiveLoading:Destroy()
    end

    pcall(RunService.UnbindFromRenderStep, RunService, "OnyxCursor")
    UserInputService.MouseIconEnabled = Library.OriginalMouseIconEnabled
    ModalElement.Modal = false

    ScreenGui:Destroy()
    table.clear(Library.Registry)
    table.clear(Library.Scales)
    Library.Toggle = function() end
    Library.ScreenGui = nil
    Library.KeybindFrame = nil
    getgenv().Library = nil
end

getgenv().Library = Library
getgenv().Toggles = Toggles
getgenv().Options = Options
return Library
