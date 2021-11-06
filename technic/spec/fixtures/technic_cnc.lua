
-- Load technic_cnc mod

mineunit:set_modpath("technic_cnc", "../technic_cnc")

mineunit:set_current_modname("technic_cnc")
sourcefile("../technic_cnc/init")
mineunit:restore_current_modname()
