local hbn="" --highest bidder  name
local shbn="" --second highest bidder name
local hbv=0; -- highest bidder value
local shbv=0; -- second highest bidder Value
local A=LibStub("AceAddon-3.0"):GetAddon("DKP Manager");
local B=LibStub("AceAddon-3.0"):GetAddon("DKP Bidder");

local GRI=LibStub("GuildRosterInfo-1.0");
A.zeroSumPoints=0;

A.transferFrom="Transfer from ";
A.transferTo="Transfer to ";


function A:SendChanges(callbackname,action)
    if string.find(action.reason,A.transferTo) then
        local ret=string.sub(action.reason,#A.transferTo+1)
        A:AddAction(ret,-action.amount,A.transferFrom..action.name);
    end
    
    if action.amount and action.amount~=0 then
        local message="Your dkp have changed by "..action.amount..". Reason: "..action.reason..". Your new dkp amount is "..GRI:GetNet(action.name);
        local name=GRI:GetOnlineName(action.name);
        if name~=nil then
            A:Send("info",message,"WHISPER",name);
            SendChatMessage("<DKP-Manager> "..message,"WHISPER",nil,name);
        end;
    end
end
function A:SendFailed(callbackname,action)
    if string.find(action.reason,A.transferTo) then
        A:Send("error","You do not have enaugh points to make this transfer. Currently you have "..GRI:GetNet(action.name).." points. Action failed: "..action.reason,"WHISPER",action.name);
    elseif action.amount and action.amount~=0 then
        A:Print("Player "..action.name.."dkp could not have been changed by "..action.amount.." becouse of "..action.reason..". His dkp amount is "..GRI:GetNet(action.name));
    end
    
end


function A:Send(msg,data,dist,target)
    local sendData={msg=msg,data=data};
    local msg=self:Serialize(sendData);
    --SendAddonMessage(B.prefix,msg,dist,target);
    self:SendCommMessage(B.prefix,msg,dist,target);
end;


function A:StartBids(item)
    
    self:CancelAllTimers();
    SendChatMessage("<DKP-Manager> Auction for "..item.." started.","RAID");
    A.biddingStartTime=GetTime();
    
    wipe(A.bidTable);
    
    A.highestBid=-1;
    A.biddingItem=item;
    
    A:SetBiddingState(true);
    local v=B.view.adminFrame.view;
    v.awardButton:Disable();
    for i=1, MAX_RAID_MEMBERS do
        local name=GetRaidRosterInfo(i);
        
        if GRI:IsOnList(name) and GRI:IsOnline(name) then
            self:Send("startBids",{minBid=A.DB.minBid,item=item},"WHISPER", name);
        end
    end;
    if A.DB.autoStartTimer then
        self:SendStartTimer(A.DB.timerAmount);
        if A.DB.stopBidsOnTimeOut then self:ScheduleTimer(A.TimerStopBids, (A.DB.timerAmount+1), self); end;
        
    end;
end

function A:TimerStopBids()
    self.wasStopedByTimer=true;
    self:StopBids();
end
function A:StopBids()
    self:CancelAllTimers();
    SendChatMessage("<DKP-Manager> Auction for "..A.biddingItem.." stoped.","RAID");
    if A.DB.silenceBidding then
        for i,v in pairs(A.bidTable) do
            self:BroadcastBid(i,v,A.bidTable[i].time);
        end
    end
    A:SetBiddingState(false);
    
    local count=0;
    for i,v in pairs(A.bidTable) do
        count=count+1;
        if A.DB.silenceBidding then self:BroadcastBid(v.amount,i,v.time); end;
    end
    local v=B.view.adminFrame.view;
    if count>0 then
        v.awardButton:Enable();
    end
    
    self:Send("stopBids",nil,"RAID");
    A.highestBid=9999999999999;
    if A.DB.awardIfStopBidsOnTimeOut and self.wasStopedByTimer then
        self.wasStopedByTimer=nil;
        self:AwardPlayer();
    end
end

function A:BroadcastBid(amount,name,timeOfBid)
    
    if not (A.DB.silenceBidding and A.biddingInProgress) then
        if not timeOfBid then timeOfBid=GetTime() end;
        self:Send("broadcastBid",{bidderName=name,amount=amount,timeOfBid=timeOfBid}, "RAID");
        if A.DB.autoRestartTimer then
            self:SendStartTimer(A.DB.timerAmount);
            self:CancelAllTimers();
            if A.DB.stopBidsOnTimeOut then self:ScheduleTimer(A.TimerStopBids, (A.DB.timerAmount+1), self); end;
        end
    end;
    
    
end

--[[ TODO: test before release
25.07.2012
- from now on u can bid 0 on silence bid and it will change ur previous bid
- you can bid below the highest bid and its still going to be received as long
]]
function A:AnalizeBid(amount,name)
    --self:Print("Bid received: "..name.." for "..amount);
    amount=tonumber(amount);
    if A.DB.silenceBidding or A.DB.biddingType=="sh" then self:Send("info","Your bid for "..amount.." has been received", "WHISPER",name) end;
    if amount>GRI:GetNet(name) then
        self:Send("Error","You do not have enought points to bid "..amount..". You have only "..GRI:GetNet(name).." points.","WHISPER",name);
        return;
    end;
    local time=(math.floor((GetTime()-A.biddingStartTime)*100))/100;
    
    if amount>=A.DB.minBid then
        if A.bidTable[name]==nil or A.bidTable[name].amount<amount then
            if A.bidTable[name]==nil then
                A.bidTable[name]={}
            end;
            A.bidTable[name].amount=amount;
            A.bidTable[name].time=time;
            if not A.DB.silenceBidding then
                self:BroadcastBid(amount,name);
                if amount>A.highestBid then
                    local hbn="" --highest bidder  name
                    local shbn="" --second highest bidder name
                    local hbv=A.DB.minBid; -- highest bidder value
                    local shbv=A.DB.minBid; -- second highest bidder Value
                    for name,data in pairs(A.bidTable) do
                        if data.amount>=shbv then
                            if hbn=="" then
                                hbn=name;
                                hbv=data.amount;
                            else
                                if hbv < data.amount or (hbv==data.amount and A.bidTable[hbn].time > data.time) then
                                    shbn=hbn;
                                    shbv=hbv;
                                    hbn=name;
                                    hbv=data.amount;
                                else
                                    shbv=data.amount;
                                    shbn=name;
                                end
                            end
                        end
                    end
                    if A.DB.biddingType=="norm" then
                        self:BroadcastBid(hbv,hbn);
                        A.highestBid=hbv;
                    elseif A.DB.biddingType=="sh" then
                        if shbn~="" then self:BroadcastBid(shbv,shbn,A.bidTable[hbn].time+1); end;
                        self:BroadcastBid(shbv,hbn,A.bidTable[hbn].time);
                        A.highestBid=shbv;
                    end
                end;
            end;
        elseif A.DB.silenceBidding and A.bidTable[name].amount>amount then
            A.bidTable[name].amount=amount;
            A.bidTable[name].time=time;
        end;
    else
        self:Send("error","The amount you want to bid must be greater then or equal to "..(A.DB.minBid-1),"WHISPER",name);
    end;
end;

--[[function A:AnalizeBid(amount,name)
	--self:Print("Bid received: "..name.." for "..amount);
	amount=tonumber(amount);
	if A.DB.silenceBidding or A.DB.biddingType=="sh" then self:Send("info","Your bid for "..amount.." has been received", "WHISPER",name) end;
	if amount>GRI:GetNet(name) then
		self:Send("error","You do not have enaught points to bid "..amount..". You have only "..GRI:GetNet(name).." points.","WHISPER",name);
		return;
	end;

	if amount>=A.DB.minBid and amount>A.highestBid then
		if A.bidTable[name]==nil or A.bidTable[name].amount<amount then
			if A.bidTable[name]==nil then
				A.bidTable[name]={}
			end;
			A.bidTable[name].amount=amount;
			A.bidTable[name].time=(math.floor((GetTime()-A.biddingStartTime)*100))/100;
			hbn="" --highest bidder  name
			shbn="" --second highest bidder name
			hbv=A.DB.minBid; -- highest bidder value
			shbv=A.DB.minBid; -- second highest bidder Value

			for name,data in pairs(A.bidTable) do

				if data.amount>=shbv then
					if hbn=="" then
						hbn=name;
						hbv=data.amount;
					else
						if hbv < data.amount or (hbv==data.amount and A.bidTable[hbn].time > data.time) then
							shbn=hbn;
							shbv=hbv;
							hbn=name;
							hbv=data.amount;
						else
							shbv=data.amount;
							shbn=name;
						end
					end
				end
			end
			if A.DB.biddingType=="norm" then
				self:BroadcastBid(hbv,hbn);
				A.highestBid=hbv;
			elseif A.DB.biddingType=="sh" then
				if shbn~="" then self:BroadcastBid(shbv,shbn,A.bidTable[hbn].time+1); end;
				self:BroadcastBid(shbv,hbn,A.bidTable[hbn].time);
				A.highestBid=shbv;
			end

		end;
	else
		if not A.DB.silenceBidding then self:Send("error","The amount you want to bid must be greater then "..math.max(A.DB.minBid-1,A.highestBid),"WHISPER",name);
		else
			if A.bidTable[name]==nil or A.bidTable[name].amount<amount then
				if A.bidTable[name]==nil then
					A.bidTable[name]={}
				end;
				A.bidTable[name].amount=amount;
				A.bidTable[name].time=(math.floor((GetTime()-A.biddingStartTime)*100))/100;
			end;
		end;
	end;
end;]]
function A:AwardPlayer()
    
    local v=B.view.adminFrame.view;
    local item=A.biddingItem
    if item==nil then return end;
    local isML=false;
    local method, partyMaster, raidMaster = GetLootMethod()
    
    if raidMaster~=nil and GetRaidRosterInfo(raidMaster)==UnitName("player") then
        isML=true;
    end
    
    local count=0;
    for i,v in pairs(A.bidTable) do
        count=count+1;
    end
    if count>0 then
        local playerName;
        local amount;
        if B:GetBidderList():GetLastSelected()~=nil then
            playerName=B:GetBidderList():GetLastSelected()[2].name;
            amount=B:GetBidderList():GetLastSelected()[3].name;
        else
            hbn="" --highest bidder  name
            shbn="" --second highest bidder name
            hbv=A.DB.minBid; -- highest bidder value
            shbv=A.DB.minBid; -- second highest bidder Value
            
            for name,data in pairs(A.bidTable) do
                --print(name,data.amount,data.time);
                if data.amount>=shbv then
                    if hbn=="" then
                        hbn=name;
                        hbv=data.amount;
                    else
                        if hbv < data.amount or (hbv==data.amount and A.bidTable[hbn].time > data.time) then
                            shbn=hbn;
                            shbv=hbv;
                            hbn=name;
                            hbv=data.amount;
                        else
                            shbv=data.amount;
                            shbn=name;
                        end
                    end
                end
            end
            if A.DB.biddingType=="norm" then
                playerName=hbn;
                amount=hbv;
            elseif A.DB.biddingType=="sh" then
                playerName=hbn;
                amount=shbv;
            end
        end
        if GRI:GetNet(playerName)>=tonumber(amount) then
            A:AddAction(playerName,-tonumber(amount),"Won "..item..".");
            SendChatMessage("<DKP-Manager> "..playerName.." won "..item.." for ".. amount.. " dkp.","RAID");
            if A.DB.zeroSum and amount>0 then
                --if self.zeroSumPoints>0 then self:Print("Points that could not be shared equally from last auction that are going to be used for this zero sum: "..self.zeroSumPoints); end;
                
                local numberOfMembers=0;
                for i=1, MAX_RAID_MEMBERS do
                    name=GetRaidRosterInfo(i);
                    if GRI:IsOnList(name) then numberOfMembers=numberOfMembers+1; end
                end
                local shareAmount=amount+self.zeroSumPoints;
                if numberOfMembers>1 then
                    amount=math.floor(shareAmount/(numberOfMembers))
                    self.zeroSumPoints=shareAmount-amount*numberOfMembers;
                end;
                for i=1, MAX_RAID_MEMBERS do
                    name=GetRaidRosterInfo(i);
                    if GRI:IsOnList(name) then
                        A:AddAction(name,tonumber(amount),"ZeroSum for "..item);
                    end;
                end;
                --if self.zeroSumPoints>0 then self:Print("Points that could not be shared equally that are going to be used for next zero sum: "..self.zeroSumPoints); end;
                
            end
            if isML and GetNumLootItems()>0 then
                
                local playerNr
                local found=0;
                
                local slot=0;
                for i=1,GetNumLootItems() do
                    item2=GetLootSlotLink(i);
                    if (item2~=nil) and item2==item then
                        slot=i;
                        found=found+1;
                        break;
                    end;
                end;
                for i=1,MAX_RAID_MEMBERS do
                    if playerName == GetMasterLootCandidate(slot,i) then playerNr=i; found=found+1; break; end;
                end
                if found==2 then
                    GiveMasterLoot(slot, playerNr)
                end;
                if found~=2 then
                    self:Print("Unable to award player with item. Try to do it manually, but most likly player is not permited to take that item.");
                end;
            end;
            
        else
            self:Print("Synchronization/communication error has occured, cannot award player "..playerName.." with "..item.." becouse he does not have the amount of points "..amount.." he used in auction.");
            return;
        end
    else
        self:Print("No bids were recevied.");
    end;
    v.awardButton:Disable();
end

function A:AskForVersion(arg)
    self:Send("askForVersion",nil,arg);
end;

function A:SendStartTimer(timer)
    self:Send("startTimer",timer, "RAID");
end;

function A:AskForVersion(dist)
    self:Send("askForVersion",nil,dist);
end
function A:AddAction(name,amount,reason)
    A:CheckCommand("AddAction",name,amount,reason);
end

function A:SetAlt(main,alt)
    A:CheckCommand("SetAlt",main,alt);
end

function A:CheckCommand(typ,arg1,arg2,arg3)
    if CanEditOfficerNote() then
        if typ=="AddAction" then
            A.log:AddAction(arg1,arg2,arg3);
        elseif typ=="SetAlt" then
            A.log:SetAlt(arg1,arg2);
        end;
    end;
end


local realmName="-"..GetRealmName();
function A:OnCommReceived(prefix, message, distribution, sender)
    sender=string.gsub(sender, realmName, "");
    suc,data=self:Deserialize(message);
    
    if suc then
        local msg=data.msg;
        local data=data.data
        if (prefix==B.prefix) then
            
            if msg=="LFDKPManager" then
                if CanEditOfficerNote() then
                    A:Send("IAMDKPManager",nil,"WHISPER",sender);
                end;
            elseif msg=="startBids" then
                if A.biddingInProgress and sender~=UnitName("player") then
                    A:SetBiddingState(false);
                    A:Print("Bidding stoped, as session was overtaken by "..sender);
                end
            elseif msg=="playerBid" then
                A:AnalizeBid(tonumber(data),sender);
            elseif msg=="transferDKP" then
                if CanEditOfficerNote() then
                    if A.DB.canTransferDKP then
                        if GRI:GetNet(sender)>=tonumber(data.amount) and tonumber(data.amount)>0 then
                            A:AddAction(sender,-tonumber(data.amount),A.transferTo..data.transferTo);
                        elseif tonumber(data.amount)<=0 then
                            A:Send("error","The amount of points to transfer must be greater then 0.","WHISPER",sender);
                        else
                            A:Send("error","You do not have enaugh points. Currently you have "..GRI:GetNet(sender).." when you are trying to transfer "..data.amount.." to player "..data.transferTo..".","WHISPER",sender);
                        end
                    else
                        A:Send("error",UnitName("player").." settings do not allow dkp transfer, sorry. For more information ask an officer.","WHISPER",sender);
                    end
                end
            elseif msg=="returnVersion" then
                local ver=data;
                A:Print(B:GetPlayerTextColor(sender)..sender..B.colors["close"].." confirms echo. Addon version: "..B.colors["blue"]..data..B.colors["close"]);
				--[[if ver<B:GetVersion() and A.DB.broadcastBidderUpdate then --TODO: remove or finish
					--SendAddonMessage("QDKP_ksqBid","error#".."There is new version available: "..B.colors["red"]..B.ver,"WHISPER",sender);
                end]]
            end
            
        end
    end
end


local function noWhisperSpam(self,event,msg)
    return string.find(msg,"<DKP.Manager>.+");
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM",noWhisperSpam)












