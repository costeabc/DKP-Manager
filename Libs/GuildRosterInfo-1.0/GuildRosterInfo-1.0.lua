local MAJOR,MINOR = "GuildRosterInfo-1.0", 2
local GRI, oldminor = LibStub:NewLibrary(MAJOR, MINOR);

if not GRI then return end -- No upgrade needed\

--LibStub("AceConsole-3.0"):Embed(DKPlog);
LibStub("AceComm-3.0"):Embed(GRI);
LibStub("AceSerializer-3.0"):Embed(GRI);
LibStub("AceEvent-3.0"):Embed(GRI);
LibStub("AceTimer-3.0"):Embed(GRI);


GRI.callbacks = GRI.callbacks or LibStub("CallbackHandler-1.0"):New(GRI)


local lastGuildRosterUpdateEvent=0;
local lastDataUpdate=0;
local players={};
local colors={
    ["Death Knight"]={0.77,0.12,0.23,1.00,"|CFFC41F3B"},
    Druid={1.00,0.49,0.04,1.00,"|CFFFF7D0A"},
    Hunter= {0.67,0.83,0.45,1.00,"|CFFABD473"},
    Mage= {0.41,0.80,0.94,1.00,"|CFF69CCF0"},
    Paladin= {0.96,0.55,0.73,1.00,"|CFFF58CBA"},
    Priest={1.00,1.00,1.00,1.00,"|CFFFFFFFF"},
    Rogue= {1.00,0.96,0.41,1.00,"|CFFFFF569"},
    Shaman={0.14,0.35, 1.00,1.00,"|CFF2459FF"},
    Warlock={0.58,0.51,0.79,1.00,"|CFF9482C9"},
    Warrior={0.78,0.61,0.43,1.00,"|CFFC79C6E"},
    Monk={0.33,0.54,0.52,1.0,"|CFF00FF96"},
    unknown={0.50,0.50,0.50,1.00,"|CFF666666"}
}

function GRI:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa".."GuildRosterInfo ".."|cffaaaaaa".."> ".."|r"..msg);
end





function GRI:GUILD_ROSTER_UPDATE()
	--[[if time()<=lastGuildRosterUpdateEvent then
		lastGuildRosterUpdateEvent=lastGuildRosterUpdateEvent+1;
    else]]
    lastGuildRosterUpdateEvent=GetTime();
    --end;
    --self:Print(lastGuildRosterUpdateEvent);
    self:ScheduleUpdateData()
end
GRI:RegisterEvent("GUILD_ROSTER_UPDATE");

function GRI:ScheduleUpdateData()--TODO: move this to gui lib
    GRI.timerIsOn=true;
    local timeGap=1;
    if GRI.timeLeft==nil then GRI.timeLeft=timeGap; end;
    if GRI.timeLeft<=0 then GRI.timeLeft=timeGap; end;
    if(GRI.timerFrame == nil) then
        GRI.timerFrame = CreateFrame("Frame",nil, UIParent);
        GRI.timerFrame.ScriptLaunched=false;
    end
    if not GRI.timerFrame.ScriptLaunched then
        GRI.timerFrame.ScriptLaunched=true;
        GRI.timerFrame:SetScript("onUpdate",function (self,elapse)
            if elapse<2 then
                if GRI.timeLeft>0 and GRI.timerIsOn then
                    GRI.timeLeft=GRI.timeLeft-elapse;
                elseif GRI.timerIsOn then
                    GRI.timerFrame.ScriptLaunched=false;
                    GRI.timerIsOn=false
                    self:SetScript("onUpdate",nil);
                    GRI:UpdateData();
                end;
            end;
        end);
    end;
end

function GRI:ScheduleFireDataUpdate()--TODO: move this to gui lib
    GRI.timerIsOn2=true;
    local timeGap2=1;
    if GRI.timeLeft2==nil then GRI.timeLeft2=timeGap2; end;
    if GRI.timeLeft2<=0 then GRI.timeLeft2=timeGap2; end;
    if(GRI.timerFrame2 == nil) then
        GRI.timerFrame2 = CreateFrame("Frame",nil, UIParent);
        GRI.timerFrame2.ScriptLaunched=false;
    end
    if not GRI.timerFrame2.ScriptLaunched then
        GRI.timerFrame2.ScriptLaunched=true;
        GRI.timerFrame2:SetScript("onUpdate",function (self,elapse)
            if elapse<2 then
                if GRI.timeLeft2>0 and GRI.timerIsOn2 then
                    GRI.timeLeft2=GRI.timeLeft2-elapse;
                elseif GRI.timerIsOn2 then
                    GRI.timerFrame2.ScriptLaunched=false;
                    GRI.timerIsOn2=false
                    self:SetScript("onUpdate",nil);
                    GRI.callbacks:Fire("DataUpdated");
                    --GRI:Print("Fires data updated");
                end;
            end;
        end);
    end;
end

function GRI:UpdateData()
    if (lastDataUpdate<lastGuildRosterUpdateEvent) then
        --self:Print("Updating");
        lastDataUpdate=GetTime();
        local total= GetNumGuildMembers();
        local makealt={};
        local realmName="-"..GetRealmName();
        for i=1,total do
            local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(i)
            name=string.gsub(name, realmName, "")
            players[name]={};
            players[name]["lastUpdateTime"]=lastDataUpdate;
            players[name]["class"]=class;
            players[name]["note"]=note;
            players[name]["rankIndex"]=rankIndex;
            players[name]["officerNote"]=officernote;
            players[name]["color"]=colors[class];
            years, months, days, hours = GetGuildRosterLastOnline(i);
            --print(name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile)
            --print(years, months, days, hours);
            if online or isMobile then
                players[name]["lastonline"]=0;
            else players[name]["lastonline"]=years*365+months*30+days; end;
            players[name]["rank"]=rank;
            players[name]["online"]=online;
            players[name]["id"]=i;
            players[name]["onlineName"]=nil;
            if not players[name]["alt"] then
                players[name]["alt"]={};
            else
                wipe(players[name]["alt"]);
            end
            
            if (string.find(officernote, "N.-:([-%d]+).-T.-:([-%d]+)")~=nil) then --TODO: przy pierwszym odpaleniu niech sprawdza tez notacje T: i N:
                temp=string.gsub(officernote,".-N.-:([-%d]+).*","%1");
                players[name]["net"]= tonumber(temp);
                temp=string.gsub(officernote,".-T.-:([-%d]+).*","%1");
                players[name]["tot"]= tonumber(temp);
                players[name]["main"]=name;
                if players[name].online then players[name].onlineName=name; end;
            else
                players[name]["net"]=0;
                players[name]["tot"]=0;
                
                makealt[name]=officernote;
            end
        end
        for name,data in pairs(players) do
            if not data.lastUpdateTime or data.lastUpdateTime<lastDataUpdate then
                wipe(data);
                players[name]=nil;
            end;
        end
        
        for i,v in pairs(makealt) do
            if players[v]~=nil then
                players[i]["main"]=v;
                table.insert(players[v]["alt"],i);
                players[i].tot=players[v].tot;
                players[i].net=players[v].net;
                if players[i].online then players[v].onlineName=i; end;
            else
                players[i]["main"]=i;--he doesnt have a main so he is his main.
                if players[i].online then players[i].onlineName=i; end;
            end
        end;
        
        self:ScheduleFireDataUpdate()
        
    end;
end;

--remember to check if player is already added --TODO: Update with new data.
--todo:check if to remove player if player number is lower then those in memory. same for dkp bidder




-----------------------
--// GET Functions
-----------------------
function GRI:GetMainPlayers()--[[working incorerectly]]
    
    local playersRet={};
    local temp={};
    self:UpdateData();
    
    for i,v in pairs(players) do
        if not temp[players[i].main] then
            table.insert(playersRet,players[i].main);
            temp[players[i].main]=true;
        end
    end;
    return playersRet;
end;


function GRI:GetData()
    self:UpdateData();
    return players;
end;
function GRI:GetMain(name)
    self:UpdateData();
    return players[name].main;
end;
function GRI:RemoveAlt(main,alt)
    self:UpdateData();
    for i=1,#self:GetAlts(main) do
        if self:GetAlts(main)[i]==alt then
            table.remove(self:GetAlts(main),i);
            break;
        end;
    end;
end

function GRI:SetMain(alt,main)
    self:UpdateData();
    table.insert(self:GetAlts(main),alt);
    players[alt].main=main;
    players[alt].net=players[main].net;
    players[alt].tot=players[main].tot;
    self:ScheduleFireDataUpdate()
end;
function GRI:GetClass(name)
    self:UpdateData();
    return players[name].class;
end;
function GRI:GetRank(name)
    self:UpdateData();
    return players[name].rank;
end;
function GRI:GetId(name)
    self:UpdateData();
    return players[name].id;
end;
function GRI:GetAlts(name)
    self:UpdateData();
    return players[name].alt;
end;
function GRI:SetNet(name,amount)
    self:UpdateData();
    players[players[name].main].net=amount;
    local alts=self:GetAlts(players[name].main)
    for i=1,#alts do
        players[alts[i]].net=amount;
    end;
    
    self:ScheduleFireDataUpdate()
end
function GRI:IsOnList(name)
    self:UpdateData();
    if players[name] then
        return true
    else
        return false
    end
end
function GRI:GetNet(name)
    self:UpdateData();
    return players[players[name].main].net;
end;
function GRI:GetTot(name)
    self:UpdateData();
    return players[players[name].main].tot;
end;
function GRI:SetTot(name,amount)
    self:UpdateData();
    players[players[name].main].tot=amount;
    local alts=self:GetAlts(players[name].main)
    for i=1,#alts do
        players[alts[i]].tot=amount;
    end;
    
    self:ScheduleFireDataUpdate()
end

function GRI:GetLastOnline(name)
    self:UpdateData();
    return players[name].lastonline;
end;
function GRI:GetPlayerLastOnline(name)
    self:UpdateData();
    return players[players[name].main].lastonline;
end;
function GRI:GetOnlineName(name)
    self:UpdateData();
    return players[players[name].main].onlineName;
end

function GRI:IsOnline(name)
    self:UpdateData()
    return players[name].online;
end
function GRI:GetPlayerData(name)
    self:UpdateData()
    return players[name];
end
---------------------------
---------------------------
