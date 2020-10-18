/*

TODO:

add voting | ulx.doVote( string title, table options, function callback,   |   timeout, filter, noecho, ... )
                                                                                                true


-add sv_sticktoground option -Done

-add autohop option (make autohop optional) -Done

remove old commented code

improve autohop code

add jump pack support

-?fix default values not working on airaccel and sticktoground arguments -Done? (might have problems with typing command vs using menu)

don't let spectators autohop

tell clients to enable autohop when they connect mid round

don't let players in ulx noclip autohop

*/



local CATEGORY_NAME = "Voting"

if CLIENT then

  local function Autohop(cmd)

    if cmd:KeyDown(IN_JUMP) then
      if !LocalPlayer():IsOnGround() then
        cmd:RemoveKey(IN_JUMP)
      end

    end

  end


  net.Receive("BhopRound.AutohopToggle", function()

    local toggle = net.ReadBool()

    if toggle then
      hook.Add("CreateMove", "BhopRound.AutohopHook", Autohop)
    else
      hook.Remove("CreateMove", "BhopRound.AutohopHook")
    end

  end)

end

if SERVER then

  util.AddNetworkString("BhopRound.AutohopToggle")

  local RanStartHook = false

  function StartBhopRound(AirAccel, AutohopDisable, DisableStickToGround)
    -- change convars
    RunConsoleCommand("sv_airaccelerate", AirAccel)
    RunConsoleCommand("sv_sticktoground", DisableStickToGround)

    -- tell clients to start using autohop
    if !(AutohopDisable) then
      net.Start("BhopRound.AutohopToggle")
        net.WriteBool(true)
      net.Broadcast()
    end
  end

  function EndBhopRound(PreviousAirAccel, PreviousStickToGround)
    -- tell clients to stop using autohop
    if !(AutohopDisable) then
      net.Start("BhopRound.AutohopToggle")
        net.WriteBool(false)
      net.Broadcast()
    end

    -- reset convars
    RunConsoleCommand("sv_airaccelerate", PreviousAirAccel)
    RunConsoleCommand("sv_sticktoground", PreviousStickToGround)

    -- remove hooks
    hook.Remove("HASRoundStarted", "BhopRound.RoundStart")
    hook.Remove("HASRoundEnded", "BhopRound.RoundEnd")

  end

end

function ulx.BhopRound(ply, AirAccel, AutohopDisable, DisableStickToGround)
  if SERVER then

    local DisableStickToGround = !(DisableStickToGround) -- flip bool
    local DisableStickToGround = DisableStickToGround and 1 or 0 -- convert bool to int

      -- hook for next round start
      hook.Add("HASRoundStarted", "BhopRound.RoundStart", function()

        -- if the seeker leaves, run all this code again for when the round restarts with a new seeker
        if !(RanStartHook) then
          RanStartHook = true
          -- store convars so we can reset them after the round ends
          local PreviousAirAccel = GetConVar("sv_airaccelerate"):GetInt()
          local PreviousStickToGround = GetConVar("sv_sticktoground"):GetInt()

          StartBhopRound(AirAccel, AutohopDisable, DisableStickToGround)

          -- add hook to end bhop round inside of the start hook so that it resets everything at the end of the next round, not this one
          hook.Add("HASRoundEnded", "BhopRound.RoundEnd", function()

            RanStartHook = false
            EndBhopRound(PreviousAirAccel, PreviousStickToGround)

        end) -- HASRoundEnded
      end -- if !(RanStartHook) then
    end) -- HASRoundStarted
  end -- if SERVER then
end -- function ulx.BhopRound

local bhop = ulx.command(CATEGORY_NAME, "ulx bhopround", ulx.BhopRound, "!bhopround")
bhop:addParam{type=ULib.cmds.NumArg, hint="sv_airaccelerate", min=0, default=2000, ULib.cmds.optional, ULib.cmds.round}

bhop:addParam{type=ULib.cmds.BoolArg, hint="disable autohop", ULib.cmds.optional}

bhop:addParam{type=ULib.cmds.BoolArg, hint="disable sv_sticktoground", ULib.cmds.optional}


bhop:defaultAccess(ULib.ACCESS_ADMIN)
bhop:help("Enables autohop and increases sv_airaccelerate next round")
