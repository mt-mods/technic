
local maxvel = vector.new(0.8, 0.8, 0.8)
local minvel = -maxvel
local acceleration = vector.zero()

core.register_abm({
  nodenames = {"technic:hv_nuclear_reactor_core_active"},
  interval = 10,
  chance = 1,
  action = function(pos, node)
    core.add_particlespawner({
      amount = 50,
      time = 10,
      minpos = pos:offset(-0.5, -0.5, -0.5),
      maxpos = pos:offset(0.5, 0.5, 0.5),
      minvel = minvel,
      maxvel = maxvel,
      minacc = acceleration,
      maxacc = acceleration,
      minexptime = 0.5,
      maxexptime = 2,
      minsize = 1,
      maxsize = 2,
      texture = "technic_blueparticle.png",
      glow = 5
    })
  end
})
