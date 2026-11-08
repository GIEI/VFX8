function love.load()
  local ok, err = xpcall(function()
    for _, name in ipairs({"rain_contract.lua", "snow_contract.lua"}) do
      local contract, load_error = love.filesystem.load(name)
      assert(contract, load_error)
      contract()
    end
  end, debug.traceback)
  if not ok then print(err) end
  local result_path = os.getenv("VFX8_TEST_RESULT")
  if result_path then
    local file = io.open(result_path, "w")
    assert(file, "Unable to write weather contract result")
    file:write(ok and "passed" or tostring(err))
    file:close()
  end
  love.event.quit(ok and 0 or 1)
end
