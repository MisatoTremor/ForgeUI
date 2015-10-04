-----------------------------------------------------------------------------------------------
-- Client Lua Script for ForgeUI
--
-- name: 		taxi.lua
-- author:		Winty Badass@Jabbit
-- about:		ForgeUI skin for Carbine's TaxiMapdon
-----------------------------------------------------------------------------------------------

local F = _G["ForgeLibs"]["ForgeUI"] -- ForgeUI API
local Skins = F:API_GetModule("skins")

local fnUseSkin

local function LoadSkin()
	local addon = Apollo.GetAddon("TaxiMap")
	
	F:PostHook(addon, "OnDocumentReady", fnUseSkin)
	
	fnUseSkin(addon)
end

fnUseSkin = function(luaCaller)
	if not luaCaller.wndMain and not bRun then return end
	
	Skins:HandleFrame(luaCaller.wndMain)
	
	luaCaller.wndMain:FindChild("MainFrame"):SetStyle("Border", false)
	
	-- workaround for carbin's stupid name system
	luaCaller.wndMain:FindChild("Title"):SetName("TitleOuter")
	luaCaller.wndMain:FindChild("Title"):SetTextColor("FFFF0000")
	luaCaller.wndMain:FindChild("Title"):SetFont("Nameplates")
	luaCaller.wndMain:FindChild("TitleOuter"):SetName("Title")
	
	Skins:HandleTitle(luaCaller.wndMain:FindChild("Title"))
	
	Skins:HandleFooter(luaCaller.wndMain:FindChild("MetalFooter"))
	
	luaCaller.wndMain:FindChild("BGArt"):SetSprite("ForgeUI_InnerWindow")
	luaCaller.wndMain:FindChild("BGArt"):SetStyle("Picture", true)
	luaCaller.wndMain:FindChild("BGArt"):SetBGColor("FFFFFFFF")
	luaCaller.wndMain:FindChild("BGArt"):SetAnchorOffsets(5, 30, -5, -35)
	
	luaCaller.wndMain:FindChild("BG_Backer"):Show(false)
	
	luaCaller.wndMain:FindChild("MapContainer"):SetAnchorOffsets(1, 1, -1, -1)
	
	Skins:HandleButton(luaCaller.wndMain:FindChild("CancelButton"))
	luaCaller.wndMain:FindChild("CancelButton"):SetAnchorOffsets(-100, -25, 0, 0)
	
	Skins:HandleCloseButton(luaCaller.wndMain:FindChild("CloseButton"))	
end

Skins:NewCarbineSkin("TaxiMap", LoadSkin)
