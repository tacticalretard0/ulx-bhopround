local CATEGORY_NAME = "Voting"

if CLIENT then

  local function Autohop(cmd)

    local ply  = LocalPlayer()
    local mt   = ply:GetMoveType()
    local team = ply:Team()

    if mt == MOVETYPE_WALK && team != TEAM_SPECTATOR then

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
    else
      hook.Remove("CreateMove", "BhopRound.Autohop")
    end
  end)
end

if SERVER then
  util.AddNetworkString("BhopRound.AutohopToggle")
end

function ulx.BhopVote(calling_ply, AirAccel, AutohopDisable, StickToGround)

  -- 10 minute cooldown

  if !(StartedVoteTime) then StartedVoteTime = -600 end

  if (CurTime() - StartedVoteTime) < 600 then

    ULib.tsayError(calling_ply, "Please wait " .. tostring(math.floor(600 - (CurTime() - StartedVoteTime))) .. " seconds before starting another bhop round vote")

  else

    StartedVoteTime = CurTime()

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

          --print("round start")
          if !(AutohopDisable) then
            --print("autohop is enabled")
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
          end -- if !(AutohopDisable) then

          -- Add hook to end bhop round inside of the start hook so that it resets everything at the end of the next round, not this one
          hook.Add("HASRoundEnded", "BhopRound.RoundEnded", function()
            --print("round end")

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

          end) -- hook.Add("HASRoundEnded", "BhopRound.RoundEnded", function()
        end) -- hook.Add("HASRoundStarted", "BhopRound.RoundStarted", function()
      end -- if winner == 2 then ... else
    end) -- ulx.doVote(function()
  end -- if (CurTime() - StartedVoteTime) < 600 then ... else
end -- function ulx.BhopVote()


local ULXBhopRound = ulx.command(CATEGORY_NAME, "ulx bhopround", ulx.BhopVote, "!bhopround")

ULXBhopRound:addParam{type=ULib.cmds.NumArg, hint="sv_airaccelerate", min=0, default=2000, ULib.cmds.optional, ULib.cmds.round}

ULXBhopRound:addParam{type=ULib.cmds.BoolArg, hint="disable autohop", ULib.cmds.optional}

ULXBhopRound:addParam{type=ULib.cmds.BoolArg, hint="enable sv_sticktoground", ULib.cmds.optional}
