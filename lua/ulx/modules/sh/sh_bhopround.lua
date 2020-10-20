/*

TODO:

add voting | ulx.doVote( string title, table options, function callback,   |   timeout, filter, noecho, ... )
                                                                                                true


-add sv_sticktoground option -Done

-add autohop option (make autohop optional) -Done

remove old commented code

improve autohop code

-?fix default values not working on airaccel and sticktoground arguments -Done? (might have problems with typing command vs using menu)

*/



local CATEGORY_NAME = "Voting"

if CLIENT then

  local function Autohop(cmd)

    local ply = LocalPlayer()
    local mt = ply:GetMoveType()
    local team = ply:Team()

    if mt != MOVETYPE_NOCLIP && team != TEAM_SPECTATOR then

      if cmd:KeyDown(IN_JUMP) && !(ply:IsOnGround()) then
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

  BhopRound = {}

  BhopRound.RanStartHook = false
  BhopRound.ServerHasPointshop = false

  -- Is pointshop on the server?
  if istable(PS) then
    -- Yes
    BhopRound.ServerHasPointshop = true

    -- The name of the category with jumppacks, change if it has a different name
    BhopRound.JUMPPACK_CATEGORY_NAME = "Jump Packs"

  end

  function BhopRound.FakeJumppack(ply, data)

    if ply:PS_NumItemsEquippedFromCategory(BhopRound.JUMPPACK_CATEGORY_NAME) > 0 then
      -- They aren't on the ground, so the fake jump pack should activate
      if !(ply:IsOnGround()) then
  	     data:SetVelocity( data:GetVelocity() + Vector(0,0,100)*FrameTime() )

      end
    end
  end

  function BhopRound.StartBhopRound(AirAccel, AutohopDisable, DisableStickToGround)
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

  function BhopRound.EndBhopRound(PreviousAirAccel, AutohopDisable, PreviousStickToGround)
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
    hook.Remove("HASPlayerNetReady", "BhopRound.PlayerJoin")
    hook.Remove("Move", "BhopRound.FakeJumppack")
    hook.Remove("HASRoundEnded", "BhopRound.RoundEnd")

  end
end

function ulx.BhopRound(ply, AirAccel, AutohopDisable, DisableStickToGround)

  -- Convert bool to int
  DisableStickToGround = DisableStickToGround and 1 or 0

    -- hook for next round start
  hook.Add("HASRoundStarted", "BhopRound.RoundStart", function()

    -- if the seeker leaves, don't run all this code again for when the round restarts with a new seeker
    if !(BhopRound.RanStartHook) then
      BhopRound.RanStartHook = true
      -- store convars so we can reset them after the round ends
      local PreviousAirAccel = GetConVar("sv_airaccelerate"):GetInt()
      local PreviousStickToGround = GetConVar("sv_sticktoground"):GetInt()

      -- Start the bhop round
      BhopRound.StartBhopRound(AirAccel, AutohopDisable, DisableStickToGround)

      -- Add hooks
      -- Let players autohop if they join mid round
      hook.Add("HASPlayerNetReady", "BhopRound.PlayerJoin", function(ply)
        net.Start("BhopRound.AutohopToggle")
          net.WriteBool(true)
        net.Send(ply)
      end)

      -- Pointshop jump pack
      if BhopRound.ServerHasPointshop then
        hook.Add("Move", "BhopRound.FakeJumppack", BhopRound.FakeJumppack)
      end

      -- add hook to end bhop round inside of the start hook so that it resets everything at the end of the next round, not this one
      hook.Add("HASRoundEnded", "BhopRound.RoundEnd", function()

        BhopRound.RanStartHook = false
        BhopRound.EndBhopRound(PreviousAirAccel, AutohopDisable, PreviousStickToGround)

      end) -- HASRoundEnded
    end -- if !(BhopRound.RanStartHook) then
  end) -- HASRoundStarted
end -- function ulx.BhopRound

-- Create command
local ULXBhopRound = ulx.command(CATEGORY_NAME, "ulx bhopround", ulx.BhopRound, "!bhopround")
ULXBhopRound:addParam{type=ULib.cmds.NumArg, hint="sv_airaccelerate", min=0, default=2000, ULib.cmds.optional, ULib.cmds.round}

ULXBhopRound:addParam{type=ULib.cmds.BoolArg, hint="disable autohop", ULib.cmds.optional}

ULXBhopRound:addParam{type=ULib.cmds.BoolArg, hint="enable sv_sticktoground", ULib.cmds.optional}


ULXBhopRound:defaultAccess(ULib.ACCESS_ADMIN)
ULXBhopRound:help("Enables autohop and increases sv_airaccelerate next round")
