local function print_r (t, indent, done)
  done = done or {}
  indent = indent or ''
  local nextIndent -- Storage for next indentation value
  for key, value in pairs (t) do
    if type (value) == "table" and not done [value] then
      nextIndent = nextIndent or
          (indent .. string.rep(' ',string.len(tostring (key))+2))
          -- Shortcut conditional allocation
      done [value] = true
      print (indent .. "[" .. tostring (key) .. "] => Table {");
      print  (nextIndent .. "{");
      print_r (value, nextIndent .. string.rep(' ',2), done)
      print  (nextIndent .. "}");
    else
      print  (indent .. "[" .. tostring (key) .. "] => " .. tostring (value).."")
    end
  end
end

privs:register("teleport:everybody:coordinates", false)
privs:register("teleport:everybody:coordinates", true, "admin")
privs:register("teleport:everybody:coordinates", true, "admin")
privs:register("drive:car")
privs:register("drive:car:safe:a:b:c")

privs:allow("drive:car", "@admin")
--privs:deny("drive:car:safe:a", "xyz")
print(privs:check("drive:car:safe:a:b:c", "xyz"))
privs:join("xyz", "admin")
print(privs:check("drive:car:safe:a:b:c", "xyz"))
privs:deny("drive:car:safe", "xyz")
print(privs:check("drive:car:safe:a:b:c", "xyz"))
--privs:allow("drive:car:safe", "xyz")
--privs:save()
--privs:reload()
--print_r(privs:get(""))

print("--debug finished--")
