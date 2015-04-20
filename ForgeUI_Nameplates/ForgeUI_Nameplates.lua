require "Window"

local ForgeUI
local ForgeUI_Nameplates = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
krtClassEnums = {
	[GameLib.CodeEnumClass.Warrior]      	= "Warrior",
	[GameLib.CodeEnumClass.Engineer]     	= "Engineer",
	[GameLib.CodeEnumClass.Esper]        	= "Esper",
	[GameLib.CodeEnumClass.Medic]        	= "Medic",
	[GameLib.CodeEnumClass.Stalker]      	= "Stalker",
	[GameLib.CodeEnumClass.Spellslinger]	= "Spellslinger"
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
local fnDrawName
local fnDrawHealth
local fnDrawShield
local fnDrawAbsorb

local fnDrawRewards
local fnDrawCastBar
local fnDrawTarget

local fnColorNameplate

function ForgeUI_Nameplates:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	self.tPreloadUnits = {}

	self.arWindowPool = {}
	self.arUnit2Nameplate = {}
	self.arWnd2Nameplate = {}

	-- mandatory 
    self.api_version = 2
	self.version = "1.0.0"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_Nameplates"
	self.strDisplayName = "Nameplates"
	
	self.wndContainers = {}
	
	self.tStylers = {}
	
	-- optional
	self.settings_version = 3
    self.tSettings = {
		nMaxRange = 75,
		bUseOcclusion = true,
		bShowTitles = false,
		crShield = "FF0699F3",
		crAbsorb = "FFFFC600",
		crDead = "FF666666",
		tUnits = {
			Target = {
				bShowMarker = true
			},
			Player = {
				bEnabled = true,
				nShowName = 0,
				nShowBars = 0,
				nShowCast = 0,
				nShowGuild = 0,
				crName = "FFFFFFFF",
				crHealth = "FF75CC26",
				bClassColors = false,
			},
			FriendlyPlayer = {
				bEnabled = true,
				nShowName = 3,
				nShowBars = 3,
				nShowCast = 0,
				nShowGuild = 0,
				crName = "FFFFFFFF",
				crHealth = "FF75CC26",
				bClassColors = true,
			},
			PartyPlayer = {
				bEnabled = true,
				nShowName = 3,
				nShowBars = 3,
				nShowCast = 0,
				nShowGuild = 0,
				crName = "FF43C8F3",
				crHealth = "FF75CC26",
				bClassColors = true,
			},
			HostilePlayer = {
				bEnabled = true,
				nShowName = 3,
				nShowBars = 3,
				nShowCast = 3,
				nShowGuild = 0,
				crName = "FFFF0000",
				crHealth = "FFFF0000",
				bClassColors = true,
			},
			FriendlyNPC = {
				bEnabled = true,
				nShowName = 3,
				nShowBars = 2,
				nShowCast = 2,
				nShowGuild = 3,
				crName = "FF76CD26",
				crHealth = "FF75CC26",
			},
			NeutralNPC = {
				bEnabled = true,
				nShowName = 3,
				nShowBars = 2,
				nShowCast = 2,
				nShowGuild = 0,
				crName = "FFFFF569",
				crHealth = "FFF3D829",
			},
			HostileNPC = {
				bEnabled = true,
				nShowName = 3,
				nShowBars = 2,
				nShowCast = 2,
				nShowGuild = 0,
				crName = "FFD9544D",
				crHealth = "FFE50000",
			},
			UnknownNPC = {
				bEnabled = false,
				nShowName = 0,
				nShowBars = 0,
			},
			FriendlyPet = {
				bEnabled = false,
				nShowName = 0,
				nShowBars = 0,
			},
			PlayerPet = {
				bEnabled = true,
				nShowName = 0,
				nShowBars = 0,
				crName = "FFFFFFFF",
				crHealth = "FFFFFFFF"
			},
			HostilePet = {
				bEnabled = false,
				nShowName = 0,
				nShowBars = 0,
			},
			Simple = {
				bEnabled = false,
				nShowName = 0,
				crName = "FFFFFFFF"
			},
			Pickup = {
				bEnabled = true,
				nShowName = 3,
				crName = "FFFFFFFF"
			},
			PickupNotPlayer = {
				bEnabled = false,
				nShowName = 0,
				crName = "FFFFFFFF"
			},
			Collectible = {
				bEnabled = false,
				nShowName = 0,
				crName = "FFFFFFFF"
			},
			PinataLoot = {
				bEnabled = false,
				nShowName = 0,
				crName = "FFFFFFFF"
			},
			Mount = {
				bEnabled = false,
				nShowName = 0,
				crName = "FFFFFFFF"
			},
			
		},
		knNameplatePoolLimit = 500,
		knTargetRange = 5000,
	}
	
    return o
end

function ForgeUI_Nameplates:Init()
    Apollo.RegisterAddon(self, false, nil, {})
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates OnLoad
-----------------------------------------------------------------------------------------------

function ForgeUI_Nameplates:OnLoad()
	Apollo.RegisterEventHandler("UnitCreated", 					"OnPreloadUnitCreated", self)

	self.xmlDoc = XmlDoc.CreateFromFile("ForgeUI_Nameplates.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ForgeUI_Nameplates:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then return end

	if ForgeUI == nil then -- forgeui loaded
		ForgeUI = Apollo.GetAddon("ForgeUI")
	end
	
	ForgeUI.API_RegisterAddon(self)
end

function ForgeUI_Nameplates:ForgeAPI_AfterRegistration()
	Apollo.RemoveEventHandler("UnitCreated", self)
	
	Apollo.RegisterEventHandler("UnitCreated", 					"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 				"OnUnitDestroyed", self)

	Apollo.RegisterEventHandler("VarChange_FrameCount", 		"OnFrame", self)

	Apollo.RegisterEventHandler("TargetUnitChanged", 			"OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("UnitNameChanged", 				"OnUnitNameChanged", self)
	Apollo.RegisterEventHandler("UnitTitleChanged", 			"OnUnitTitleChanged", self)
	Apollo.RegisterEventHandler("PlayerTitleChange", 			"OnPlayerTitleChanged", self)
	Apollo.RegisterEventHandler("UnitGuildNameplateChanged", 	"OnUnitGuildNameplateChanged",self)
	Apollo.RegisterEventHandler("UnitMemberOfGuildChange", 		"OnUnitMemberOfGuildChange", self)
	Apollo.RegisterEventHandler("GuildChange", 					"OnGuildChange", self)
	Apollo.RegisterEventHandler("UnitGibbed",					"OnUnitGibbed", self)
	
	local tRewardUpdateEvents = {
		"QuestObjectiveUpdated", "QuestStateChanged", "ChallengeAbandon", "ChallengeLeftArea",
		"ChallengeFailTime", "ChallengeFailArea", "ChallengeActivate", "ChallengeCompleted",
		"ChallengeFailGeneric", "PublicEventObjectiveUpdate", "PublicEventUnitUpdate",
		"PlayerPathMissionUpdate", "FriendshipAdd", "FriendshipPostRemove", "FriendshipUpdate",
		"PlayerPathRefresh", "ContractObjectiveUpdated", "ContractStateChanged", "ChallengeUpdated"
	}

	for i, str in pairs(tRewardUpdateEvents) do
		Apollo.RegisterEventHandler(str, "RequestUpdateAllNameplateRewards", self)
	end

	Apollo.RegisterTimerHandler("VisibilityTimer", "OnVisibilityTimer", self)
	Apollo.CreateTimer("VisibilityTimer", 0.5, true)

	self.arUnit2Nameplate = {}
	self.arWnd2Nameplate = {}

	-- Cache defaults
	local wndTemp = Apollo.LoadForm(self.xmlDoc, "Nameplate", nil, self)
	self.nFrameLeft, self.nFrameTop, self.nFrameRight, self.nFrameBottom = wndTemp:FindChild("Container:Health:HealthBars:MaxHealth"):GetAnchorOffsets()
	self.nHealthWidth = self.nFrameRight - self.nFrameLeft
	wndTemp:Destroy()
	
	self:CreateUnitsFromPreload()
end

function ForgeUI_Nameplates:OnVisibilityTimer()
	self:UpdateAllNameplateVisibility()
end

function ForgeUI_Nameplates:RequestUpdateAllNameplateRewards()
	self.bRedrawRewardIcons = true
end

function ForgeUI_Nameplates:UpdateNameplateRewardInfo(tNameplate)
	local tFlags =
	{
		bVert = false,
		bHideQuests = not self.bShowRewardTypeQuest,
		bHideChallenges = not self.bShowRewardTypeChallenge,
		bHideMissions = not self.bShowRewardTypeMission,
		bHidePublicEvents = not self.bShowRewardTypePublicEvent,
		bHideRivals = not self.bShowRivals,
		bHideFriends = not self.bShowFriends
	}

	if RewardIcons ~= nil and RewardIcons.GetUnitRewardIconsForm ~= nil then
		RewardIcons.GetUnitRewardIconsForm(tNameplate.wnd.questRewards, tNameplate.unitOwner, tFlags)
	end
end

function ForgeUI_Nameplates:UpdateAllNameplateVisibility()
	
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:UpdateNameplateVisibility(tNameplate)
		if self.bRedrawRewardIcons then
			self:UpdateNameplateRewardInfo(tNameplate)
		end
	end

	self.bRedrawRewardIcons = false
end

function ForgeUI_Nameplates:UpdateNameplateVisibility(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local wndNameplate = tNameplate.wndNameplate
	local bIsMounted = unitOwner:IsMounted()
	local unitWindow = wndNameplate:GetUnit()

	if bIsMounted and unitWindow == unitOwner then
		if not tNameplate.bMounted then
			wndNameplate:SetUnit(unitOwner:GetUnitMount(), 1)
			tNameplate.bMounted = true
		end
	elseif not bIsMounted and unitWindow ~= unitOwner then
		if tNameplate.bMounted then
			wndNameplate:SetUnit(unitOwner, 1)
			tNameplate.bMounted = false
		end
	end

	local eDisposition = unitOwner:GetDispositionTo(self.unitPlayer)
	
	tNameplate.bOnScreen = wndNameplate:IsOnScreen()
	tNameplate.bOccluded = wndNameplate:IsOccluded()
	
	local bNewShow = self:HelperVerifyVisibilityOptions(tNameplate) and self:CheckDrawDistance(tNameplate)
	if bNewShow ~= tNameplate.bShow then
		wndNameplate:Show(bNewShow, true)
		tNameplate.bShow = bNewShow
	end
	
	if bNewShow then
		fnColorNameplate(self, tNameplate)
		
		fnDrawHealth(self, tNameplate)
		fnDrawShield(self, tNameplate)
		fnDrawTarget(self, tNameplate)
		
		fnDrawRewards(self, tNameplate)
	end
	
	tNameplate.eDisposition = eDisposition
end

function ForgeUI_Nameplates:OnUnitCreated(unitNew) -- build main options here
	local strNewUnitType = self:GetUnitType(unitNew)
	if not self.tSettings.tUnits[strNewUnitType] then Print(strNewUnitType) end
	if not self.tSettings.tUnits[strNewUnitType].bEnabled then return end

	local idUnit = unitNew:GetId()
	if self.arUnit2Nameplate[idUnit] ~= nil and self.arUnit2Nameplate[idUnit].wndNameplate:IsValid() then
		return
	end

	local wnd = nil
	local wndReferences = nil
	if next(self.arWindowPool) ~= nil then
		local poolEntry = table.remove(self.arWindowPool)
		wnd = poolEntry[1]
		wndReferences = poolEntry[2]
	end

	if wnd == nil or not wnd:IsValid() then
		wnd = Apollo.LoadForm(self.xmlDoc, "Nameplate", "InWorldHudStratum", self)
		wndReferences = nil
	end

	wnd:SetUnit(unitNew, 1)

	local tNameplate =
	{
		unitOwner 		= unitNew,
		idUnit 			= idUnit,
		wndNameplate	= wnd,
		strUnitType		= strNewUnitType,
		tSettings 		= self.tSettings.tUnits[strNewUnitType],
		
		bOnScreen 		= wnd:IsOnScreen(),
		bOccluded 		= wnd:IsOccluded(),
		
		bIsTarget 		= GameLib.GetTargetUnit() == unitNew,
		bIsCluster 		= false,
		bIsCasting 		= false,
		bIsMounted		= false,
		
		nVulnerableTime = 0,
		eDisposition	= unitNew:GetDispositionTo(self.unitPlayer),
		tActivation		= unitNew:GetActivationState(),
		
		bShow			= false,
	}

	tNameplate.wnd = {
		health = wnd:FindChild("Container:Health"),
		castBar = wnd:FindChild("Container:CastBar"),
		level = wnd:FindChild("Container:Health:Level"),
		wndGuild = wnd:FindChild("Guild"),
		wndName = wnd:FindChild("NameRewardContainer:Name"),
		
		nameRewardContainer = wnd:FindChild("NameRewardContainer:RewardContainer"),
		healthMaxShield = wnd:FindChild("Container:Health:HealthBars:MaxShield"),
		healthShieldFill = wnd:FindChild("Container:Health:HealthBars:MaxShield:ShieldFill"),
		healthMaxAbsorb = wnd:FindChild("Container:Health:HealthBars:MaxAbsorb"),
		healthAbsorbFill = wnd:FindChild("Container:Health:HealthBars:MaxAbsorb:AbsorbFill"),
		healthMaxHealth = wnd:FindChild("Container:Health:HealthBars:MaxHealth"),
		healthHealthFill = wnd:FindChild("Container:Health:HealthBars:MaxHealth:HealthFill"),
		healthHealthLabel = wnd:FindChild("Container:Health:HealthLabel"),
		
		castBarLabel = wnd:FindChild("Container:CastBar:Label"),
		castBarCastFill = wnd:FindChild("Container:CastBar:CastFill"),
		questRewards = wnd:FindChild("NameRewardContainer:RewardContainer:QuestRewards"),
		targetMarker = wnd:FindChild("Container:TargetMarker"),
	}

	self.arUnit2Nameplate[idUnit] = tNameplate
	self.arWnd2Nameplate[wnd:GetId()] = tNameplate

	self:UpdateNameplateRewardInfo(tNameplate)
	
	self:DrawName(tNameplate)
	self:DrawGuild(tNameplate)
	self:DrawRewards(tNameplate)
	self:DrawTarget(tNameplate)
	self:DrawHealth(tNameplate)
end

function ForgeUI_Nameplates:OnPreloadUnitCreated(unitNew)
	self.tPreloadUnits[#self.tPreloadUnits + 1] = unitNew
end

function ForgeUI_Nameplates:CreateUnitsFromPreload()
	self.unitPlayer = GameLib.GetPlayerUnit()

	-- Process units created while form was loading
	self.timerPreloadUnitCreateDelay = ApolloTimer.Create(0.5, true, "OnPreloadUnitCreateTimer", self)
	self:OnPreloadUnitCreateTimer()
end

function ForgeUI_Nameplates:OnPreloadUnitCreateTimer()
	local nCurrentTime = GameLib.GetTickCount()
	
	while #self.tPreloadUnits > 0 do
		local unit = table.remove(self.tPreloadUnits, #self.tPreloadUnits)
		if unit:IsValid() then
			self:OnUnitCreated(unit)
		end
		
		if GameLib.GetTickCount() - nCurrentTime > 250 then
			return
		end
	end
	
	self.timerPreloadUnitCreateDelay:Stop()
	self.arPreloadUnits = nil
	self.timerPreloadUnitCreateDelay = nil
end

function ForgeUI_Nameplates:OnUnitDestroyed(unitOwner)
	local idUnit = unitOwner:GetId()
	if self.arUnit2Nameplate[idUnit] == nil then
		return
	end

	local tNameplate = self.arUnit2Nameplate[idUnit]
	local wndNameplate = tNameplate.wndNameplate

	self.arWnd2Nameplate[wndNameplate:GetId()] = nil
	if #self.arWindowPool < self.tSettings.knNameplatePoolLimit then
		wndNameplate:Show(false, true)
		wndNameplate:SetUnit(nil)
		table.insert(self.arWindowPool, {wndNameplate, tNameplate.wnd})
	else
		wndNameplate:Destroy()
	end
	self.arUnit2Nameplate[idUnit] = nil
end

function ForgeUI_Nameplates:OnFrame()
	self.unitPlayer = GameLib.GetPlayerUnit()

	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		if tNameplate.bShow then
			fnDrawCastBar(self, tNameplate)
			
			if tNameplate.tSettings.bShowBars then
				fnDrawHealth(self, tNameplate)
			end
		end
	end
end

function ForgeUI_Nameplates:ColorNameplate(tNameplate) -- Every frame
	local unitOwner = tNameplate.unitOwner
	local wndNameplate = tNameplate.wndNameplate
	local tSettings = tNameplate.tSettings
	
	if tSettings == nil then Print(tNameplate.strUnitType) end
	
	local crNameColors = tSettings.crName
	local crBarColor = tSettings.crHealth
	
	if unitOwner:IsDead() then
		crNameColors = self.tSettings.crDead
	end
	
	if tSettings.bClassColors then
		crBarColor = ForgeUI.tSettings.tClassColors["cr" .. krtClassEnums[unitOwner:GetClassId()]]
	end

	tNameplate.wnd.wndName:SetTextColor(crNameColors)
	tNameplate.wnd.wndGuild:SetTextColor(crNameColors)
	tNameplate.wnd.healthHealthFill:SetBarColor(crBarColor)
end

function ForgeUI_Nameplates:DrawName(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner
	local wndName = tNameplate.wnd.wndName
	
	local bShow = self:GetBooleanOption(tNameplate.tSettings.nShowName, unitOwner)
	if wndName:IsShown() ~= bShow then
		wndName:Show(bShow, true)
	end

	if bShow then
		local strNewName
		if self.tSettings.bShowTitles then
			strNewName = unitOwner:GetTitleOrName()
		else
			strNewName = unitOwner:GetName()
		end

		if tNameplate.strName ~= strNewName then
			wndName:SetText(strNewName)
			tNameplate.strName = strNewName

			-- Need to consider guild as well for the resize code
			local strNewGuild = unitOwner:GetAffiliationName()
			if unitOwner:GetType() == "Player" and strNewGuild ~= nil and strNewGuild ~= "" then
				strNewGuild = String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), strNewGuild)
			end
		end
	end
end

function ForgeUI_Nameplates:DrawGuild(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local wndGuild = tNameplate.wnd.wndGuild
	local bShow = self:GetBooleanOption(tNameplate.tSettings.nShowGuild, unitOwner)

	local strNewGuild = unitOwner:GetAffiliationName()
	if unitOwner:GetType() == "Player" and strNewGuild ~= nil and strNewGuild ~= "" then
		strNewGuild = String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), strNewGuild)
	end

	if bShow and strNewGuild ~= wndGuild:GetText() then
		wndGuild:SetTextRaw(strNewGuild)

		-- Need to consider name as well for the resize code
		local strNewName
		if self.bShowTitle then
			strNewName = unitOwner:GetTitleOrName()
		else
			strNewName = unitOwner:GetName()
		end
	end

	wndGuild:Show(bShow and strNewGuild ~= nil and strNewGuild ~= "", true)
	wndNameplate:ArrangeChildrenVert(2) -- Must be run if bShow is false as well
end

function ForgeUI_Nameplates:DrawHealth(tNameplate)
	local unitOwner = tNameplate.unitOwner

	local nHealth = unitOwner:GetHealth()
	local nMaxHealth = unitOwner:GetMaxHealth()
	
	local bShow = nHealth ~= nil and not unitOwner:IsDead() and nMaxHealth > 0 and self:GetBooleanOption(tNameplate.tSettings.nShowBars, unitOwner)
	
	if bShow then
		self:SetBarValue(tNameplate.wnd.healthHealthFill, 0, nHealth, nMaxHealth)
		
		fnDrawShield(self, tNameplate)
		fnDrawAbsorb(self, tNameplate)
	end
	
	if bShow ~= tNameplate.wnd.health:IsShown() then
		tNameplate.wnd.health:Show(bShow, true)
	end
end

function ForgeUI_Nameplates:DrawShield(tNameplate)
	local unitOwner = tNameplate.unitOwner
	
	local nShield = unitOwner:GetShieldCapacity()
	local nShieldMax = unitOwner:GetShieldCapacityMax()
	
	local bShow = nShield ~= nil and not unitOwner:IsDead() and nShield > 0
	
	if bShow then
		self:SetBarValue(tNameplate.wnd.healthShieldFill, 0, nShield, nShieldMax)
	end
	
	if bShow ~= tNameplate.wnd.healthMaxShield:IsShown() then
		tNameplate.wnd.healthMaxShield:Show(bShow, true)
		tNameplate.bShowShield = bShow
	end
end

function ForgeUI_Nameplates:DrawAbsorb(tNameplate)
	local unitOwner = tNameplate.unitOwner
	
	local nAbsorb = unitOwner:GetAbsorptionValue()
	local nAbsorbMax = unitOwner:GetAbsorptionMax()
	
	local bShow = nAbsorb ~= nil and not unitOwner:IsDead() and nAbsorb > 0
	
	if bShow then
		self:SetBarValue(tNameplate.wnd.healthAbsorbFill, 0, nAbsorb, nAbsorbMax)
	end
	
	if bShow ~= tNameplate.wnd.healthMaxAbsorb:IsShown() then
		tNameplate.wnd.healthMaxAbsorb:Show(bShow, true)
		tNameplate.bShowAbsorb = bShow
	end
end

function ForgeUI_Nameplates:DrawCastBar(tNameplate) -- Every frame
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	-- Casting; has some onDraw parameters we need to check
	tNameplate.bIsCasting = unitOwner:ShouldShowCastBar()

	local bShow = tNameplate.bIsCasting and self:GetBooleanOption(tNameplate.tSettings.nShowCast, unitOwner)

	local wndCastBar = tNameplate.wnd.castBar
	if bShow ~= wndCastBar:IsShown() then
		wndCastBar:Show(bShow)
	end
	
	if bShow then
		local strCastName = unitOwner:GetCastName()
		if strCastName ~= tNameplate.strCastName then
			tNameplate.wnd.castBarLabel:SetText(strCastName)
			tNameplate.strCastName = strCastName
		end
		
		local nCastDuration = unitOwner:GetCastDuration()
		if nCastDuration ~= tNameplate.nCastDuration then
			tNameplate.wnd.castBarCastFill:SetMax(nCastDuration)
			tNameplate.nCastDuration = nCastDuration
		end
		
		local nCastElapsed = unitOwner:GetCastElapsed()
		if nCastElapsed ~= tNameplate.nCastElapsed then
			tNameplate.wnd.castBarCastFill:SetProgress(nCastElapsed)
			tNameplate.nCastElapsed = nCastElapsed
		end
	end
end

function ForgeUI_Nameplates:DrawRewards(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local bUseTarget = tNameplate.bIsTarget
	local bShow = self.bShowRewardsMain
	if bUseTarget then
		bShow = self.bShowRewardsTarget
	end

	if bShow ~= tNameplate.wnd.questRewards:IsShown() then
		tNameplate.wnd.questRewards:Show(bShow)
	end
	
	local tRewardsData = tNameplate.wnd.questRewards:GetData()
	if bShow and tRewardsData ~= nil and tRewardsData.nIcons ~= nil and tRewardsData.nIcons > 0 and tNameplate.nHalfNameWidth ~= nil then
		local wndnameRewardContainer = tNameplate.wnd.nameRewardContainer
		local nLeft, nTop, nRight, nBottom = wndnameRewardContainer:GetAnchorOffsets()
		wndnameRewardContainer:SetAnchorOffsets(tNameplate.nHalfNameWidth, nTop, tNameplate.nHalfNameWidth + wndnameRewardContainer:ArrangeChildrenHorz(0), nBottom)
	end
end

function ForgeUI_Nameplates:DrawTarget(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local bUseTarget = tNameplate.bIsTarget

	local bShowTargetMarker = bUseTarget and self.tSettings.tUnits["Target"].bShowMarker and tNameplate.wnd.health:IsShown()
	if tNameplate.wnd.targetMarker:IsShown() ~= bShowTargetMarker then
		tNameplate.wnd.targetMarker:Show(bShowTargetMarker)
	end
end

function ForgeUI_Nameplates:CheckDrawDistance(tNameplate)
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner

	if not unitOwner or not unitPlayer then
	    return false
	end

	local tPosTarget = unitOwner:GetPosition()
	local tPosPlayer = unitPlayer:GetPosition()

	if tPosTarget == nil or tPosPlayer == nil then
		return
	end

	local nDeltaX = tPosTarget.x - tPosPlayer.x
	local nDeltaY = tPosTarget.y - tPosPlayer.y
	local nDeltaZ = tPosTarget.z - tPosPlayer.z

	local nDistance = (nDeltaX * nDeltaX) + (nDeltaY * nDeltaY) + (nDeltaZ * nDeltaZ)

	if tNameplate.bIsTarget or tNameplate.bIsCluster then
		bInRange = nDistance < self.tSettings.knTargetRange
		return bInRange
	else
		bInRange = nDistance < self.tSettings.nMaxRange * self.tSettings.nMaxRange
		return bInRange
	end
end

function ForgeUI_Nameplates:HelperVerifyVisibilityOptions(tNameplate)
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	
	local bDontShowNameplate = (not unitOwner:ShouldShowNamePlate() and not tNameplate.bIsTarget)
		or ((self.tSettings.bUseOcclusion and tNameplate.bOccluded) or not tNameplate.bOnScreen)
		or tNameplate.bGibbed
	
	if bDontShowNameplate then
		return false
	end
	
	local eDisposition = tNameplate.eDisposition
	local tActivation = tNameplate.tActivation

	-- if you stare into the abyss the abyss stares back into you
	local bShowNameplate = not tNameplate.bOccluded

	if self.tSettings.bShowMainObjectiveOnly and not bShowNameplate then
		local tRewardInfo = unitOwner:GetRewardInfo() or {}
		for idx, tReward in pairs(tRewardInfo) do
			if tReward.eType == Unit.CodeEnumRewardInfoType.Quest or tReward.eType == Unit.CodeEnumRewardInfoType.Contract then
				bShowNameplate = true
				break
			end
		end
	end

	return bShowNameplate
end

function ForgeUI_Nameplates:HelperFormatBigNumber(nArg)
	if nArg < 1000 then
		strResult = tostring(nArg)
	elseif nArg < 1000000 then
		if math.floor(nArg%1000/100) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberWhole"), math.floor(nArg / 1000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberFloat"), nArg / 1000)
		end
	elseif nArg < 1000000000 then
		if math.floor(nArg%1000000/100000) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_MillionsNumberWhole"), math.floor(nArg / 1000000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_MillionsNumberFloat"), nArg / 1000000)
		end
	elseif nArg < 1000000000000 then
		if math.floor(nArg%1000000/100000) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_BillionsNumberWhole"), math.floor(nArg / 1000000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_BillionsNumberFloat"), nArg / 1000000)
		end
	else
		strResult = tostring(nArg)
	end
	return strResult
end

function ForgeUI_Nameplates:SetBarValue(wndBar, fMin, fValue, fMax)
	wndBar:SetMax(fMax)
	wndBar:SetFloor(fMin)
	wndBar:SetProgress(fValue)
end

-----------------------------------------------------------------------------------------------
-- Helper functions
-----------------------------------------------------------------------------------------------

function ForgeUI_Nameplates:GetUnitType(unit)
	if unit == nil or not unit:IsValid() then return end

	local eDisposition = unit:GetDispositionTo(self.unitPlayer)
	
	if unit:IsThePlayer() then
		return "Player"
	elseif unit:GetType() == "Player" then
		if eDisposition == 0 then
			return "HostilePlayer"
		else
			if unit:IsInYourGroup() then
				return "PartyPlayer"
			else
				return "FriendlyPlayer"
			end
		end
	elseif unit:GetType() == "Collectible" then
		return "Collectible"
	elseif unit:GetType() == "PinataLoot" then
		return "PinataLoot"
	elseif unit:GetType() == "Pet" then
		local petOwner = unit:GetUnitOwner()
	
		if eDisposition == 0 then
			return "HostilePet"
		elseif petOwner ~= nil and petOwner:IsThePlayer() then
			return "PlayerPet"
		else
			return "FriendlyPet"
		end
	elseif unit:GetType() == "Mount" then
		return "Mount"
	elseif unit:GetType() == "Pickup" then
		if string.match(unit:GetName(), self.unitPlayer:GetName()) then
			return "Pickup"
		end
		return "PickupNotPlayer"
	elseif unit:GetHealth() == nil and not unit:IsDead() then
		if unit:GetActivationState().InstancePortal then
			return "Simple"
		else
			return "Simple"
		end
	else
		if eDisposition == 0 then
			return "HostileNPC"
		elseif eDisposition == 1 then
			return "NeutralNPC"
		elseif eDisposition == 2 then
			return "FriendlyNPC"
		elseif eDisposition == 3 then
			return "UnknownNPC"
		end
	end
end

function ForgeUI_Nameplates:GetBooleanOption(nOption, unit)
	if nOption == 0 then
		return false
	elseif nOption == 1 then
		if not unit:IsInCombat() then
			return true
		else
			return false
		end
	elseif nOption == 2 then
		if unit:IsInCombat() or unit:GetHealth() ~= unit:GetMaxHealth() then
			return true
		else
			return false
		end
	elseif nOption == 3 then
		return true
	end
end

-----------------------------------------------------------------------------------------------
-- Nameplate Events
-----------------------------------------------------------------------------------------------

function ForgeUI_Nameplates:OnNameplateNameClick(wndHandler, wndCtrl, eMouseButton)
	local tNameplate = self.arWnd2Nameplate[wndHandler:GetId()]
	if tNameplate == nil then
		return
	end

	local unitOwner = tNameplate.unitOwner
	if GameLib.GetTargetUnit() ~= unitOwner and eMouseButton == GameLib.CodeEnumInputMouse.Left then
		GameLib.SetTargetUnit(unitOwner)
	end
end

function ForgeUI_Nameplates:OnWorldLocationOnScreen(wndHandler, wndControl, bOnScreen)
	local tNameplate = self.arWnd2Nameplate[wndHandler:GetId()]
	if tNameplate ~= nil then
		tNameplate.bOnScreen = bOnScreen
		self:UpdateNameplateVisibility(tNameplate)
	end
end

function ForgeUI_Nameplates:OnUnitOcclusionChanged(wndHandler, wndControl, bOccluded)
	local tNameplate = self.arWnd2Nameplate[wndHandler:GetId()]
	if tNameplate ~= nil then
		tNameplate.bOccluded = bOccluded
		self:UpdateNameplateVisibility(tNameplate)
	end
end

-----------------------------------------------------------------------------------------------
-- System Events
-----------------------------------------------------------------------------------------------

function ForgeUI_Nameplates:OnEnteredCombat(unitChecked, bInCombat)
	if unitChecked == self.unitPlayer then
		self.bPlayerInCombat = bInCombat
	end
	
	local tNameplate = self.arUnit2Nameplate[unitChecked:GetId()]
	if tNameplate ~= nil then
		self:DrawName(tNameplate)
	end
end

function ForgeUI_Nameplates:OnUnitGibbed(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		tNameplate.bGibbed = true
		self:UpdateNameplateVisibility(tNameplate)
	end
end

function ForgeUI_Nameplates:OnUnitNameChanged(unitUpdated, strNewName)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		self:DrawName(tNameplate)
	end
end

function ForgeUI_Nameplates:OnUnitTitleChanged(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		self:DrawName(tNameplate)
	end
end

function ForgeUI_Nameplates:OnPlayerTitleChanged()
	local tNameplate = self.arUnit2Nameplate[self.unitPlayer:GetId()]
	if tNameplate ~= nil then
		self:DrawName(tNameplate)
	end
end

function ForgeUI_Nameplates:OnGuildChange()
	self.guildDisplayed = nil
	self.guildWarParty = nil
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		local eGuildType = guildCurr:GetType()
		if eGuildType == GuildLib.GuildType_Guild then
			self.guildDisplayed = guildCurr
		end
		if eGuildType == GuildLib.GuildType_WarParty then
			self.guildWarParty = guildCurr
		end
	end

	for key, tNameplate in pairs(self.arUnit2Nameplate) do
		local unitOwner = tNameplate.unitOwner
		tNameplate.bIsGuildMember = self.guildDisplayed and self.guildDisplayed:IsUnitMember(unitOwner) or false
		tNameplate.bIsWarPartyMember = self.guildWarParty and self.guildWarParty:IsUnitMember(unitOwner) or false
	end
end

function ForgeUI_Nameplates:OnUnitGuildNameplateChanged(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		self:DrawGuild(tNameplate)
	end
end

function ForgeUI_Nameplates:OnUnitMemberOfGuildChange(unitOwner)
	local tNameplate = self.arUnit2Nameplate[unitOwner:GetId()]
	if tNameplate ~= nil then
		self:DrawGuild(tNameplate)
		tNameplate.bIsGuildMember = self.guildDisplayed and self.guildDisplayed:IsUnitMember(unitOwner) or false
		tNameplate.bIsWarPartyMember = self.guildWarParty and self.guildWarParty:IsUnitMember(unitOwner) or false
	end
end

function ForgeUI_Nameplates:OnTargetUnitChanged(unitOwner) -- build targeted options here; we get this event when a creature attacks, too
	for idx, tNameplateOther in pairs(self.arUnit2Nameplate) do
		local bIsTarget = tNameplateOther.bIsTarget
		local bIsCluster = tNameplateOther.bIsCluster

		tNameplateOther.bIsTarget = false
		tNameplateOther.bIsCluster = false

		if bIsTarget or bIsCluster then
			self:DrawHealth(tNameplateOther)
			self:DrawName(tNameplateOther)
			self:DrawGuild(tNameplateOther)
			self:UpdateNameplateRewardInfo(tNameplateOther)
			self:DrawTarget(tNameplateOther)
		end
	end

	if unitOwner == nil then
		return
	end
	
	local tNameplate = self.arUnit2Nameplate[unitOwner:GetId()]
	if tNameplate == nil then
		return
	end

	if GameLib.GetTargetUnit() == unitOwner then
		tNameplate.bIsTarget = true
		self:DrawHealth(tNameplate)
		self:DrawName(tNameplate)
		self:DrawGuild(tNameplate)
		self:DrawTarget(tNameplate)
		self:UpdateNameplateRewardInfo(tNameplate)

		local tCluster = unitOwner:GetClusterUnits()
		if tCluster ~= nil then
			tNameplate.bIsCluster = true

			for idx, unitCluster in pairs(tCluster) do
				local tNameplateOther = self.arUnit2Nameplate[unitCluster:GetId()]
				if tNameplateOther ~= nil then
					tNameplateOther.bIsCluster = true
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Local function reference assignments
-----------------------------------------------------------------------------------------------
fnDrawName = ForgeUI_Nameplates.DrawName
fnDrawHealth = ForgeUI_Nameplates.DrawHealth
fnDrawShield = ForgeUI_Nameplates.DrawShield
fnDrawAbsorb = ForgeUI_Nameplates.DrawAbsorb

fnDrawRewards = ForgeUI_Nameplates.DrawRewards
fnDrawCastBar = ForgeUI_Nameplates.DrawCastBar
fnColorNameplate = ForgeUI_Nameplates.ColorNameplate
fnDrawTarget = ForgeUI_Nameplates.DrawTarget

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_NameplatesInst = ForgeUI_Nameplates:new()
ForgeUI_NameplatesInst:Init()
