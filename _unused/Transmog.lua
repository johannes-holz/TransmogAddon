folder, core = ...


Transmog = {}

Transmog.GetBalance = function()
    local bal = core.GetBalance()

    return bal.shards, bal.shardsLimit, bal.weekly.total, bal.weekly.totalLimit, bal.weekly.raid, bal.weekly.raidLimit, bal.weekly.lfg, bal.weekly.lfgLimit, bal.weekly.arena, bal.weekly.arenaLimit, bal.weekly.bg, bal.weekly.bgLimit
end

