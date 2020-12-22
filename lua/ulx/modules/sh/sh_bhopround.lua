-- The category the command shows up in
local CATEGORY_NAME          = "Voting"

-- Which category are the jumppacks in?
local JUMPPACK_CATEGORY_NAME = "Jump Packs"

local SERVER_HAS_POINTSHOP   = istable(PS)

if CLIENT then

  -- Pointshop documentation says that this method is shared but it isn't, so i add it to client
  -- begin pointshop retardation
  local PLAYER = FindMetaTable("Player")

  function PLAYER:PS_NumItemsEquippedFromCategory(cat_name)
  	local count = 0

  	for item_id, item in pairs(self.PS_Items) do
  		local ITEM = PS.Items[item_id]
  		if ITEM.Category == cat_name and item.Equipped then
  			count = count + 1
  		end
  	end

  	return count
  end
  -- end pointshop retardation

  local function Autohop(cmd)

    local ply        = LocalPlayer()

    local mt         = ply:GetMoveType()
    local team       = ply:Team()
    local waterlevel = ply:WaterLevel()

    if mt == MOVETYPE_WALK && team != TEAM_SPECTATOR && waterlevel == 0 then

      if cmd:KeyDown(IN_JUMP) && !(ply:IsOnGround()) then
        cmd:RemoveKey(IN_JUMP)

      end -- if cmd:KeyDown(IN_JUMP) && !(ply:IsOnGround()) then
    end -- if mt == MOVETYPE_WALK && team != TEAM_SPECTATOR then
  end -- function Autohop(cmd)

  -- We got told to enable or disable autohop
  net.Receive("BhopRound.AutohopToggle", function(_, ply)

    -- Enable or disable it?
    BhopToggle = net.ReadBool()

    if BhopToggle then
      hook.Add("CreateMove", "BhopRound.Autohop", Autohop)

      -- Add clientside jumppack
      if SERVER_HAS_POINTSHOP then
        hook.Add("Move", "BhopRound.JumpPack", FakeJumppack)
      end

    else
      hook.Remove("CreateMove", "BhopRound.Autohop")
      -- Disable clientside jumppack
      hook.Remove("Move", "BhopRound.JumpPack")
    end
  end)
end

-- Shared jumppack support used with Move hook
local function FakeJumppack(ply, data)

  if ply:PS_NumItemsEquippedFromCategory(JUMPPACK_CATEGORY_NAME) > 0 then
    -- They aren't on the ground, so the fake jump pack should activate
    if !(ply:IsOnGround()) then
       data:SetVelocity( data:GetVelocity() + Vector(0,0,100)*FrameTime() )

    end
  end
end

if SERVER then
  util.AddNetworkString("BhopRound.AutohopToggle")
end

function ulx.BhopVote(calling_ply, AirAccel, AutohopDisable, StickToGround)

  -- 10 minute cooldown
  if !(StartedBhopVoteTime) then StartedBhopVoteTime = -600 end

  if (CurTime() - StartedBhopVoteTime) < 600 then

    ULib.tsayError(calling_ply, "Please wait " .. tostring(math.floor(600 - (CurTime() - StartedBhopVoteTime))) .. " seconds before starting another bhop round vote")

  else

    StartedBhopVoteTime = CurTime()

    ulx.doVote("Bhop round? (next round)", {"Yes", "No"}, function(results)

      local winner  = 2
      local highest = 0

      for option, votecount in pairs(results.results) do
        if votecount > highest then
          highest = votecount
          winner = option
        end
      end

      if winner == 2 then
        ULib.tsay(nil, "Vote results: Round will not be a bhop round.")
      else

        ULib.tsay(nil, "Vote Passed! Next round will be a bhop round")

        hook.Add("HASRoundStarted", "BhopRound.RoundStarted", function()

          -- Store convars so we can reset them
          local PreviousAirAccel      = GetConVar("sv_airaccelerate"):GetInt()
          local PreviousStickToGround = GetConVar("sv_sticktoground"):GetInt()

          -- Change convars
          RunConsoleCommand("sv_airaccelerate", AirAccel)
          RunConsoleCommand("sv_sticktoground", StickToGround && 1 || 0)

          if !(AutohopDisable) then
            -- Tell players to use autohop
            net.Start("BhopRound.AutohopToggle")
              net.WriteBool(true)
            net.Broadcast()

            -- For when a player joins mid round
            hook.Add("HASPlayerNetReady", "BhopRound.PlayerJoined", function(ply)
              net.Start("BhopRound.AutohopToggle")
                net.WriteBool(true)
              net.Send(ply)
            end) -- hook.Add("HASPlayerNetReady", "BhopRound.PlayerJoined", function(ply)

            -- Enable jumppack serverside
            if SERVER_HAS_POINTSHOP then
              hook.Add("Move", "BhopRound.JumpPack", FakeJumppack)
            end
          end -- if !(AutohopDisable) then

          -- Add hook to end bhop round inside of the start hook so that it resets everything at the end of the next round, not this one
          hook.Add("HASRoundEnded", "BhopRound.RoundEnded", function()

            -- Tell players to stop using autohop
            net.Start("BhopRound.AutohopToggle")
              net.WriteBool(false)
            net.Broadcast()

            -- Reset convars
            RunConsoleCommand("sv_airaccelerate", PreviousAirAccel)
            RunConsoleCommand("sv_sticktoground", PreviousStickToGround)

            -- remove hooks
            hook.Remove("HASRoundStarted", "BhopRound.RoundStarted")   -- Round start
            hook.Remove("HASRoundEnded", "BhopRound.RoundEnded")       -- Round end

            hook.Remove("HASPlayerNetReady", "BhopRound.PlayerJoined") -- Player join

            hook.Remove("Move", "BhopRound.JumpPack")       -- Serverside jumppack

          end) -- hook.Add("HASRoundEnded", "BhopRound.RoundEnded", function()
        end) -- hook.Add("HASRoundStarted", "BhopRound.RoundStarted", function()
      end -- if winner == 2 then ... else
    end) -- ulx.doVote(function()
  end -- if (CurTime() - StartedBhopVoteTime) < 600 then ... else
end -- function ulx.BhopVote()


local ULXBhopRound = ulx.command(CATEGORY_NAME, "ulx bhopround", ulx.BhopVote, "!bhopround")

ULXBhopRound:addParam{type=ULib.cmds.NumArg, hint="sv_airaccelerate", min=0, default=2000, ULib.cmds.optional, ULib.cmds.round}

ULXBhopRound:addParam{type=ULib.cmds.BoolArg, hint="disable autohop", ULib.cmds.optional}

ULXBhopRound:addParam{type=ULib.cmds.BoolArg, hint="enable sv_sticktoground", ULib.cmds.optional}

ULXBhopRound:defaultAccess(ULib.ACCESS_ADMIN)

ULXBhopRound:help("Enables autohop and increases sv_airaccelerate next round")
