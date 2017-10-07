local MAJOR,MINOR = "DKPlog-1.0", 1
local DKPlog, oldminor = LibStub:NewLibrary(MAJOR, MINOR);

if not DKPlog then return end -- No upgrade needed\

--LibStub("AceConsole-3.0"):Embed(DKPlog);
LibStub("AceComm-3.0"):Embed(DKPlog);
LibStub("AceSerializer-3.0"):Embed(DKPlog);
LibStub("AceEvent-3.0"):Embed(DKPlog);

DKPlog.callbacks = DKPlog.callbacks or LibStub("CallbackHandler-1.0"):New(DKPlog)


prefix="dkplog";
local DB={};
local GRI=LibStub("GuildRosterInfo-1.0");
DKPlog.initialized=false;




local function Log(main,changetime,name,dkpchange,newdkp,reason,zone,loggername)
    --print("LOG: ",main,changetime,name,dkpchange,newdkp,reason,zone,loggername);
    if DB.logData[main]==nil then DB.logData[main]={}; end;
    table.insert(DB.logData[main],1,{changetime,name,tonumber(dkpchange),tonumber(newdkp),reason,zone,loggername});
    GRI:SetNet(main,tonumber(newdkp));
    if tonumber(dkpchange)>0 then
        GRI:SetTot(main,GRI:GetTot(main)+tonumber(dkpchange));
    end
    if loggername==UnitName("player") then
        
        local sendData={msg="loginput",data={main,changetime,name,dkpchange,newdkp,reason,zone,loggername}};
        DKPlog:SendCommMessage(prefix, DKPlog:Serialize(sendData), "GUILD"); --if (action.amount~=0) then end;
        GuildRosterSetOfficerNote(GRI:GetId(main),"N:"..GRI:GetNet(main).." T:"..GRI:GetTot(main));--todo: 17.08.2012 this part was removed to clean code. Althoguht it might happen it was needed to be this way!if tonumber(dkpchange)~=0 then  [..] end
    end
    
end
--local functions
local function Lock(playerName)
    if not DKPlog.initialized then return; end;
    --DKPlog:Print("Log locked by: "..playerName);
    if playerName==UnitName("player") then
        local sendData={msg="lock",data={}};
        DKPlog:SendCommMessage(prefix, DKPlog:Serialize(sendData), "GUILD");
    end;
    DB.locked=playerName;
    DB.lockedCount=0;
end;
local function printTable(t,s)
    if s==nil then s=""; end;
    for i,v in pairs(t) do
        print (s..i.."=",v);
        if type(v)=="table" then printTable(v,s.."   ") end
    end;
end

function DKPlog:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa".."DKP - |r|CFF56fd11Log".."|cffaaaaaa".."> ".."|r"..msg);
end


local realmName="-"..GetRealmName();
function DKPlog:OnCommReceived(prefix, message, distribution, sender)
    if not DKPlog.initialized then return; end;
    
    sender=string.gsub(sender, realmName, "");
    
    suc,data=DKPlog:Deserialize(message);
    if suc then
        msg=data.msg;
        data=data.data;
        if msg=="loginput" and sender~=UnitName("player") then
            Log(unpack(data));
        elseif msg=="lock" then
            if sender~=UnitName("player") then
                Lock(sender);
            end;
        elseif msg=="unlock" then
            if sender==DB.locked then
                --DKPlog:Print("Player "..sender.." unlocking.");
                DB.locked=nil;
                DB.lockedCount=0;
                GuildRoster()
            else
                --DKPlog:Print("Player "..sender.." trying to unlock player "..DB.locked.." lock.");
            end;
        end;
    end
end



--CanViewOfficerNote()
---
function DKPlog:SetDB(data)
    DB=data;
    DKPlog:RegisterComm(prefix);
    if DB.actions==nil then
        DB.actions={};
        DB.logData={};
    end
    wipe(DB.actions);
    DKPlog.initialized=true--TODO: Change into function printing log is ready for use.
    GRI:UpdateData()
end

---
function DKPlog:GetLog(name)
    if not DKPlog.initialized then return; end;
    GRI:UpdateData();
    return DB.logData[GRI:GetMain(name)]
end

function DKPlog:GetEntireLog()
    return DB.logData
end

local function ApplyActions()
    if not DKPlog.initialized then return; end;
    GRI:UpdateData();
    if #DB.actions>0 then
        if DB.locked==UnitName("player") then--REAL APPLY PART! TODO: Remake it. It has to remove 1. dkp from notes 2. remove values from playerdata. important!: Firstly remove from playerdata, then from note! After that acknowledge of the change.
            --DKPlog:Print("Applying actions");
            for index,action in ipairs(DB.actions) do
                
                if action.type=="dkpchange" then
                    if GRI:GetNet(action.mainName)+tonumber(action.amount)>=0 then
                        
                        Log(action.mainName,action.time,action.name,action.amount,GRI:GetNet(action.mainName)+action.amount,action.reason,action.zone,UnitName("player"));
                        DKPlog.callbacks:Fire("ActionComplete",action); --or not, if the points do not match!
                    else
                        DKPlog.callbacks:Fire("ActionFailed",action);
                    end
                elseif action.type=="setalt" then
                    if action.alt==action.main then
                        if action.alt~=GRI:GetMain(action.alt) then
                            GRI:RemoveAlt(GRI:GetMain(action.alt),action.alt);
                            GRI:SetMain(action.alt,action.main);
                            GRI:SetTot(action.alt,0);
                            Log(action.alt,action.time,action.alt,0,0,"Char was set as a main",action.zone,UnitName("player"));
                            
                            --GuildRosterSetOfficerNote(GRI:GetId(action.alt),"Net:"..GRI:GetNet(action.alt).." Tot:"..GRI:GetTot(action.alt));--todo: 17.08.2012 this part was removed to clean code. Althoguht it might happen it was needed to be this way! it was changed so that the previous function does all the job itself.
                        end
                    else
                        if GRI:GetMain(action.alt)==action.alt then--alt is a main, transfer his dkp!
                            --fuck the logs!
                            local net=GRI:GetNet(action.alt);
                            Log(action.alt,action.time,action.alt,-net,0,"Char was set as an alt of "..action.main,action.zone,UnitName("player"))
                            
                            Log(action.main,action.time,action.alt,net,GRI:GetNet(action.main)+net,"Added alt "..action.alt,action.zone,UnitName("player"))
                        else
                            GRI:RemoveAlt(GRI:GetMain(action.alt),action.alt);
                        end;
                        GRI:SetMain(action.alt,action.main);
                        GuildRosterSetOfficerNote(GRI:GetId(action.alt),action.main);
                    end;
                end
                
            end;
            
            wipe(DB.actions);
            local sendData={msg="unlock",data={}};
            --DKPlog:Print("Unlocking log");
            DKPlog:SendCommMessage(prefix, DKPlog:Serialize(sendData), "GUILD");
            GuildRoster();
        else
            if DB.locked==nil then
                Lock(UnitName("player"));
            elseif (DB.lockedCount==10) then
                DKPlog:Print("Trying to release lock, another player might get stuck.");
                Lock(UnitName("player"));
            else
                DKPlog:Print("Log is locked by "..DB.locked..". Cannot apply actions. Wait 2 sec.");--TODO add counter.
                DB.lockedCount=DB.lockedCount+1;
            end;
            DKPlog:ScheduleApplyActions()
        end;
        
    end
end

function DKPlog:AddAction(name,amount,reason)
    if not DKPlog.initialized then return; end;
    GRI:UpdateData();
    local action={};
    action.type="dkpchange";
    action.mainName=GRI:GetMain(name);--todo: this should be counted after roster change, cuz main might have changed during time!
    action.name=name;
    action.time=time();
    action.amount=amount;
    action.reason=reason;
    action.zone=GetRealZoneText();
    table.insert(DB.actions,action);
    DKPlog:ScheduleApplyActions()
    GuildRoster();
end;
function DKPlog:SetAlt(main,alt)
    if not DKPlog.initialized then return; end;
    GRI:UpdateData();
    --main=GRI:GetMain(main);
    if GRI:GetMain(main)~=main and main~=alt  then--na chuj to tu jest?... todo: test this
        self:Print("Cannot set "..alt.." as alt of "..main.." becouse he is an alt already of "..GRI:GetMain(main)..". You must firstly set "..main.." as main.");
        return;
    end
    if alt~=main then
        for i=1,#GRI:GetAlts(alt) do
            self:SetAlt(main,#GRI:GetAlts(alt)[i]);
        end;
    end
    local action={};
    action.type="setalt";
    action.main=main;
    action.alt=alt;
    action.time=time();
    action.zone=GetRealZoneText();
    
    table.insert(DB.actions,action);
    DKPlog:ScheduleApplyActions()
    GuildRoster();
end

--remember to check if player is already added --TODO: Update with new data.
--todo:check if to remove player if player number is lower then those in memory. same for dkp bidder

function DKPlog:ScheduleApplyActions()--TODO: move this to gui lib
    DKPlog.timerIsOn=true;
    if DKPlog.timeLeft==nil then DKPlog.timeLeft=1; end;
    if DKPlog.timeLeft<=0 then DKPlog.timeLeft=1; end;
    if(DKPlog.timerFrame == nil) then
        DKPlog.timerFrame = CreateFrame("Frame",nil, UIParent);
        DKPlog.timerFrame.ScriptLaunched=false;
    end
    if not DKPlog.timerFrame.ScriptLaunched then
        DKPlog.timerFrame.ScriptLaunched=true;
        DKPlog.timerFrame:SetScript("onUpdate",function (self,elapse)
            if elapse<2 then
                if DKPlog.timeLeft>0 and DKPlog.timerIsOn then
                    DKPlog.timeLeft=DKPlog.timeLeft-elapse;
                elseif DKPlog.timerIsOn then
                    DKPlog.timerFrame.ScriptLaunched=false;
                    DKPlog.timerIsOn=false
                    self:SetScript("onUpdate",nil);
                    ApplyActions();
                    
                    
                end;
            end;
        end);
    end;
end


