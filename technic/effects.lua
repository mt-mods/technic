
local offset = vector.offset

local maxvel = vector.new( 0.8, 0.8, 0.8)
local minvel = vector.new(-0.8,-0.8,-0.8)
local acceleration = vector.new(0, 0, 0)

core.register_abm({
  nodenames = {"technic:hv_nuclear_reactor_core_active"},
  interval = 10,
  chance = 1,
  action = function(pos, node)
    core.add_particlespawner({
      amount = 50,
      time = 10,
      minpos = offset(pos,-0.5,-0.5,-0.5),
      maxpos = offset(pos, 0.5, 0.5, 0.5),
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
