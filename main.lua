DKPmanager = LibStub("AceAddon-3.0"):NewAddon("DKP Manager","AceComm-3.0","AceTimer-3.0","AceEvent-3.0","AceHook-3.0","AceSerializer-3.0");
local Log=LibStub("DKPlog-1.0");
local B=LibStub("AceAddon-3.0"):GetAddon("DKP Bidder");
local GRI=LibStub("GuildRosterInfo-1.0");

DKPmanagerDB={};
local A=DKPmanager;
local DB=DKPmanagerDB;
A.ver="70300.0.0";
A.log=Log;
A.prefix="dkp_manager";
DB.log={};
A.bidTable={};
DB.biddingType="sh";
DB.minBid=0;
DB.zeroSum=true;
DB.broadcastBidderUpdate=false;
DB.silenceBidding=true;


A.isInRaidGroup=false;


-----------------------------
-------/------------
-------------------------------

function A:GROUP_ROSTER_UPDATE()
    
    if not UnitInRaid("player") then
        if A.biddingInProgress then
            self:Print("Ending bidding becouse you left the raid group");
            self:StopBids();
        end;
        self.isInRaidGroup=false;
        B.view.adminFrame.view.startStopButton:Disable();
    elseif not self.isInRaidGroup then
        self.isInRaidGroup=true;
        
        B.view.adminFrame.view.startStopButton:Enable();
    end
    
    
end
function A:OnInitialize()
    self:CreateGUI();
    self:RegisterEvent("LOOT_OPENED");
    self:RegisterEvent("GROUP_ROSTER_UPDATE");
    A.log:RegisterCallback("ActionComplete",self.SendChanges,self);
    A.log:RegisterCallback("ActionFailed",self.SendFailed,self);
    self:RegisterComm(B.prefix);
    self:RegisterComm(A.prefix);
    
    
    self:SecureHook("LootFrame_Update");
    self:SecureHook("ChatEdit_InsertLink");
    table.insert(B.dropDownMenuTable,(#B.dropDownMenuTable-1),{
        notCheckable = 1,
        disabled=1,
        text="",
    });
    table.insert(B.dropDownMenuTable,(#B.dropDownMenuTable-1),{
        text = "DKP Manager",
        isTitle = 1,
        notCheckable = 1,
    });
    table.insert(B.dropDownMenuTable,(#B.dropDownMenuTable-1),{
        text = "Increase/Reduce DKP",
        func = function()
            local v=B.view.rosterFrame.view;
            local point=v.bidderList:GetSelected();
            if point~=nil then
                local text="Type the change amount for following players: "
                local onlyMains={};
                local sep="";
                local mains={};
                for i=1,#point do
                    text=text..sep..point[i][1].data.name;
                    table.insert(mains,point[i][1].data.name);
                    sep=",";
                end
                text=text..".";
                
                if StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup"]~=nil then table.wipe(StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup"]); end;
                StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup"] = {
                    text = text,
                    whileDead = true,
                    enterClicksFirstButton=1,
                    hideOnEscape = 1,
                    hasEditBox=true,
                    button1 = "Change amounts",
                    button2 = "Cancel",
                    EditBoxOnTextChanged = function (self, data)
                        -- careful! 'self' here points to the editbox, not the dialog
                        self:GetParent().button1:Enable()          -- self:GetParent() is the dialog
                    end,
                    EditBoxOnEnterPressed = function(self) StaticPopup_OnClick(self:GetParent(), 1) end,
                    EditBoxOnEscapePressed = function(self) StaticPopup_OnClick(self:GetParent(), 2) end,
                    OnShow = function (self, data)
                        self.button1:Disable();
                    end,
                    OnAccept = function(self, data, data2)
                        local number=self.editBox:GetNumber();
                        if number then
                            
                            A:ChangeAmounts(number,mains);--/script for i=1,20 do LibStub("AceAddon-3.0"):GetAddon("DKP Bidder"):Transfer(10,{"Mogrhana"}); end
                        end
                    end,
                    timeout = 0,
                    
                }
                StaticPopup_Show("DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup");
            end
        end,
        notCheckable = 1,
    });
    table.insert(B.dropDownMenuTable,(#B.dropDownMenuTable-1),{
        text = "Set alts",
        func = function()
            local v=B.view.rosterFrame.view;
            local point=v.bidderList:GetSelected();
            local main=v.bidderList:GetLastSelected()[1].data.name;
            if point~=nil then
                local text="Following players will be marked as alts of "..main..": ";
                local sep="";
                local mains={};
                for i=1,#point do
                    if main~=point[i][1].data.name then
                        text=text..sep..point[i][1].data.name;
                        table.insert(mains,point[i][1].data.name);
                        sep=",";
                    end
                end
                text=text..".";
                
                if StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup"]~=nil then table.wipe(StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup"]); end;
                StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup"] = {
                    text = text,
                    whileDead = true,
                    enterClicksFirstButton=1,
                    hideOnEscape = 1,
                    hasEditBox=false,
                    button1 = "Accept",
                    button2 = "Cancel",
                    OnAccept = function(self, data, data2)
                        A:Print("This operation may take a few second to update data and notes, please wait.");
                        for i=1,#mains do
                            A.log:SetAlt(main,mains[i]);
                        end
                        
                    end,
                    timeout = 0,
                    
                }
                StaticPopup_Show("DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup");
            end
        end,
        notCheckable = 1,
    });
    
    table.insert(B.dropDownMenuTable,(#B.dropDownMenuTable-1),{
        text = "Set as main",
        func = function()
            local v=B.view.rosterFrame.view;
            local point=v.bidderList:GetSelected();
            if point~=nil then
                local text="Following players will be marked as mains: ";
                local sep="";
                local mains={};
                for i=1,#point do
                    text=text..sep..point[i][1].data.name;
                    table.insert(mains,point[i][1].data.name);
                    sep=",";
                end
                text=text..".";
                
                if StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup"]~=nil then table.wipe(StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup"]); end;
                StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup"] = {
                    text = text,
                    whileDead = true,
                    enterClicksFirstButton=1,
                    hideOnEscape = 1,
                    hasEditBox=false,
                    button1 = "Accept",
                    button2 = "Cancel",
                    OnAccept = function(self, data, data2)
                        A:Print("This operation may take a few second to update data and notes, please wait.");
                        for i=1,#mains do
                            A.log:SetAlt(mains[i],mains[i]);
                        end
                        
                    end,
                    timeout = 0,
                    
                }
                StaticPopup_Show("DKPBidder_TitleDropDownMenu_ChangeDKPStaticPopup");
            end
        end,
        notCheckable = 1,
    });
    table.insert(B.dropDownMenuTable,(#B.dropDownMenuTable-1),{
        text = "Show log",
        func = function() B.view.logFrame:Show(); B.view.logFrame:UpdateList() end,
        notCheckable = 1,
    });
    
end
function A:ChangeAmounts(number,mains)
    if StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPReason"]~=nil then table.wipe(StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPReason"]); end;
    StaticPopupDialogs["DKPBidder_TitleDropDownMenu_ChangeDKPReason"] = {
        text = "What reason?",
        hasEditBox=true,
        button1 = "Change amounts",
        button2 = "Cancel",
        EditBoxOnTextChanged = function (self, data)
            self:GetParent().button1:Enable()
        end,
        EditBoxOnEnterPressed = function(self) StaticPopup_OnClick(self:GetParent(), 1) end,
        EditBoxOnEscapePressed = function(self) StaticPopup_OnClick(self:GetParent(), 2) end,
        OnShow = function (self, data)
            self.mains=mains;
            self.button1:Disable();
            
        end,
        OnAccept = function(self, data, data2)
            local reason=self.editBox:GetText();
            
            for i=1,#mains do
                --print(mains[i],number,reason);
                A:AddAction(mains[i],number,reason);
            end
        end,
        timeout = 0,
        whileDead = true,
        enterClicksFirstButton=true,
        hideOnEscape = true,
    }
    StaticPopup_Show("DKPBidder_TitleDropDownMenu_ChangeDKPReason");
end

function A:SetBiddingState(bidMaster)
    local v=B.view.adminFrame.view;
    
    if bidMaster then
        
        v.startStopButton:SetText("Stop bidding");
        A.biddingInProgress=true
    else
        v.awardButton:Disable();
        v.startStopButton:SetText("Start bidding");
        A.biddingInProgress=false
    end
end

function A:ChatEdit_InsertLink(link)
    if B.view.adminFrame:IsVisible() and link:find("|Hitem") then  B.view.adminFrame.view.itemLinkEditBox:SetText(link); end;
end
A.printedItems={};
function A:LOOT_OPENED()
    
    local method, partyMaster, raidMaster = GetLootMethod()
    local guid=UnitGUID("target")
    local target=UnitName("target");
    if raidMaster~=nil and GetRaidRosterInfo(raidMaster)==UnitName("player") and UnitInRaid("player") then
        if not A.printedItems[guid] then
            if guid then A.printedItems[guid]=true;
            else
                target="container";
                if GetRealZoneText()=="Firelands" then
                    target="Ragnaros"
                end;
            end;
            local n=0;
            for i=1,GetNumLootItems() do
                if LootSlotHasItem(i) then
                    local texture, item, quantity, quality, locked = GetLootSlotInfo(i)
                    if quality>=GetLootThreshold() then
                        n=n+1;
                    end;
                end;
            end;
            
            if n>0 then
                SendChatMessage("<DKP-Manager> ".."Items dropped by "..target..":","RAID");
                for i=1,GetNumLootItems() do
                    
                    if LootSlotHasItem(i) then
                        local texture, item, quantity, quality, locked = GetLootSlotInfo(i)
                        if quality>=GetLootThreshold() then
                            --print("getlootslotinfo",texture, item, quantity, quality, locked );
                            SendChatMessage("<DKP-Manager> ".."* "..GetLootSlotLink(i),"RAID");
                        end;
                    end;
                    --print("loot threshold",GetLootThreshold());
                end;
            end;
        end;
        self:LootFrame_Update()
    else
        for i=1,4 do B.view["lootButton"..i]:Hide(); end--TODO does this have to be called everytimne on loot opened? :/
    end;
    
end
function A:LootFrame_Update()
    for i=1,4 do
        local lootB=_G["LootButton"..tostring(i)]
        --print(lootB.quality);
        if lootB.quality and LootSlotHasItem(i) and lootB.quality>=GetLootThreshold() then
            B.view["lootButton"..i]:Show()
        else
            B.view["lootButton"..i]:Hide()
        end
    end
end


function A:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(B.colors["grey"].."DKP - |r|CFF2459FFManager"..B.colors["grey"].."> "..B.colors["close"]..msg);
end


local function awardDKPtoRaid(amount,boss)
    local method, partyMaster, raidMaster = GetLootMethod()
    if method=="master"and GetRaidRosterInfo(raidMaster)==UnitName("player") then
        for i=1, MAX_RAID_MEMBERS do
            name=GetRaidRosterInfo(i);
            if GRI:IsOnList(name) then
                A:AddAction(name,tonumber(amount),"Award for killing "..boss);
            end;
        end;
    else
        if StaticPopupDialogs["DKPBidder_AwardDKPAfterBossKill"]~=nil then table.wipe(StaticPopupDialogs["DKPBidder_AwardDKPAfterBossKill"]); end;
        StaticPopupDialogs["DKPBidder_AwardDKPAfterBossKill"] = {
            text = "Award raid members with "..amount.." dkp for killing "..boss.."?",
            whileDead = true,
            enterClicksFirstButton=1,
            hideOnEscape = 1,
            hasEditBox=false,
            button1 = "Accept",
            button2 = "Cancel",
            OnAccept = function(self, data, data2)
                for i=1, MAX_RAID_MEMBERS do
                    name=GetRaidRosterInfo(i);
                    if GRI:IsOnList(name) then
                        A:AddAction(name,tonumber(amount),"Award for killing "..boss);
                    end;
                end;
                
            end,
            timeout = 0,
            
        }
        StaticPopup_Show("DKPBidder_AwardDKPAfterBossKill");
    end;
end

function A.BossKill(event,mod) --/script DKPmanager.BossKill("kill",{combatInfo={name="Ultraxion"}})
    local boss=mod.combatInfo.name;
    
    if DB.bossesDKP.enabled and DB.bossesDKP.bosses[boss]then
        
        local difficulties={"10-man normal","25-man normal","10-man heroic","25-man heroic"};
        
        local difficulty=difficulties[GetRaidDifficultyID()-2]
        local amount=-1;
        
        A.Print(A,"Boss killed! "..boss);
        if DB.bossesDKP.bosses[boss].patch.perpatch then --per patch!
            
            amount= DB.bossesDKP.bosses[boss].patch[difficulty].dkp;
            --A.Print(A,"setting per patch! "..amount);
        else -- per instance?
            if DB.bossesDKP.bosses[boss].instance[difficulty].perinstance then
                amount =DB.bossesDKP.bosses[boss].instance[difficulty].dkp;
                --A.Print(A,"setting per instance! "..amount);
            else
                amount=DB.bossesDKP.bosses[boss].instance[difficulty].dkpPerBoss[boss];
                --A.Print(A,"setting per boss! "..amount);
            end
            
        end
        awardDKPtoRaid(amount,boss);
        
    end
    
    
    --printTable(mod.combatInfo);
end
local function addBossEncounter(patch,instance,bosses)
    
    if DB.bossesDKP.enabled==nil then DB.bossesDKP.enabled=false; end;
    
    local bossEncOptions={
        name="Award dkp points per boss kill",
        type="toggle",
        order=0,
        desc="Turn this feature on to set the dkp amounts given for boss kills.",
        set = function(info,val)
            DB.bossesDKP.enabled = val;
            A.optionsTable.args.autoBossAwards=val and DB.bossesDKP.optEnabled or DB.bossesDKP.optDisabled;
            --insTypes[name] = val and DB.bossesDKP.instance[instance][name].optPerInstance or DB.bossesDKP.instance[instance][name].optPerBoss;
            
        end,
        get = function(info) return DB.bossesDKP.enabled end,
    }
    if DB.bossesDKP.optEnabled==nil then
        DB.bossesDKP.optEnabled= {
            name="Auto boss award",
            type="group",
            order=100,
            args={
                bossEncOptions=bossEncOptions,
            },
        };
        DB.bossesDKP.optDisabled= {
            name="Auto boss award",
            type="group",
            order=100,
            args={
                bossEncOptions=bossEncOptions,
            },
        };
    else
        DB.bossesDKP.optDisabled.args.bossEncOptions=bossEncOptions;
        DB.bossesDKP.optEnabled.args.bossEncOptions=bossEncOptions;
    end
    
    
    
    A.optionsTable.args.autoBossAwards=DB.bossesDKP.enabled and DB.bossesDKP.optEnabled or DB.bossesDKP.optDisabled;
    
    --A.optionsTable.args.autoBossAwards=DB.bossesDKP.optEnabled;
    
    DB.bossesDKP.instance[instance]=DB.bossesDKP.instance[instance] or {};
    
    DB.bossesDKP.patch=DB.bossesDKP.patch or {};
    DB.bossesDKP.patch[patch]=DB.bossesDKP.patch[patch] or {};
    
    if nil==DB.bossesDKP.patch[patch].perpatch then DB.bossesDKP.patch[patch].perpatch=true; end;
    DB.bossesDKP.patch[patch].dkp=DB.bossesDKP.patch[patch].dkp or 0;
    if not DB.bossesDKP.optEnabled.args[patch] then
        DB.bossesDKP.optEnabled.args[patch]={
            name=patch,
            type="group",
            args={
            },
        }
    end;
    
    
    
    
    local patchOptions={
        name="Award equally in "..patch,
        type="toggle",
        order=0,
        desc="Award all bosses same amount among all bosses in "..patch..".",
        set = function(info,val)
            DB.bossesDKP.patch[patch].perpatch = val;
            DB.bossesDKP.optEnabled.args[patch].args=val and DB.bossesDKP.patch[patch].optPerPatch or DB.bossesDKP.patch[patch].optPerInstance;
            --insTypes[name] = val and DB.bossesDKP.instance[instance][name].optPerInstance or DB.bossesDKP.instance[instance][name].optPerBoss;
            
        end,
        get = function(info) return DB.bossesDKP.patch[patch].perpatch end,
    }
    DB.bossesDKP.patch[patch].optPerInstance=DB.bossesDKP.patch[patch].optPerInstance or {};
    DB.bossesDKP.patch[patch].optPerInstance.patchOptions=patchOptions;
    --=A.optionsTable.args.autoBossAwards.args[patch].args;
    local perPatch={}
    perPatch.patchOptions=patchOptions;
    DB.bossesDKP.patch[patch].optPerPatch=perPatch;
    
    
    --print (patch,instance,bosses);
    if not DB.bossesDKP.patch[patch].optPerInstance[instance] then
        DB.bossesDKP.patch[patch].optPerInstance[instance]={
            name=instance,
            type="group",
            childGroups="tab",
            args={
            },
        }
    end;
    
    
    
    
    
    DB.bossesDKP.optEnabled.args[patch].args=DB.bossesDKP.patch[patch].perpatch and DB.bossesDKP.patch[patch].optPerPatch or DB.bossesDKP.patch[patch].optPerInstance;
    local insTypes=DB.bossesDKP.patch[patch].optPerInstance[instance].args;
    --agrgs instance args
    
    --print(insTypes);
    local typCounter=0;
    local function addType(name)
        DB.bossesDKP.instance[instance][name]=DB.bossesDKP.instance[instance][name] or {};
        DB.bossesDKP.instance[instance][name].dkp=DB.bossesDKP.instance[instance][name].dkp or 0;
        if nil==DB.bossesDKP.instance[instance][name].perinstance then DB.bossesDKP.instance[instance][name].perinstance=true; end;
        
        typCounter=typCounter+1;
        DB.bossesDKP.patch[patch][name]=DB.bossesDKP.patch[patch][name] or {};
        DB.bossesDKP.patch[patch][name].dkp=DB.bossesDKP.patch[patch][name].dkp or 0;
        DB.bossesDKP.patch[patch].optPerPatch[name]={
            name="Dkp per boss kill on "..name,
            desc="Amount of dkp everyone in the raid will get once a boss is killed in "..patch.." on "..name.." difficulty.",
            type = "input",
            order=2*typCounter,
            pattern="%d+";
            usage="Must be a number.";
            set = function(info,val) local a=tonumber(val);if a~=nil then DB.bossesDKP.patch[patch][name].dkp=a;end; end,
            get = function(info) return tostring(DB.bossesDKP.patch[patch][name].dkp);  end,
            
        }
        DB.bossesDKP.patch[patch].optPerPatch[name.."_nl"]={
            order=2*typCounter,
            type = "description",
            name = "",
        }
        
        DB.bossesDKP.instance[instance][name].optPerInstance={
            name=name,
            type="group",
            order=typCounter,
            args={
                
                instanceDKPonly={
                    name="Award per instance",
                    type="toggle",
                    desc = "Turn this off to set dkp points awareded per boss.",
                    set = function(info,val)
                        DB.bossesDKP.instance[instance][name].perinstance = val;
                        insTypes[name] = val and DB.bossesDKP.instance[instance][name].optPerInstance or DB.bossesDKP.instance[instance][name].optPerBoss;
                        --if val then
                    end,
                    get = function(info) return DB.bossesDKP.instance[instance][name].perinstance end,
                    order=0,
                },
                instanceAmount_nl = {
                    order = 1,
                    type = "description",
                    name = "",
                },
                instanceAmount={
                    name="Dkp per boss kill",
                    desc="Amount of dkp everyone in the raid will get once a boss is killed in "..instance.." on "..name.." difficulty.",
                    type = "input",
                    order=2,
                    pattern="%d+";
                    usage="Must be a number.";
                    set = function(info,val) local a=tonumber(val);if a~=nil then DB.bossesDKP.instance[instance][name].dkp=a;end; end,
                    get = function(info) return tostring(DB.bossesDKP.instance[instance][name].dkp);  end,
                },
            }
        }
        DB.bossesDKP.instance[instance][name].optPerBoss={
            name=name,
            type="group",
            order=typCounter,
            args={
                instanceDKPonly={
                    name="Award per instance",
                    type="toggle",
                    desc = "Turn this on to award for every boss same amount.",
                    set = function(info,val)
                        DB.bossesDKP.instance[instance][name].perinstance = val;
                        insTypes[name] = val and DB.bossesDKP.instance[instance][name].optPerInstance or DB.bossesDKP.instance[instance][name].optPerBoss;
                    end,
                    get = function(info) return DB.bossesDKP.instance[instance][name].perinstance end,
                    order=0,
                },
                instanceAmount_nl = {
                    order = 1,
                    type = "description",
                    name = "",
                },
            }
        }
        
        for i,v in pairs(bosses) do
            DB.bossesDKP.instance[instance][name].dkpPerBoss=DB.bossesDKP.instance[instance][name].dkpPerBoss or {};
            DB.bossesDKP.instance[instance][name].dkpPerBoss[v]=DB.bossesDKP.instance[instance][name].dkpPerBoss[v] or 0;
            DB.bossesDKP.instance[instance][name].optPerBoss.args[v]={
                name="Dkp per "..v.." kill",
                desc="Amount of dkp everyone in the raid will get once a "..v.." is killed in "..instance.." on "..name.." difficulty.",
                type = "input",
                order=2*i+2,
                pattern="%d+";
                usage="Must be a number.";
                set = function(info,val) local a=tonumber(val);if a~=nil then DB.bossesDKP.instance[instance][name].dkpPerBoss[v]=a;end; end,
                get = function(info) return tostring(DB.bossesDKP.instance[instance][name].dkpPerBoss[v]);  end,
            }
            DB.bossesDKP.instance[instance][name].optPerBoss.args[v.."_nl"]={
                order = 2*i+3,
                type = "description",
                name = "",
            }
            
            
        end
        insTypes[name]=DB.bossesDKP.instance[instance][name].perinstance and DB.bossesDKP.instance[instance][name].optPerInstance or DB.bossesDKP.instance[instance][name].optPerBoss;
        --print("callled with",name);
        
        
    end
    
    
    addType("10-man normal");
    addType("10-man heroic");
    addType("25-man normal");
    addType("25-man heroic");
    
    DB.bossesDKP.bosses=DB.bossesDKP.bosses or {};
    for i,v in pairs(bosses) do
        DB.bossesDKP.bosses[v]={};
        DB.bossesDKP.bosses[v].instance=DB.bossesDKP.instance[instance];
        DB.bossesDKP.bosses[v].patch=DB.bossesDKP.patch[patch];
    end
    
end
function A:OnEnable()
    DB=DKPmanagerDB;
    A.DB=DB;
    A.log:SetDB(DB.log);
    
    if DB.timerAmount==nil then DB.timerAmount=30; end;
    if DB.awardIfStopBidsOnTimeOut==nil then DB.awardIfStopBidsOnTimeOut=false; end;
    if DB.stopBidsOnTimeOut==nil then DB.stopBidsOnTimeOut=false; end;
    if DB.autoStartTimer==nil then DB.autoStartTimer=false; end;
    if DB.autoRestartTimer==nil then DB.autoRestartTimer=false; end;
    if DB.tunnelPlayer==nil then DB.tunnelPlayer={}; end;
    
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DKP Manager", "DKP Manager")
    --LibStub("AceConfigDialog-3.0"):SetDefaultSize("DKP Manager", 400, 250)
    self:Print(B.colors["red"]..A.ver..B.colors["close"].." version Loaded");
    if DBM then --this can be changed to UNIT_DIED	event from major event: COMBAT_LOG_EVENT_UNFILTERED or COMBAT_LOG_EVENT
        DBM:RegisterCallback("kill",self.BossKill);
        self:Print("DBM found, enabling Boss Auto Award");
        DB.bossesDKP= DB.bossesDKP or{};
        DB.bossesDKP.instance=DB.bossesDKP.instance or {};
        addBossEncounter("Cataclysm","Firelands",{"Beth'tilac","Lord Rhyolith", "Alysarazor", "Shannox", "Baleroc, the Gatekeeper", "Majordomo Staghelm","Ragnaros"});
        
        addBossEncounter("Cataclysm","Dragon Soul",{"Morchok","Warlord Zon'ozz","Yor'sahj the Unsleeping","Hagara the Stormbinder","Ultraxion", "Warmaster Blackhorn","Spine of Deathwing","Madness of Deathwing"});
        addBossEncounter("MoP","Heart of Fear",{"Imperial Vizier Zor'lok","Blade Lord Ta'yak","Garalon","Wind Lord Mel'jarak", "Amber-Shaper Un'sok","Grand Empress Shek'zeer"});
        addBossEncounter("MoP","Mogu'shan Vaults",{"The Stone Guard","Feng the Accursed","Gara'jal the Spiritbinder","The Spirit Kings","Elegon", "Will of the Emperor"});
        
        addBossEncounter("MoP","Pandaria",{"Sha of Anger", "Salyis's Warband"});
        addBossEncounter("MoP","Terrace of Endless Spring",{"Protectors of the Endless", "Tsulong", "Lei Shi", "Sha of Fear"});
        addBossEncounter("MoP","Throne of Thunder",{"Jin'rokh the Breaker", "Horridon", "Council of Elders", "Tortos","Megaera", "Ji-Kun", "Durumu the Forgotten", "Primordius", "Dark Animus","Iron Qon","Twin Consorts","Lei Shen","Ra-den"});
        addBossEncounter("MoP","Siege of Orgrimmar",{"Immerseus", "The Fallen Protectors", "Norushen", "Sha of Pride","Galakras", "Iron Juggernaut", "Kor'kron Dark Shaman", "General Nazgrim", "Malkorok","Spoils of Pandaria","Thok the Bloodthirsty", "Siegecrafter Blackfuse","Paragons of the Klaxxi","Garrosh Hellscream"});
		--NOTE: when u remove one line of the above, those will still stay in users DB, so they should either be removed or code should be adjusted to nor print those that are not added in here.
    else
        self:Print("DBM not found, Boss Auto Award disabled.");
        
    end
    
    
    
    
    
    LibStub("AceConfig-3.0"):RegisterOptionsTable("DKP Manager", A.optionsTable, {"dkpmanager", "dkpm"});
end





function A:OnDisable()
    
    -- Called when the addon is disabled
end

A.optionsTable = {
    type = "group",
    childGroups="tree",
    args = {
	biddingOptions={
            name="Dkp options",
            type="group",
            order=10,
            args={
                minBid={
                    name="Minimum bid",
                    type = "input",
                    order=110,
                    pattern="%d+";
                    usage="Minimum bid must be a number.";
                    set = function(info,val) local a=tonumber(val);if a~=nil then DB.minBid=a;end; end,
                    get = function(info) return tostring(DB.minBid);  end,
                },
                minBid_nl = {
                    order = 111,
                    type = "description",
                    name = "",
                },
                
                biddingType={
                    name="Method",
                    type="select",
                    values={sh="Second Highest",norm="Normal"},
                    desc = "Set's the way winner is going to be charged. If 'normal', then he will pay the highest value that he bid. With second highest, he will pay the second highest amount that was bid by another person.",
                    set = function(info,val) DB.biddingType=val; end,
                    get = function(info) return DB.biddingType;  end,
                    order=120,
                },
                biddingType_nl = {
                    order = 121,
                    type = "description",
                    name = "",
                },
                zeroSum={
                    name="zero sum",
                    type="toggle",
                    desc = "Enables / disables zero sum dkp award.",
                    set = function(info,val) DB.zeroSum = val end,
                    get = function(info) return DB.zeroSum end,
                    order=140,
                },
                silenceBid={
                    name="silence bidding",
                    type="toggle",
                    desc = "Enables / disables silence bidding.",
                    set = function(info,val) DB.silenceBidding = val end,
                    get = function(info) return DB.silenceBidding end,
                    order=150,
                },
                silenceBid_nl = {
                    order = 151,
                    type = "description",
                    name = "",
                },
                transferDkp={
                    name="transfer dkp",
                    type="toggle",
                    desc = "Enables / disables possibility to transfer dkp by you.",
                    set = function(info,val) DB.canTransferDKP = val end,
                    get = function(info) return DB.canTransferDKP end,
                    order=160,
                },
                
                
                h6={
                    name="Timer settings",
                    type="header",
                    order=230,
                },
                autoStartTimer={
                    name="Auto-start",
                    type="toggle",
                    desc = "Start timer automaticly when bidding was started.",
                    set = function(info,val) DB.autoStartTimer = val end,
                    get = function(info) return DB.autoStartTimer end,
                    order=240,
                },
                autoRestartTimer={
                    name="Restart on bid",
                    type="toggle",
                    desc = "Restarts the timer when bid have been received.",
                    set = function(info,val) DB.autoRestartTimer= val end,
                    get = function(info) return DB.autoRestartTimer end,
                    order=250,
                },
                autoRestartTimer_nl = {
                    order = 251,
                    type = "description",
                    name = "",
                },
                stopBidsOnTimeOut={
                    name="Auto-stop",
                    type="toggle",
                    desc = "Stop bidding when the timer has run out.",
                    set = function(info,val) DB.stopBidsOnTimeOut = val end,
                    get = function(info) return DB.stopBidsOnTimeOut end,
                    order=260,
                },
                awardIfStopBidsOnTimeOut={
                    name="Auto-award",
                    type="toggle",
                    desc = "Award player automaticly when the bidding was stoped by the timer.",
                    set = function(info,val) DB.awardIfStopBidsOnTimeOut= val end,
                    get = function(info) return DB.awardIfStopBidsOnTimeOut end,
                    order=270,
                },
                awardIfStopBidsOnTimeOut_nl = {
                    order = 271,
                    type = "description",
                    name = "",
                },
                timerAmount={
                    name="Time for bidding:",
                    type = "input",
                    order=280,
                    pattern="%d+";
                    usage="Time must be a number.";
                    set = function(info,val) local a=tonumber(val);if a~=nil then DB.timerAmount=a;end; end,
                    get = function(info) return tostring(DB.timerAmount);  end,
                },
            }
	},
	guildCommands={
            name="Guild commands",
            type="group",
            order=20,
            args={
                h4={
                    name="Dkp backup",
                    type="header",
                    order=170,
                },
                dkpBackup={
                    name="Backup",
                    type="execute",
                    desc = "Backup dkp points.",
                    func = function()
                        DB.backupOfficerNotes={};
                        for i,v in pairs(GRI:GetData()) do
                            DB.backupOfficerNotes[i]=v["officerNote"];
                        end;
                        DB.backupTime=date("%c", time());
                        A:Print("Officer notes with points have been saved at "..DB.backupTime..".");
                    end,
                    order=180,
                },
                dkpRestore={
                    name="Restore",
                    type="execute",
                    desc = "Restore dkp points.",
                    func = function()
                        local total= GetNumGuildMembers();
                        if StaticPopupDialogs["DKPBidder_TitleDropDownMenu_RestoreDKPStaticPopup"]~=nil then table.wipe(StaticPopupDialogs["DKPBidder_TitleDropDownMenu_RestoreDKPStaticPopup"]); end;
                        StaticPopupDialogs["DKPBidder_TitleDropDownMenu_RestoreDKPStaticPopup"] = {
                            text = "Are you sure you want to restore dkp points from "..DB.backupTime.."?",
                            whileDead = true,
                            enterClicksFirstButton=1,
                            hideOnEscape = 1,
                            hasEditBox=false,
                            button1 = "Restore",
                            button2 = "Cancel",
                            OnAccept = function(self, data, data2)
                                
                                local realmName="-"..GetRealmName();
                                for i=1,total do
                                    local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(i)
                                    name=string.gsub(name, realmName, "")
                                    if DB.backupOfficerNotes[name] then
                                        GuildRosterSetOfficerNote(i,DB.backupOfficerNotes[name]);
                                    end
                                end;
                                
                                A:Print("Officer notes with points have been restored from "..DB.backupTime.." backup.");
                            end,
                            timeout = 0,
                            
                        }
                        StaticPopup_Show("DKPBidder_TitleDropDownMenu_RestoreDKPStaticPopup");
                    end,
                    order=190,
                },
                h4={
                    name="Dkp decays",
                    type="header",
                    order=200,
                },
                decay={
                    name="Decay by perc",
                    type="execute",
                    desc = "Decay players dkp by % of their points that you will choose in the pop up. Helps prevent inflation.",
                    func = function()
                        if StaticPopupDialogs["DKPBidder_Popupwindow"]~=nil then table.wipe(StaticPopupDialogs["DKPBidder_Popupwindow"]); end;
                        StaticPopupDialogs["DKPBidder_Popupwindow"] = {
                            text = "What perc of players points should decay?",
                            hasEditBox=true,
                            button1 = "Decay",
                            button2 = "Cancel",
                            EditBoxOnTextChanged = function (self, data)
                                self:GetParent().button1:Enable()
                            end,
                            EditBoxOnEnterPressed = function(self) StaticPopup_OnClick(self:GetParent(), 1) end,
                            EditBoxOnEscapePressed = function(self) StaticPopup_OnClick(self:GetParent(), 2) end,
                            OnShow = function (self, data)
                                self.button1:Disable();
                                
                            end,
                            OnAccept = function(self, data, data2)
                                local perc=self.editBox:GetNumber();
                                A:LaunchDecay(perc);
                            end,
                            timeout = 0,
                            whileDead = true,
                            enterClicksFirstButton=true,
                            hideOnEscape = true,
                        }
                        StaticPopup_Show("DKPBidder_Popupwindow");
                    end,
                    order=220,
                },
                cap={
                    name="Decay by cap",
                    type="execute",
                    desc = "Cap all players dkp to amount of points that you will choose in the pop up. Helps prevent inflation.",
                    func = function()
                        if StaticPopupDialogs["DKPBidder_Popupwindow"]~=nil then table.wipe(StaticPopupDialogs["DKPBidder_Popupwindow"]); end;
                        StaticPopupDialogs["DKPBidder_Popupwindow"] = {
                            text = "At how many points you want to cap players?",
                            hasEditBox=true,
                            button1 = "Accept",
                            button2 = "Cancel",
                            EditBoxOnTextChanged = function (self, data)
                                self:GetParent().button1:Enable()
                            end,
                            EditBoxOnEnterPressed = function(self) StaticPopup_OnClick(self:GetParent(), 1) end,
                            EditBoxOnEscapePressed = function(self) StaticPopup_OnClick(self:GetParent(), 2) end,
                            OnShow = function (self, data)
                                self.button1:Disable();
                                
                            end,
                            OnAccept = function(self, data, data2)
                                local perc=self.editBox:GetNumber();
                                A:LaunchCap(perc);
                            end,
                            timeout = 0,
                            whileDead = true,
                            enterClicksFirstButton=true,
                            hideOnEscape = true,
                        }
                        StaticPopup_Show("DKPBidder_Popupwindow");
                    end,
                    order=230,
                },
            }
	},
	raidCommands={
            name="Raid commands",
            type="group",
            order=30,
            args={
                h5={
                    name="List players addon version",
                    type="header",
                    order=200,
                },
                verGuildCheck={
                    name="Guild",
                    type="execute",
                    desc = "Check guild.",
                    func = function()
                        A:AskForVersion("guild");
                    end,
                    order=210,
                },
                verRaidCheck={
                    name="Raid",
                    type="execute",
                    desc = "Check raid.",
                    func = function()
                        A:AskForVersion("raid");
                    end,
                    order=220,
                },
                
            }
	},
        
        
        
}}






--/script DKPmanager:LaunchDecay(5)
function A:LaunchDecay(perc)
    
    local players=GRI:GetMainPlayers();
    for i=1,#players do
        
        local name=players[i];
        local net= GRI:GetNet(name);
        
        if net > 0 then
            local change=math.floor(net*perc/100);
            if (change > 0) then
                A:AddAction(name,-change,"Decay by "..perc.."%.");
            end
        end
    end;
    self:Print("Decay function run.");
end

--/script DKPmanager:LaunchCap(1000)
function A:LaunchCap(cap)
    
    local players=GRI:GetMainPlayers();
    for i=1,#players do
        
        local name=players[i];
        local net= GRI:GetNet(name);
        
        if net > cap then
            local change = net-cap;
            A:AddAction(name,-change,"Capping to "..cap..".");
        end
    end;
    self:Print("Cap function run.");
end

--/script DKPmanager:LaunchOnTime(25) --todo: remake this function as its crappy written guild with 100 players will cause this to run 4000 times the loop instead of 10-40.
function A:LaunchOnTime(amount)
    
    local players=GRI:GetMainPlayers();
    for i=1,#players do
        
        local name= players[i];
        local net = GRI:GetNet(name);
        
        if GetNumGroupMembers() > 1 then
            for i=1,40 do
                
                local inraidname = GetRaidRosterInfo(i);
                
                if inraidname == name then
                    A:AddAction(name,amount,"OnTime bonus: "..amount..".");
                end;
            end;
        end;
    end;
    
    self:Print("OnTime function run.");
end
