local gs=LibStub("GuiSkin-1.0");
local A=LibStub("AceAddon-3.0"):GetAddon("DKP Manager");
local B=LibStub("AceAddon-3.0"):GetAddon("DKP Bidder");
local DKPlog=A.log;
function A:CreateGUI()
    
    local v=B.view;
    v.logFrame=B:CreateLogFrame();
    v.adminFrame=CreateFrame("Frame",B.mainFrame:GetName().."_adminFrame",UIParent);
    local f=v.adminFrame;
    f:SetWidth(B.mainFrame:GetWidth()-40);
    f:SetHeight(200);
    
    if B.mainFrame:IsVisible() then
        f:Show()
    else
        f:Hide()
    end
    --B.mainFrame:SetParent(f);
    local func = B.mainFrame:GetScript("OnHide")
    B.mainFrame:SetScript("OnHide",function(self) func(self); f:Hide() end)
    func = B.mainFrame:GetScript("OnShow")
    B.mainFrame:SetScript("OnShow",function(self) func(self); f:Show() end)
    
    
    B.mainFrame:SetFrameLevel(f:GetFrameLevel()+1);
    f:SetBackdrop( {
        bgFile =[[Interface\FrameGeneral\UI-Background-Rock]],
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        atileSize = 32,
        edgeSize =32,
        insets = { left=11,right=11, top=12, bottom=10}
    })
    
    f.view={};
    local v=f.view;
    local name=f:GetName();
    
    
    --titleframe and text
    v.titleFrame = CreateFrame("Frame",name.."_titleFrame",f)
    
    
    v.titleString=v.titleFrame:CreateFontString(name.."_title","ARTWORK","GameFontNormal");
    v.titleString:SetPoint("TOP",v.titleFrame,"TOP",18,-14);
    v.titleString:SetText("Bossul DKP-ului");
    
    v.titleString:SetFont([[Fonts\MORPHEUS.ttf]],14);
    v.titleString:SetTextColor(1,1,1,1);--shadow??
    v.titleFrame:SetScript("OnEnter",function()
        v.titleString:SetTextColor(1,1,0.3,1);
        
        
    end)
    v.titleFrame:SetScript("OnLeave",function()
        v.titleString:SetTextColor(1,1,1,1);
        
        
    end)
    
    v.optionsButton = CreateFrame("Button", nil, f)
    v.optionsButton:SetFrameLevel(10)
    --v.optionsButton:ClearAllPoints()
    v.optionsButton:SetHeight(20)
    v.optionsButton:SetWidth(20)
    v.optionsButton:SetNormalTexture("Interface\\Addons\\DKP-Manager\\arts\\icon-config")
    v.optionsButton:SetHighlightTexture("Interface\\Addons\\DKP-Manager\\arts\\icon-config", 0.2)
    v.optionsButton:SetAlpha(0.8)
    v.optionsButton:SetPoint("TOPLEFT", v.titleString, "TOPRIGHT", 5, 2);
    v.optionsButton:Show()
    v.optionsButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    v.optionsButton:SetScript("OnClick", function()
        LibStub("AceConfigDialog-3.0"):Open("DKP Manager");
    end)
    
    v.titleFrame:SetHeight(40)
    v.titleFrame:SetWidth(f:GetWidth()/3);
    
    
    
    
    v.titleString:SetPoint("TOP", f, "BOTTOM", 0,10);
    v.titleFrame:SetPoint("TOP",v.titleString, "TOP", 0, 12);
    v.titleFrame:SetMovable(true)
    v.titleFrame:EnableMouse(true)
    f.hidden=true;
    f:SetPoint('BOTTOM', B.mainFrame,'BOTTOM', 0,-20);
    v.titleFrame:SetScript("OnMouseDown",function()
        if not f.hidden then
            f:ClearAllPoints()
            f:SetPoint('BOTTOM', B.mainFrame,'BOTTOM', 0,-20);
            
            f.hidden=true
            --print("1");
        else
            --print("2");
            f:ClearAllPoints()
            f:SetPoint('bottom', B.mainFrame,'BOTTOM', 0,-100);
            --print("3");
            f.hidden=false
        end
        
    end)
    
    v.titleFrame:SetScript("OnMouseUp",function()
        --f:StopMovingOrSizing()
    end)
    v.titleFrame.texture=gs.CreateTexture(v.titleFrame,name.."_titleFrameTexture","ARTWORK",300,68,"TOP", v.titleFrame, "TOP", 0,2,[[Interface\DialogFrame\UI-DialogBox-Header]]);
    --- end of title frame
    
    
    v.itemLinkString=gs.CreateFontString(f,name.."_itemLinkString","ARTWORK","Item: ","BOTTOMLEFT",f,"BOTTOMLEFT",20,34);
    
    v.itemLinkEditBox = CreateFrame("EditBox", name.."_itemLinkEditBox", f, "InputBoxTemplate")
    
    v.itemLinkEditBox:SetPoint('LEFT', v.itemLinkString,'RIGHT',10 ,0)
    v.itemLinkEditBox:Show();
    v.itemLinkEditBox:Disable();
    v.itemLinkEditBox:SetAutoFocus(false);
    
    v.itemLinkEditBox:SetWidth(140);
    v.itemLinkEditBox:SetHeight(20);
    v.tooltipFrameHelp = CreateFrame("Frame",nil,f)
    v.itemLinkEditBox:SetScript("OnEnter", function(self)
        v.tooltipFrameHelp:SetScript("OnUpdate", 	function()
            A:ShowGameTooltip();
        end)
    end)
    v.itemLinkEditBox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        v.tooltipFrameHelp:SetScript("OnUpdate", 	function()
            -- Dont do anything
        end)
    end)
    
    
    --Award bid Button
    v.awardButton = CreateFrame("Button", name.."_awardButton", f, "UIPanelButtonTemplate")
    local b=v.awardButton;
    b:SetText("Award player");
    b:SetPoint('bottom', f,"bottom", 0,55)
    b:SetScript("OnClick",function(self)
        --A:StopBids();
        A:AwardPlayer();
    end)
    b:SetHeight(20);
    b:SetWidth(150);
    b:Disable();
    --//Bid Button
    
    
    --Start/stop bid Button
    v.startStopButton = CreateFrame("Button", name.."_startStopBidButton", f, "UIPanelButtonTemplate")
    v.startStopButton:SetText("Start  bidding");
    v.startStopButton:SetPoint('bottom', v.awardButton,"top", 0,3)
    v.startStopButton:SetScript("OnClick",function(self)
        --B:Bid(v.bidEditBox:GetNumber());\
        if not A.biddingInProgress then
            A:StartBids(v.itemLinkEditBox:GetText());
        else
            A:StopBids();
        end;
        
    end)
    v.startStopButton:SetHeight(20);
    v.startStopButton:SetWidth(150);
    v.startStopButton:Disable();
    --//Bid Button
    
    self:CreateBidButtons()
end
function A:CreateBidButtons()
    for i=1,4 do
        B.view["lootButton"..i]= CreateFrame("Button", "DKPLootButton"..i, _G["LootButton"..i], "UIPanelButtonTemplate")
        local b =B.view["lootButton"..i];
        b:SetText("Bid");
        b:SetPoint('top', "LootButton"..i,"top", 0,0);
        b:SetPoint('bottom', "LootButton"..i,"bottom", 0,0);
        b:SetPoint('right', "LootButton"..i,"left", 0,0);
        b:SetWidth(34);
        b.id=i;
        b:SetScript("OnClick",function(self)
            --B:Bid(v.bidEditBox:GetNumber());\
            --if not A.biddingInProgress then
            
            A:StartBids(GetLootSlotLink(_G["LootButton"..tostring(i)].slot));
            --else
            --	A:StopBids();
            --end;
            
        end)
        b:Hide();
    end;
end

function A:ShowGameTooltip()
    local v=B.view.adminFrame.view;
    GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("bottom",v.itemLinkEditBox, "top", 0, 0)
    GameTooltip:ClearLines()
    
    if v.itemLinkEditBox:GetText()~="" then
        GameTooltip:SetHyperlink(v.itemLinkEditBox:GetText())
    end
end

function B:CreateLogFrame()
    --if GetNumGuildMembers()>0 then
    local f=gs:CreateFrame(self.ver.."_LogFrame","DKP Log","BASIC",690,355,'TOPLEFT',self.view.rosterFrame,'BOTTOMLEFT',0 ,-50);
    f:Hide();
    f:SetScript("OnShow",
    function(self)
        PlaySound("igCharacterInfoOpen");
    end)
    f:SetScript("OnHide",
    function(self)
        PlaySound("igCharacterInfoClose");
    end)
    
    local v=f.view;
    
    local data={columns={"Date","Name","Change","Amount","Reason","Zone","Logger name"},columnsWidth={130,90,55,55,150,90,90},rows=20,height=290};
    
    v.logList=LibStub("WowList-1.0"):CreateNew(self:GetName().."_logList",data,f);
    v.logList:SetPoint('TOPLEFT', f,'TOPLEFT', 16,-30);
    v.logList:SetColumnSortFunction(1,function(a,b) return a>b end)
    v.logList:SetColumnDisplayFunction(1,function(t)
        local total=math.floor(t/86400)%26+1;
        local r=total%3
        local gt=(total-total%3)/3
        local g=gt%3
        local b=(gt-gt%3)/3%3;
        return date("%d.%m.%y %H:%M:%S",t),{r/2,g/2,b/2,1}
    end)
    
    v.logList:SetColumnSortFunction(2,function(a,b) return a>b end)
    v.logList:SetColumnSortFunction(3,function(a,b) return a>b end)
    v.logList:SetColumnSortFunction(4,function(a,b) return a>b end)
    v.logList:SetColumnSortFunction(5,function(a,b) return a>b end)
    v.logList:SetColumnSortFunction(6,function(a,b) return a>b end)
    v.logList:SetColumnSortFunction(7,function(a,b) return a>b end)
    v.logList:SetMultiSelection(false);
    function f:SelectionChanged(arg1,arg2)
        if f:IsVisible() then
            self:UpdateList();
        end;
    end
    
    
    B.view.rosterFrame.view.bidderList.RegisterCallback(f, "SelectionChanged");
    
    
    function f:UpdateList()
        
        if B.view.rosterFrame.view.bidderList:GetLastSelected()~=nil then
            local main=B.view.rosterFrame.view.bidderList:GetLastSelected()[1].data.main;
            
            self.view.titleString:SetText("DKP Log: "..main);
            if DKPlog:GetLog(main)~=nil then
                for i,v in pairs(DKPlog:GetLog(main)) do
                    v.isSelected=nil
                end
                
                
                local lookup_table = {}
                local function _copy(object)
                    if type(object) ~= "table" then
                        return object
                    elseif lookup_table[object] then
                        return lookup_table[object]
                    end
                    local new_table = {}
                    lookup_table[object] = new_table
                    for index, value in pairs(object) do
                        new_table[_copy(index)] = _copy(value)
                    end
                    return setmetatable(new_table, getmetatable(object))
                end
                self.view.logList:SetData(_copy(DKPlog:GetLog(main)));
                
                self.view.logList:UpdateView();
            else
                
                self.view.logList:SetData({});
                self.view.logList:UpdateView();
            end;
        end
    end;
    --f:UpdateList()
    return f;
    --end;
    
end;
