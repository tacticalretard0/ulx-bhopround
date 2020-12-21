local CATEGORY_NAME = "Voting"

if SERVER then
  util.AddNetworkString("BhopRound.AutohopToggle")
end


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

local VotedThisRound = false

function ulx.BhopVote(calling_ply, AutohopDisable)

  print("command run")
  if VotedThisRound then

    print("replace me with something to do if we already created a vote this round")

  else

    VotedThisRound = true

    hook.Add("HASRoundStarted", "BhopRound.RoundStarted", function()
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

        -- remove hooks

        hook.Remove("HASRoundStarted", "BhopRound.RoundStarted")   -- Round start
        hook.Remove("HASRoundEnded", "BhopRound.RoundEnded")       -- Round end

        hook.Remove("HASPlayerNetReady", "BhopRound.PlayerJoined") -- Player join

        -- new round, can vote again (maybe remove this later so command only works once per map, or add time cooldown?)
        VotedThisRound = false

      end) -- hook.Add("HASRoundEnded", "BhopRound.RoundEnded", function()
    end) -- hook.Add("HASRoundStarted", "BhopRound.RoundStarted", function()
  end -- if VotedThisRound then ... else
end -- function ulx.BhopVote(calling_ply, AutohopDisable)


local ULXBhopRound = ulx.command(CATEGORY_NAME, "ulx bhopround", ulx.BhopVote, "!bhopround")

ULXBhopRound:addParam{type=ULib.cmds.BoolArg, hint="disable autohop", ULib.cmds.optional}
