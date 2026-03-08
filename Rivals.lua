local mainapi = {
	Tabs = {},
	Keybind = {'RightShift','RightControl'},
	Font = Enum.Font.BuilderSans,
	Loaded = false,
	Modules = {},
	Catalogs = {},
	Libraries = {},
	Binds = {},
	Place = game.PlaceId,
	ThreadFix = setthreadidentity and true or false,
	Scale = {Value = 1},
	GradientKeypoints = 5,
	TargetHudFrame = Instance.new("Frame"),
	MainScreenGui = Instance.new('ScreenGui'),
	ClickGuiStatus = false
}

local cloneref = cloneref or function(obj) return obj end
local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local TextService = cloneref(game:GetService("TextService"))
local GuiService = cloneref(game:GetService("GuiService"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer

local fontsize = Instance.new("GetTextBoundsParams")
fontsize.Width = math.huge

local function getfontsize(text, size, font)
	fontsize.Text = text
	fontsize.Size = size
	if typeof(font) == "Font" then fontsize.Font = font end
	return TextService:GetTextBoundsAsync(fontsize)
end

local function addMaid(object)
	object.Connections = {}
	function object:Clean(callback)
		if typeof(callback) == "Instance" then
			table.insert(self.Connections, {Disconnect = function() callback:ClearAllChildren() callback:Destroy() end})
		elseif type(callback) == "function" then
			table.insert(self.Connections, {Disconnect = callback})
		else
			table.insert(self.Connections, callback)
		end
	end
end

addMaid(mainapi)

local function makeDraggable(obj, window)
	obj.InputBegan:Connect(function(input)
		if not mainapi.ClickGuiStatus then return end
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and (input.Position.Y - obj.AbsolutePosition.Y < 40 or window) then
			local dragPos = Vector2.new(obj.AbsolutePosition.X - input.Position.X, obj.AbsolutePosition.Y - input.Position.Y + GuiService:GetGuiInset().Y) / mainapi.Scale.Value
			local conn
			conn = UIS.InputChanged:Connect(function(inp)
				if inp.UserInputType == (input.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
					local pos = inp.Position
					if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
						dragPos = (dragPos // 3) * 3
						pos = (pos // 3) * 3
					end
					obj.Position = UDim2.fromOffset((pos.X / mainapi.Scale.Value) + dragPos.X, (pos.Y / mainapi.Scale.Value) + dragPos.Y)
				end
			end)
			local endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if conn then conn:Disconnect() end
					if endConn then endConn:Disconnect() end
				end
			end)
		end
	end)
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0,5)
	c.Parent = parent
	return c
end

local function addBlur(parent)
	local b = Instance.new("ImageLabel")
	b.Name = "Blur"
	b.Size = UDim2.new(1,89,1,52)
	b.Position = UDim2.fromOffset(-48,-31)
	b.BackgroundTransparency = 1
	b.Image = "rbxassetid://74663567791967"
	b.ScaleType = Enum.ScaleType.Slice
	b.SliceCenter = Rect.new(52,31,261,502)
	b.ZIndex = -100
	b.Parent = parent
	return b
end

local uipallet = {
	MainColor = Color3.fromRGB(0,0,0),
	SecondaryColor = Color3.fromRGB(255,255,255)
}

local function getBlendFactor(vec)
	return math.sin(DateTime.now().UnixTimestampMillis / 600 + vec.X * 0.005 + vec.Y * 0.06) * 0.5 + 0.5
end

function mainapi:GetColor(vec)
	local blend = getBlendFactor(Vector2.new(vec.X or 0, vec.Y or 0))
	if uipallet.ThirdColor then
		if blend <= 0.5 then
			return uipallet.MainColor:Lerp(uipallet.SecondaryColor, blend*2)
		end
		return uipallet.SecondaryColor:Lerp(uipallet.ThirdColor, (blend-0.5)*2)
	end
	return uipallet.SecondaryColor:Lerp(uipallet.MainColor, blend)
end

local InterfaceMode = {}
local Gradients = {}

local function addGradient(parent)
	local g = Instance.new("UIGradient")
	local k = {}
	if InterfaceMode.Value ~= "Static" then
		for i = 0, mainapi.GradientKeypoints do
			local p = i / mainapi.GradientKeypoints
			local off = parent.AbsoluteSize * p
			table.insert(k, ColorSequenceKeypoint.new(p, mainapi:GetColor(InterfaceMode.Value ~= "Breathe" and parent.AbsolutePosition + off or Vector2.zero)))
		end
	else
		table.insert(k, ColorSequenceKeypoint.new(0, uipallet.MainColor))
		if uipallet.ThirdColor then
			table.insert(k, ColorSequenceKeypoint.new(0.5, uipallet.SecondaryColor))
			table.insert(k, ColorSequenceKeypoint.new(1, uipallet.ThirdColor))
		else
			table.insert(k, ColorSequenceKeypoint.new(1, uipallet.SecondaryColor))
		end
	end
	g.Color = ColorSequence.new(k)
	table.insert(Gradients, g)
	g.Parent = parent
	return g
end

mainapi:Clean(RunService.PreSimulation:Connect(function()
	for _,v in Gradients do
		if v.Parent then
			local k = {}
			if InterfaceMode.Value ~= "Static" then
				for i = 0, mainapi.GradientKeypoints do
					local p = i / mainapi.GradientKeypoints
					local off = v.Parent.AbsoluteSize * p
					table.insert(k, ColorSequenceKeypoint.new(p, mainapi:GetColor(InterfaceMode.Value ~= "Breathe" and v.Parent.AbsolutePosition + off or Vector2.zero)))
				end
			else
				table.insert(k, ColorSequenceKeypoint.new(0, uipallet.MainColor))
				if uipallet.ThirdColor then
					table.insert(k, ColorSequenceKeypoint.new(0.5, uipallet.SecondaryColor))
					table.insert(k, ColorSequenceKeypoint.new(1, uipallet.ThirdColor))
				else
					table.insert(k, ColorSequenceKeypoint.new(1, uipallet.SecondaryColor))
				end
			end
			v.Color = ColorSequence.new(k)
		end
	end
	uipallet.FinalColor = mainapi:GetColor(Vector2.zero)
end))

if shared.Modern then shared.Modern:Uninject() end

mainapi.Libraries = {
	getfontsize = getfontsize,
	uipallet = uipallet,
	addGradient = addGradient
}

local SoundEffect = Instance.new("Sound")
SoundEffect.SoundId = "rbxassetid://137273815815490"
SoundEffect.TimePosition = 0.21
SoundEffect.PlayOnRemove = true

local Main, ClickGui, Gradient, Gradient2, NotifyList, ArrayList

local UICornors = {}

function mainapi:CreateGUI()
	Main = mainapi.MainScreenGui
	Main.Name = "Modern"
	Main.DisplayOrder = 2147483647
	Main.ScreenInsets = Enum.ScreenInsets.None
	Main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Main.Parent = mainapi.ThreadFix and game:GetService("CoreGui") or LocalPlayer.PlayerGui
	Main.ResetOnSpawn = false

	ClickGui = Instance.new("Frame")
	ClickGui.Name = "ClickGui"
	ClickGui.Size = UDim2.fromScale(1.3,0.5)
	ClickGui.Position = UDim2.fromScale(0.5,0.35)
	ClickGui.AnchorPoint = Vector2.new(0.5,0.5)
	ClickGui.BackgroundTransparency = 1
	ClickGui.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ClickGui.Parent = Main

	local Modal = Instance.new("TextButton")
	Modal.Name = "Modal"
	Modal.BackgroundTransparency = 1
	Modal.Text = ""
	Modal.Modal = true
	Modal.Visible = mainapi.ClickGuiStatus
	Modal.Parent = Main

	ArrayList = Instance.new("Frame")
	ArrayList.Name = "ArrayList"
	ArrayList.Size = UDim2.fromScale(1,1)
	ArrayList.BackgroundTransparency = 1
	ArrayList.Visible = false
	ArrayList.Parent = Main

	local list = Instance.new("UIListLayout", ArrayList)
	list.FillDirection = Enum.FillDirection.Vertical
	list.VerticalAlignment = Enum.VerticalAlignment.Top
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.SortOrder = Enum.SortOrder.LayoutOrder

	local pad = Instance.new("UIPadding", ArrayList)
	pad.PaddingBottom = UDim.new(0.03,0)
	pad.PaddingTop = UDim.new(0.03,0)
	pad.PaddingLeft = UDim.new(0.01,0)
	pad.PaddingRight = UDim.new(0.01,0)

	local scale = Instance.new("UIScale", ClickGui)
	scale.Scale = mainapi.ClickGuiStatus and mainapi.Scale.Value or 0

	Gradient = Instance.new("ImageLabel")
	Gradient.Name = "Gradient"
	Gradient.AnchorPoint = Vector2.new(0.5,1)
	Gradient.Position = UDim2.fromScale(0.5,1)
	Gradient.Size = UDim2.fromScale(1,1)
	Gradient.Image = "rbxassetid://107200271119058"
	Gradient.ImageTransparency = mainapi.ClickGuiStatus and 0.76 or 1
	Gradient.BackgroundColor3 = Color3.fromRGB(0,0,0)
	Gradient.BackgroundTransparency = mainapi.ClickGuiStatus and 0.6 or 1
	Gradient.ZIndex = -10
	Gradient.Parent = Main

	Gradient2 = Gradient:Clone()
	Gradient2.Size = UDim2.fromScale(1,2)
	Gradient2.ImageTransparency = mainapi.ClickGuiStatus and 0.9 or 1
	Gradient2.Parent = Gradient

	addGradient(Gradient)
	addGradient(Gradient2)

	NotifyList = Instance.new("Frame")
	NotifyList.Name = "NotifyList"
	NotifyList.Size = UDim2.fromScale(0.2,1)
	NotifyList.Position = UDim2.fromScale(1,0)
	NotifyList.AnchorPoint = Vector2.new(1,0)
	NotifyList.BackgroundTransparency = 1
	NotifyList.Parent = Main

	local nl = Instance.new("UIListLayout", NotifyList)
	nl.FillDirection = Enum.FillDirection.Vertical
	nl.VerticalAlignment = Enum.VerticalAlignment.Bottom
	nl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	nl.SortOrder = Enum.SortOrder.LayoutOrder
	nl.Padding = UDim.new(0.01,0)

	local np = Instance.new("UIPadding", NotifyList)
	np.PaddingBottom = UDim.new(0.05,0)
	np.PaddingTop = UDim.new(0.05,0)

	local aspect = Instance.new("UIAspectRatioConstraint", ClickGui)
	aspect.AspectRatio = 10

	local cl = Instance.new("UIListLayout", ClickGui)
	cl.FillDirection = Enum.FillDirection.Horizontal
	cl.VerticalAlignment = Enum.VerticalAlignment.Center
	cl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cl.Padding = UDim.new(0.03,0)

	function mainapi:AddCatalog(arg)
		local cat = {
			Name = arg.Name or "",
			Frame = Instance.new("CanvasGroup"),
			Modules = {},
			AddModule = function() end
		}
		local btn = cat.Frame
		btn.Name = arg.Name.."_Catalog"
		btn.Size = UDim2.fromScale(0.13,4)
		btn.BackgroundTransparency = 1
		btn.Parent = ClickGui

		local namef = Instance.new("Frame", btn)
		namef.Size = UDim2.fromScale(1,0.07)
		namef.ClipsDescendants = true
		namef.BackgroundTransparency = 1

		local namet = Instance.new("TextButton", namef)
		namet.Name = "CatalogName"
		namet.AutoButtonColor = false
		namet.BackgroundColor3 = Color3.fromRGB(12,12,12)
		namet.BorderSizePixel = 0
		namet.Size = UDim2.fromScale(1,2)
		namet.Font = Enum.Font.BuilderSansBold
		namet.TextScaled = true
		namet.Text = cat.Name
		namet.TextColor3 = Color3.fromRGB(255,255,255)
		table.insert(UICornors, addCorner(namet, UDim.new(0.2,0)).Parent)

		local np = Instance.new("UIPadding", namet)
		np.PaddingBottom = UDim.new(0.63,0)
		np.PaddingTop = UDim.new(0.1,0)

		local listf = Instance.new("CanvasGroup", btn)
		listf.Name = "List"
		listf.Size = UDim2.fromScale(1,0.5)
		listf.BackgroundTransparency = 1
		table.insert(UICornors, addCorner(listf, UDim.new(0.1,0)).Parent)

		local scroll = Instance.new("ScrollingFrame", listf)
		scroll.Position = UDim2.new(0,0,0,namet.AbsoluteSize.Y/2)
		scroll.Size = UDim2.fromScale(1,0.94)
		scroll.BackgroundTransparency = 1
		scroll.ScrollBarThickness = 0
		scroll.ScrollingDirection = Enum.ScrollingDirection.Y
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarImageTransparency = 1

		mainapi:Clean(namet:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if mainapi.ClickGuiStatus then
				scroll.Position = UDim2.new(0,0,0,namet.AbsoluteSize.Y/2)
			end
		end))

		mainapi:Clean(RunService.RenderStepped:Connect(function()
			if not mainapi.ClickGuiStatus then return end
			local s = 0
			for _,v in scroll:GetChildren() do
				if (v:IsA("Frame") or v:IsA("CanvasGroup")) and v.Visible then
					s += v.AbsoluteSize.Y
				end
			end
			listf.Size = s >= btn.AbsoluteSize.Y and UDim2.new(1,0,0,btn.AbsoluteSize.Y) or UDim2.new(1,0,0,s + namet.AbsoluteSize.Y/2)
			scroll.CanvasSize = UDim2.new(0,0,0,s)
		end))

		local ll = Instance.new("UIListLayout", scroll)
		ll.FillDirection = Enum.FillDirection.Vertical
		ll.SortOrder = Enum.SortOrder.LayoutOrder

		local Count = 0

		function cat:AddModule(arg)
			local mod = {
				Name = arg.Name,
				Frame = Instance.new("TextButton"),
				Children = Instance.new("Frame"),
				Expanded = arg.Expanded or false,
				Enabled = arg.Enabled or arg.Default or false,
				ExtraText = arg.ExtraText or function() return "" end,
				Bind = {},
				Settings = {}
			}
			addMaid(mod)
			Count += 1

			if mainapi.Modules[arg.Name] then mainapi.Modules[arg.Name]:Delete() end

			local mf = Instance.new("Frame", scroll)
			mf.Size = UDim2.new(1,0,0,namet.AbsoluteSize.Y*0.33)
			mf.BorderSizePixel = 0
			mf.BackgroundColor3 = Color3.fromRGB(230,230,230)

			local mb = mod.Frame
			mb.Size = UDim2.fromScale(1,1)
			mb.BorderSizePixel = 0
			mb.BackgroundColor3 = Color3.fromRGB(31,32,28)
			mb.AutoButtonColor = false
			mb.Text = mod.Name
			mb.TextScaled = true
			mb.Font = Enum.Font.BuilderSansMedium
			mb.TextColor3 = mod.Enabled and Color3.fromRGB(255,255,255) or Color3.fromRGB(227,227,227)
			mf.LayoutOrder = -((getfontsize(mb.Text,10,Enum.Font.BuilderSansMedium).X+10)*100 - Count)
			mb.Parent = mf
			addGradient(mf)

			mod.Function = arg.Function or function() end

			if mod.Enabled then
				TweenService:Create(mb, TweenInfo.new(0.3,Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
				mb.TextColor3 = Color3.fromRGB(255,255,255)
				task.spawn(mod.Function, true)
			end

			function mod:Toggle(val)
				mod.Enabled = not mod.Enabled
				TweenService:Create(mb, TweenInfo.new(0.3,Enum.EasingStyle.Exponential), {BackgroundTransparency = mod.Enabled and 1 or 0}):Play()
				mb.TextColor3 = mod.Enabled and Color3.fromRGB(255,255,255) or Color3.fromRGB(227,227,227)
				if not mod.Enabled then
					for _,c in mod.Connections do c:Disconnect() end
					table.clear(mod.Connections)
				end
				task.spawn(mod.Function, mod.Enabled)
			end

			mb.MouseButton1Click:Connect(mod.Toggle)
			mb.MouseButton1Click:Connect(function()
				local s = SoundEffect:Clone()
				s.Volume = 0.6
				s.Parent = mainapi.MainScreenGui
				s:Play()
			end)

			local pad = Instance.new("UIPadding", mb)
			pad.PaddingBottom = UDim.new(0.13,0)
			pad.PaddingTop = UDim.new(0.13,0)

			local ch = mod.Children
			ch.Name = "Children"
			ch.BackgroundColor3 = Color3.fromRGB(22,22,22)
			ch.BorderSizePixel = 0
			ch.LayoutOrder = -((getfontsize(mb.Text,10,Enum.Font.BuilderSansMedium).X+10)*100 - Count - 1)
			ch.ClipsDescendants = true
			ch.Parent = scroll

			local cll = Instance.new("UIListLayout", ch)
			cll.FillDirection = Enum.FillDirection.Vertical
			cll.SortOrder = Enum.SortOrder.LayoutOrder
			cll.Padding = UDim.new(0, namet.AbsoluteSize.Y*0.04)

			local cp = Instance.new("UIPadding", ch)
			cp.PaddingTop = UDim.new(0, namet.AbsoluteSize.Y*0.05)

			function mod:Delete()
				local was = mod.Enabled
				mod.Enabled = false
				for _,c in mod.Connections do c:Disconnect() end
				table.clear(mod.Connections)
				if was then task.spawn(mod.Function, false) end
				ch:ClearAllChildren()
				mf:ClearAllChildren()
				ch:Destroy()
				mf:Destroy()
			end

			function mod.getChilrenSize()
				local sz = namet.AbsoluteSize.Y*0.05
				for _,v in ch:GetChildren() do
					if v:IsA("Frame") and v.Visible then
						sz += v.AbsoluteSize.Y + namet.AbsoluteSize.Y*0.05
					end
				end
				return sz == namet.AbsoluteSize.Y*0.05 and 0 or sz
			end

			if mod.Expanded then mod:Expand() end

			function mod:Expand()
				mod.Expanded = not mod.Expanded
				TweenService:Create(ch, TweenInfo.new(0.2,Enum.EasingStyle.Exponential), {Size = mod.Expanded and UDim2.new(1,0,0,mod.getChilrenSize()) or UDim2.new(1,0,0,0)}):Play()
			end

			mb.MouseButton2Click:Connect(mod.Expand)
			mb.MouseButton2Click:Connect(function()
				if mod.getChilrenSize() ~= 0 then
					local s = SoundEffect:Clone()
					s.Volume = 0.7
					s.Parent = mainapi.MainScreenGui
					s:Play()
				end
			end)

			mainapi.Modules[mod.Name] = mod
			return mod
		end

		return cat
	end
end

local TargetHudMain = mainapi.TargetHudFrame
TargetHudMain.Size = UDim2.new(0, mainapi.MainScreenGui.AbsoluteSize.Y/6, 0, mainapi.MainScreenGui.AbsoluteSize.Y/14)
TargetHudMain.BackgroundTransparency = 1
TargetHudMain.Parent = mainapi.MainScreenGui
TargetHudMain.Visible = false

function mainapi:Notify(arg)
	local n = {
		Text = arg.Text or "None",
		Duration = arg.Duration or 2,
		Frame = Instance.new("Frame")
	}
	local nf = n.Frame
	nf.Size = UDim2.fromScale(0.8,0.05)
	nf.BackgroundTransparency = 1
	nf.BackgroundColor3 = Color3.fromRGB(20,20,20)
	nf.Parent = NotifyList

	local sc = Instance.new("UIScale", nf)
	sc.Scale = 0

	local nm = Instance.new("Frame", nf)
	nm.Name = "NotifyMain"
	nm.Size = UDim2.fromScale(1,1)
	nm.Position = UDim2.fromScale(2,0.2)
	nm.BackgroundTransparency = 0.3
	nm.BorderSizePixel = 0
	nm.BackgroundColor3 = Color3.fromRGB(20,20,20)
	addBlur(nm)
	addCorner(nm)

	local nt = Instance.new("TextButton", nm)
	nt.Size = UDim2.fromScale(1,1)
	nt.Text = n.Text
	nt.Font = mainapi.Font
	nt.BorderSizePixel = 0
	nt.BackgroundTransparency = 1
	nt.TextScaled = true
	nt.TextXAlignment = Enum.TextXAlignment.Left
	nt.TextColor3 = Color3.fromRGB(255,255,255)

	local pad = Instance.new("UIPadding", nt)
	pad.PaddingBottom = UDim.new(0.25,0)
	pad.PaddingLeft = UDim.new(0.1,0)
	pad.PaddingRight = UDim.new(0.1,0)
	pad.PaddingTop = UDim.new(0.25,0)

	local fill = Instance.new("Frame", nm)
	fill.Size = UDim2.fromScale(0,1)
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = Color3.fromRGB(210,210,210)
	addGradient(fill)
	addCorner(fill)
	addBlur(fill)

	TweenService:Create(nm, TweenInfo.new(1,Enum.EasingStyle.Exponential), {Position = UDim2.fromScale(0,0)}):Play()
	TweenService:Create(sc, TweenInfo.new(0.3,Enum.EasingStyle.Exponential), {Scale = 1}):Play()
	TweenService:Create(fill, TweenInfo.new(n.Duration,Enum.EasingStyle.Linear), {Size = UDim2.fromScale(1,1)}):Play()

	function n:Delete()
		if n.Status then return end
		n.Status = true
		TweenService:Create(nm, TweenInfo.new(1,Enum.EasingStyle.Exponential), {Position = UDim2.fromScale(2,0.2)}):Play()
		task.delay(1, function()
			nf:Destroy()
		end)
	end

	nt.MouseButton1Click:Connect(n.Delete)
	task.delay(n.Duration, n.Delete)
end

mainapi:Clean(UIS.InputBegan:Connect(function(input)
	if UIS:GetFocusedTextBox() or input.KeyCode == Enum.KeyCode.Unknown then return end
	if table.find(mainapi.Keybind, input.KeyCode.Name) then
		if mainapi.ThreadFix then setthreadidentity(8) end
		mainapi.ClickGuiStatus = not mainapi.ClickGuiStatus
		Main.Modal.Visible = mainapi.ClickGuiStatus
		TweenService:Create(ClickGui.UIScale, TweenInfo.new(0.3,Enum.EasingStyle.Exponential), {Scale = mainapi.ClickGuiStatus and mainapi.Scale.Value or 0}):Play()
		TweenService:Create(Gradient, TweenInfo.new(1,Enum.EasingStyle.Exponential), {Transparency = mainapi.ClickGuiStatus and 0.6 or 1}):Play()
		TweenService:Create(Gradient2, TweenInfo.new(1,Enum.EasingStyle.Exponential), {Transparency = mainapi.ClickGuiStatus and 0.6 or 1}):Play()
		TweenService:Create(Gradient, TweenInfo.new(2,Enum.EasingStyle.Exponential), {ImageTransparency = mainapi.ClickGuiStatus and 0.76 or 1}):Play()
		TweenService:Create(Gradient2, TweenInfo.new(2,Enum.EasingStyle.Exponential), {ImageTransparency = mainapi.ClickGuiStatus and 0.9 or 1}):Play()
	end
end))

local ESP_Folder
local ESP_Update_Interval = 3
local ESP_Connection

local function SetupESPFolder()
	if ESP_Folder and ESP_Folder.Parent then return end
	ESP_Folder = Instance.new("Folder")
	ESP_Folder.Name = "ModernBoxESP"
	ESP_Folder.Parent = game:GetService("CoreGui")
end

local function ClearOldESP()
	if not ESP_Folder then return end
	for _,v in ESP_Folder:GetChildren() do
		v:Destroy()
	end
end

local function GetBoundingBox(char)
	local parts = {}
	for _,p in char:GetChildren() do
		if p:IsA("BasePart") or p:IsA("MeshPart") then table.insert(parts,p) end
	end
	if #parts == 0 then return end

	local minP, maxP
	for _,p in parts do
		local cf, sz = p.CFrame, p.Size
		for _,c in {
			cf * CFrame.new(-sz.X/2,-sz.Y/2,-sz.Z/2),
			cf * CFrame.new( sz.X/2,-sz.Y/2,-sz.Z/2),
			cf * CFrame.new(-sz.X/2, sz.Y/2,-sz.Z/2),
			cf * CFrame.new( sz.X/2, sz.Y/2,-sz.Z/2),
			cf * CFrame.new(-sz.X/2,-sz.Y/2, sz.Z/2),
			cf * CFrame.new( sz.X/2,-sz.Y/2, sz.Z/2),
			cf * CFrame.new(-sz.X/2, sz.Y/2, sz.Z/2),
			cf * CFrame.new( sz.X/2, sz.Y/2, sz.Z/2)
		} do
			local pos = c.Position
			if not minP then minP,maxP = pos,pos
			else
				minP = Vector3.new(math.min(minP.X,pos.X),math.min(minP.Y,pos.Y),math.min(minP.Z,pos.Z))
				maxP = Vector3.new(math.max(maxP.X,pos.X),math.max(maxP.Y,pos.Y),math.max(maxP.Z,pos.Z))
			end
		end
	end
	return minP, maxP
end

local function DrawBoxESP(char)
	local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if not root then return end

	local minP, maxP = GetBoundingBox(char)
	if not minP then return end

	local size = maxP - minP

	local bb = Instance.new("BillboardGui")
	bb.Name = "BoxESP"
	bb.Parent = ESP_Folder
	bb.Adornee = root
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0,200,0,200)
	bb.StudsOffset = Vector3.new(0, size.Y/2 + 1, 0)

	local f = Instance.new("Frame", bb)
	f.Size = UDim2.new(1,0,1,0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0

	local lines = {}
	local th = 2
	local col = Color3.fromRGB(255,80,80)

	local function ln()
		local l = Instance.new("Frame")
		l.BackgroundColor3 = col
		l.BorderSizePixel = 0
		l.Parent = f
		return l
	end

	lines.top    = ln()
	lines.bottom = ln()
	lines.left   = ln()
	lines.right  = ln()

	local function update()
		if not char or not char.Parent then bb:Destroy() return end
		local rp, vis = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
		if not vis then bb.Enabled = false return end
		bb.Enabled = true

		local sc = 1000 / (rp.Z * math.tan(math.rad(workspace.CurrentCamera.FieldOfView/2)))
		local w = size.X * sc * 1.2
		local h = size.Y * sc * 1.4

		bb.Size = UDim2.new(0,w,0,h)

		lines.top.Size    = UDim2.new(1,0,0,th)   lines.top.Position    = UDim2.new(0,0,0,0)
		lines.bottom.Size = UDim2.new(1,0,0,th)   lines.bottom.Position = UDim2.new(0,0,1,-th)
		lines.left.Size   = UDim2.new(0,th,1,0)   lines.left.Position   = UDim2.new(0,0,0,0)
		lines.right.Size  = UDim2.new(0,th,1,0)   lines.right.Position  = UDim2.new(1,-th,0,0)
	end

	RunService.RenderStepped:Connect(function()
		if not bb.Parent then return end
		pcall(update)
	end)

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Died:Connect(function() bb:Destroy() end) end
end

local function UpdateAllESP()
	if not ESP_Folder then return end
	SetupESPFolder()
	ClearOldESP()

	for _,p in Players:GetPlayers() do
		if p == LocalPlayer then continue end
		local c = p.Character
		if not c then continue end
		local h = c:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 then continue end
		DrawBoxESP(c)
	end
end

local Combat  = mainapi:AddCatalog({Name="Combat"})
local Render  = mainapi:AddCatalog({Name="Render"})
local Movement = mainapi:AddCatalog({Name="Movement"})
local Player  = mainapi:AddCatalog({Name="Player"})
local Other   = mainapi:AddCatalog({Name="Other"})

run(function()
	local esp = Render:AddModule({
		Name = "Box ESP",
		Function = function(on)
			if on then
				SetupESPFolder()
				UpdateAllESP()
				if ESP_Connection then ESP_Connection:Disconnect() end
				ESP_Connection = RunService.Heartbeat:Connect(function()
					if tick() % ESP_Update_Interval < 0.05 then
						task.spawn(UpdateAllESP)
					end
				end)
			else
				if ESP_Connection then
					ESP_Connection:Disconnect()
					ESP_Connection = nil
				end
				if ESP_Folder then
					ESP_Folder:Destroy()
					ESP_Folder = nil
				end
			end
		end
	})

	esp:AddSlider({
		Name = "Update Interval",
		Min = 0.5,
		Max = 10,
		Decimal = 1,
		Default = 3,
		Function = function(v) ESP_Update_Interval = v end
	})
end)

run(function()
	local nametags = Render:AddModule({
		Name = "Nametags",
		Function = function(state)
			if state then
				local drawings = {}
				local conns = {}

				local function esp(p, cr)
					if p == LocalPlayer then return end
					local h = cr:FindFirstChild("Humanoid")
					local hrp = cr:FindFirstChild("Head")
					if not h or not hrp then return end

					local text = Drawing.new("Text")
					text.Visible = false
					text.Center = true
					text.Outline = true
					text.OutlineColor = Color3.new(0,0,0)
					text.Font = 2
					text.Size = 16
					text.Color = Color3.fromRGB(220,220,255)

					drawings[p] = text

					local conn = RunService.RenderStepped:Connect(function()
						if not cr or not cr.Parent or not h or h.Health <= 0 then
							text:Remove()
							if conn then conn:Disconnect() end
							drawings[p] = nil
							return
						end

						local pos, onscreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
						if onscreen then
							text.Position = Vector2.new(pos.X, pos.Y)
							text.Text = p.Name
							text.Visible = true
						else
							text.Visible = false
						end
					end)

					conns[p] = conn

					cr.AncestryChanged:Connect(function(_, parent)
						if not parent then
							text:Remove()
							if conn then conn:Disconnect() end
							drawings[p] = nil
							conns[p] = nil
						end
					end)

					h.HealthChanged:Connect(function(health)
						if health <= 0 then
							text:Remove()
							if conn then conn:Disconnect() end
							drawings[p] = nil
							conns[p] = nil
						end
					end)
				end

				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer and p.Character then
						esp(p, p.Character)
					end
					p.CharacterAdded:Connect(function(cr)
						esp(p, cr)
					end)
				end

				Players.PlayerAdded:Connect(function(p)
					if p ~= LocalPlayer then
						p.CharacterAdded:Connect(function(cr)
							esp(p, cr)
						end)
						if p.Character then
							esp(p, p.Character)
						end
					end
				end)
			else
				for _, text in pairs(drawings) do if text then text:Remove() end end
				for _, conn in pairs(conns) do if conn then conn:Disconnect() end end
				table.clear(drawings)
				table.clear(conns)
			end
		end
	})
end)

run(function()
	local skeletons = {}
	local connections = {}

	local SkeletonSettings = {
		Color = Color3.new(0, 1, 0),
		Thickness = 2,
		Transparency = 1
	}

	local function createLine()
		local line = Drawing.new("Line")
		line.Color = SkeletonSettings.Color
		line.Thickness = SkeletonSettings.Thickness
		line.Transparency = SkeletonSettings.Transparency
		return line
	end

	local function removeSkeleton(skeleton)
		for _, line in pairs(skeleton) do
			line:Remove()
		end
	end

	local function updateSkeleton(plr, skeleton)
		if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
			for _, line in pairs(skeleton) do line.Visible = false end
			return
		end

		local character = plr.Character
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end

		local joints = {}
		local connList = {}

		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			joints = {
				Head = character.Head,
				UpperTorso = character.UpperTorso,
				LowerTorso = character.LowerTorso,
				LeftUpperArm = character.LeftUpperArm,
				LeftLowerArm = character.LeftLowerArm,
				LeftHand = character.LeftHand,
				RightUpperArm = character.RightUpperArm,
				RightLowerArm = character.RightLowerArm,
				RightHand = character.RightHand,
				LeftUpperLeg = character.LeftUpperLeg,
				LeftLowerLeg = character.LeftLowerLeg,
				RightUpperLeg = character.RightUpperLeg,
				RightLowerLeg = character.RightLowerLeg,
			}
			connList = {
				{"Head", "UpperTorso"},
				{"UpperTorso", "LowerTorso"},
				{"LowerTorso", "LeftUpperLeg"},
				{"LeftUpperLeg", "LeftLowerLeg"},
				{"LowerTorso", "RightUpperLeg"},
				{"RightUpperLeg", "RightLowerLeg"},
				{"UpperTorso", "LeftUpperArm"},
				{"LeftUpperArm", "LeftLowerArm"},
				{"LeftLowerArm", "LeftHand"},
				{"UpperTorso", "RightUpperArm"},
				{"RightUpperArm", "RightLowerArm"},
				{"RightLowerArm", "RightHand"},
			}
		elseif humanoid.RigType == Enum.HumanoidRigType.R6 then
			joints = {
				Head = character.Head,
				Torso = character.Torso,
				LeftArm = character["Left Arm"],
				RightArm = character["Right Arm"],
				LeftLeg = character["Left Leg"],
				RightLeg = character["Right Leg"],
			}
			connList = {
				{"Head", "Torso"},
				{"Torso", "LeftArm"},
				{"Torso", "RightArm"},
				{"Torso", "LeftLeg"},
				{"Torso", "RightLeg"},
			}
		else
			return
		end

		for i, pair in ipairs(connList) do
			local partA = joints[pair[1]]
			local partB = joints[pair[2]]
			if not partA or not partB then continue end

			local posA, visA = workspace.CurrentCamera:WorldToViewportPoint(partA.Position)
			local posB, visB = workspace.CurrentCamera:WorldToViewportPoint(partB.Position)

			local line = skeleton[i] or createLine()
			skeleton[i] = line

			if visA and visB then
				line.From = Vector2.new(posA.X, posA.Y)
				line.To = Vector2.new(posB.X, posB.Y)
				line.Visible = true
			else
				line.Visible = false
			end
		end
	end

	local function trackPlayer(plr)
		if plr == LocalPlayer then return end
		if skeletons[plr] then return end

		local skeleton = {}
		skeletons[plr] = skeleton

		local conn = RunService.RenderStepped:Connect(function()
			if not plr or not plr.Parent or not skeletons[plr] then
				removeSkeleton(skeleton)
				skeletons[plr] = nil
				return
			end
			updateSkeleton(plr, skeleton)
		end)

		connections[plr] = conn

		if plr.Character then
			updateSkeleton(plr, skeleton)
		end

		plr.CharacterAdded:Connect(function()
			updateSkeleton(plr, skeleton)
		end)
	end

	local function untrackPlayer(plr)
		if skeletons[plr] then
			removeSkeleton(skeletons[plr])
			skeletons[plr] = nil
		end
		if connections[plr] then
			connections[plr]:Disconnect()
			connections[plr] = nil
		end
	end

	Render:AddModule({
		Name = "Skeleton ESP",
		Function = function(enabled)
			if enabled then
				for _, plr in ipairs(Players:GetPlayers()) do
					trackPlayer(plr)
				end
				Players.PlayerAdded:Connect(trackPlayer)
				Players.PlayerRemoving:Connect(untrackPlayer)
			else
				for plr, _ in pairs(skeletons) do
					untrackPlayer(plr)
				end
				table.clear(skeletons)
				table.clear(connections)
			end
		end
	})
end)

run(function()
	local tracers = {}
	local tracerConnections = {}

	local TracerSettings = {
		Color = Color3.fromRGB(0, 255, 50),
		Thickness = 1.4,
		Transparency = 1,
		TeamCheck = false,
		AutoThickness = false
	}

	local red = Color3.fromRGB(227, 52, 52)
	local green = Color3.fromRGB(88, 217, 24)

	local function createTracer()
		local line = Drawing.new("Line")
		line.Visible = false
		line.From = Vector2.new(0, 0)
		line.To = Vector2.new(0, 0)
		line.Color = TracerSettings.Color
		line.Thickness = TracerSettings.Thickness
		line.Transparency = TracerSettings.Transparency
		return line
	end

	local function updateTracer(plr, tracer)
		if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") 
			or not plr.Character:FindFirstChild("Humanoid") 
			or plr.Character.Humanoid.Health <= 0 then
			tracer.Visible = false
			return
		end

		local root = plr.Character.HumanoidRootPart
		local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(root.Position)

		if onScreen then
			local footPos = workspace.CurrentCamera:WorldToViewportPoint((root.CFrame * CFrame.new(0, -3, 0)).Position)

			tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
			tracer.To = Vector2.new(footPos.X, footPos.Y)

			if TracerSettings.TeamCheck then
				tracer.Color = (plr.TeamColor == LocalPlayer.TeamColor) and green or red
			else
				tracer.Color = TracerSettings.Color
			end

			if TracerSettings.AutoThickness then
				local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) 
					and (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude or 100
				tracer.Thickness = math.clamp(1 / dist * 100, 0.5, 4)
			else
				tracer.Thickness = TracerSettings.Thickness
			end

			tracer.Visible = true
		else
			tracer.Visible = false
		end
	end

	local function setupTracer(plr)
		if plr == LocalPlayer then return end
		if tracers[plr] then return end

		local tracer = createTracer()
		tracers[plr] = tracer

		local conn = RunService.RenderStepped:Connect(function()
			if not tracers[plr] then
				tracer:Remove()
				return
			end
			updateTracer(plr, tracer)
		end)

		tracerConnections[plr] = conn

		if plr.Character then
			updateTracer(plr, tracer)
		end

		plr.CharacterAdded:Connect(function()
			updateTracer(plr, tracer)
		end)
	end

	local function removeTracer(plr)
		if tracers[plr] then
			tracers[plr]:Remove()
			tracers[plr] = nil
		end
		if tracerConnections[plr] then
			tracerConnections[plr]:Disconnect()
			tracerConnections[plr] = nil
		end
	end

	Render:AddModule({
		Name = "Line ESP",
		Function = function(enabled)
			if enabled then
				for _, plr in ipairs(Players:GetPlayers()) do
					setupTracer(plr)
				end

				local playerAddedConn = Players.PlayerAdded:Connect(setupTracer)
				local playerRemovingConn = Players.PlayerRemoving:Connect(removeTracer)

				table.insert(tracerConnections, playerAddedConn)
				table.insert(tracerConnections, playerRemovingConn)
			else
				for plr, _ in pairs(tracers) do
					removeTracer(plr)
				end
				for _, conn in ipairs(tracerConnections) do
					if typeof(conn) == "RBXScriptConnection" then
						conn:Disconnect()
					end
				end
				table.clear(tracers)
				table.clear(tracerConnections)
			end
		end
	})
end)

run(function()
	Render:AddModule({
		Name = "Skin Changer",
		Function = function(enabled)
			if enabled then
				pcall(function()
					loadstring(game:HttpGet("https://raw.githubusercontent.com/codeEzyx/rivals-skin-changer/refs/heads/main/skinchanger.lua"))()
				end)
			end
		end
	})
end)

run(function()
	local SilentAimSettings = {
		Enabled = false,
		TeamCheck = false,
		Prediction = false,
		PredictionAmount = 0.165,
		HitChance = 100
	}

	local SilentAimModule = Combat:AddModule({
		Name = "Silent Aim",
		Function = function(enabled)
			SilentAimSettings.Enabled = enabled
		end
	})

	SilentAimModule:AddToggle({
		Name = "Team Check",
		Default = false,
		Function = function(v) SilentAimSettings.TeamCheck = v end
	})

	SilentAimModule:AddToggle({
		Name = "Prediction",
		Default = false,
		Function = function(v) SilentAimSettings.Prediction = v end
	})

	SilentAimModule:AddSlider({
		Name = "Prediction Amount",
		Min = 0.1,
		Max = 0.3,
		Decimal = 3,
		Default = 0.165,
		Function = function(v) SilentAimSettings.PredictionAmount = v end
	})

	SilentAimModule:AddSlider({
		Name = "Hit Chance",
		Min = 0,
		Max = 100,
		Default = 100,
		Function = function(v) SilentAimSettings.HitChance = v end
	})

	local Camera = workspace.CurrentCamera
	local Mouse = LocalPlayer:GetMouse()

	local function isAlive(plr)
		if not plr or not plr.Character then return false end
		local hum = plr.Character:FindFirstChildOfClass("Humanoid")
		return hum and hum.Health > 0
	end

	local function isTeamOk(plr)
		if not SilentAimSettings.TeamCheck then return true end
		return plr.Team ~= LocalPlayer.Team
	end

	local function getClosestToMouse()
		local closest, minDist = nil, 9999
		local mousePos = UIS:GetMouseLocation()

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LocalPlayer then continue end
			if not isAlive(plr) then continue end
			if not isTeamOk(plr) then continue end

			local char = plr.Character
			local part = char and char:FindFirstChild("Head")
			if not part then continue end

			local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
			if not onScreen then continue end

			local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
			if dist < minDist then
				closest = part
				minDist = dist
			end
		end

		return closest
	end

	local oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		local args = {...}

		if not SilentAimSettings.Enabled then
			return oldNamecall(self, ...)
		end

		if checkcaller() then
			return oldNamecall(self, ...)
		end

		if self ~= workspace or method ~= "Raycast" or #args < 3 then
			return oldNamecall(self, ...)
		end

		if math.random(1, 100) > SilentAimSettings.HitChance then
			return oldNamecall(self, ...)
		end

		local target = getClosestToMouse()
		if not target then
			return oldNamecall(self, ...)
		end

		local origin = args[1]
		local direction = (target.Position - origin).Unit * 2000

		if SilentAimSettings.Prediction then
			local vel = target.AssemblyLinearVelocity or Vector3.zero
			local predicted = target.Position + vel * SilentAimSettings.PredictionAmount
			direction = (predicted - origin).Unit * 2000
		end

		args[2] = direction
		return oldNamecall(self, unpack(args))
	end))

	local oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if not SilentAimSettings.Enabled or checkcaller() or self ~= Mouse then
			return oldIndex(self, key)
		end

		local target = getClosestToMouse()
		if not target then
			return oldIndex(self, key)
		end

		if key == "Hit" or key == "hit" then
			local pos = target.Position
			if SilentAimSettings.Prediction then
				local vel = target.AssemblyLinearVelocity or Vector3.zero
				pos = pos + vel * SilentAimSettings.PredictionAmount
			end
			return CFrame.new(pos)
		end

		if key == "Target" or key == "target" then
			return target
		end

		return oldIndex(self, key)
	end))
end)

run(function()
	local AimAssistSettings = {
		Enabled = false,
		TeamCheck = true,
		FOV = math.rad(25),
		Smoothness = 0.15
	}

	local AimAssistModule = Combat:AddModule({
		Name = "Aim Assist",
		Function = function(enabled)
			AimAssistSettings.Enabled = enabled
		end
	})

	AimAssistModule:AddToggle({
		Name = "Team Check",
		Default = true,
		Function = function(v) AimAssistSettings.TeamCheck = v end
	})

	AimAssistModule:AddSlider({
		Name = "FOV",
		Min = 5,
		Max = 90,
		Default = 25,
		Function = function(v) AimAssistSettings.FOV = math.rad(v) end
	})

	AimAssistModule:AddSlider({
		Name = "Smoothness",
		Min = 0.05,
		Max = 0.5,
		Decimal = 2,
		Default = 0.15,
		Function = function(v) AimAssistSettings.Smoothness = v end
	})

	local Camera = workspace.CurrentCamera
	local PlayersService = game:GetService("Players")
	local LocalPlayer = PlayersService.LocalPlayer

	local function getAngleDifference(targetPart)
		if not targetPart then return math.huge end
		local headPos = targetPart.Position
		local camLook = Camera.CFrame.LookVector
		local directionToTarget = (headPos - Camera.CFrame.Position).Unit
		local dot = camLook:Dot(directionToTarget)
		return math.acos(math.clamp(dot, -1, 1))
	end

	local function findBestTarget()
		local bestTarget = nil
		local bestAngle = AimAssistSettings.FOV

		for _, player in ipairs(PlayersService:GetPlayers()) do
			if player == LocalPlayer then continue end
			if not player.Character then continue end

			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then continue end

			local head = player.Character:FindFirstChild("Head")
			if not head then continue end

			if AimAssistSettings.TeamCheck and player.Team == LocalPlayer.Team then continue end

			local angle = getAngleDifference(head)
			if angle < bestAngle then
				bestAngle = angle
				bestTarget = head
			end
		end

		return bestTarget
	end

	local connection = RunService.RenderStepped:Connect(function()
		if not AimAssistSettings.Enabled then return end

		local target = findBestTarget()
		if not target then return end

		local currentCFrame = Camera.CFrame
		local targetCFrame = CFrame.new(currentCFrame.Position, target.Position)

		Camera.CFrame = currentCFrame:Lerp(targetCFrame, AimAssistSettings.Smoothness)
	end)

	AimAssistModule:Clean(connection)
end)

run(function()
	local TriggerBotModule = Combat:AddModule({
		Name = "Trigger Bot",
		Function = function(enabled)
			if enabled then
				local mouse = LocalPlayer:GetMouse()

				local conn = RunService.RenderStepped:Connect(function()
					local targetParent = mouse.Target and mouse.Target.Parent
					if not targetParent then return end

					local humanoid = targetParent:FindFirstChildOfClass("Humanoid")
					if not humanoid or humanoid.Health <= 0 then return end

					local player = Players:GetPlayerFromCharacter(targetParent)
					if not player or player.Team == LocalPlayer.Team then return end

					mouse1press()

					repeat
						RunService.RenderStepped:Wait()
					until not mouse.Target 
					   or not mouse.Target.Parent 
					   or not mouse.Target.Parent:FindFirstChildOfClass("Humanoid")

					mouse1release()
				end)

				TriggerBotModule:Clean(conn)
			end
		end
	})
end)

shared.Modern = mainapi
