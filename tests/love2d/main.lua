function love.load()
  local event_quit = love.event.quit
  local ok, err = xpcall(function()
    local names = {"particle_contract.lua", "pseudo3d_contract.lua", "pixel_deform_contract.lua", "screen_fx_contract.lua", "palette_contract.lua", "flames_contract.lua", "electricity_contract.lua"}
    for i = 1, #names do
      local contract, load_error = love.filesystem.load(names[i])
      assert(contract, load_error)
      contract()
    end
  end, debug.traceback)
  if not ok then print(err) end
  local result_path = os.getenv("VFX8_TEST_RESULT")
  if result_path then
    local result_file = io.open(result_path, "w")
    if result_file then
      result_file:write(ok and "passed" or tostring(err))
      result_file:close()
    else
      ok, err = false, "Unable to write LÖVE contract result"
      print(err)
    end
  end
  event_quit(ok and 0 or 1)
end
