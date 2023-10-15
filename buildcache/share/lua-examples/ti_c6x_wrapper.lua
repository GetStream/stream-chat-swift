-- match(.*cl6x.*)

-------------------------------------------------------------------------------
-- Copyright (c) 2018 Marcus Geelnard
--
-- This software is provided 'as-is', without any express or implied warranty.
-- In no event will the authors be held liable for any damages arising from the
-- use of this software.
--
-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it
-- freely, subject to the following restrictions:
--
--  1. The origin of this software must not be misrepresented; you must not
--     claim that you wrote the original software. If you use this software in
--     a product, an acknowledgment in the product documentation would be
--     appreciated but is not required.
--
--  2. Altered source versions must be plainly marked as such, and must not be
--     misrepresented as being the original software.
--
--  3. This notice may not be removed or altered from any source distribution.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- This is a Lua re-implementation of the TI C6000 DSP compiler wrapper,
-- ti_c6x_wrapper_t.
--
-- Note: The Lua and C++ implementations are not interchangeable (cache entries
-- produced by one of them will not produce a cache hit for the other). The
-- main purpose of this implementation is to serve as an example.
-------------------------------------------------------------------------------

require_std("io")
require_std("os")
require_std("string")
require_std("table")
require_std("bcache")


-------------------------------------------------------------------------------
-- Internal helper functions.
-------------------------------------------------------------------------------

local function starts_with (s, substr)
  return s:sub(1, #substr) == substr
end

local function make_preprocessor_cmd (args, preprocessed_file)
  local preprocess_args = {}

  -- Drop arguments that we do not want/need.
  local drop_next_arg = false
  for i, arg in ipairs(args) do
    local drop_this_arg = drop_next_arg
    drop_next_arg = false
    if (arg == "--compile_only") or
       starts_with(arg, "--output_file=") or
       starts_with(arg, "-pp") or
       starts_with(arg, "--preproc_") then
      drop_this_arg = true
    end
    if not drop_this_arg then
      table.insert(preprocess_args, arg)
    end
  end

  -- Append the required arguments for producing preprocessed output.
  table.insert(preprocess_args, "--preproc_only")
  table.insert(preprocess_args, "--output_file=" .. preprocessed_file)

  return preprocess_args
end

local function append_response_file (args, file_name)
  -- Load the response file into a string.
  local f = assert(io.open(file_name, "rb"))
  local args_string = f:read("*all")
  f:close()
  args_string = args_string:gsub("\n", " ")

  -- Split the arguments.
  local new_args = bcache.split_args(args_string)
  for i, arg in ipairs(new_args) do
    table.insert(args, arg)
  end

  return args
end


-------------------------------------------------------------------------------
-- Wrapper interface implementation.
-------------------------------------------------------------------------------

function resolve_args ()
  -- Iterate over all args and load any response files that we encounter.
  local new_args = {}
  for i, arg in ipairs(ARGS) do
    local response_file
    if starts_with(arg, "--cmd_file=") then
      response_file = arg:sub(12)
    elseif starts_with(arg, "-@") then
      response_file = arg:sub(3)
    end
    if response_file ~= nil then
      new_args = append_response_file(new_args, response_file)
    else
      table.insert(new_args, arg)
    end
  end

  -- Replace the old args with the new args.
  ARGS = new_args
end

function get_build_files ()
  local files = {}
  local found_object_file = false
  local found_dep_file = false
  for i = 2, #ARGS do
    local next_idx = i + 1
    if starts_with(ARGS[i], "--output_file=") then
      if found_object_file then
        error("Only a single target object file can be specified.")
      end
      files["object"] = ARGS[i]:sub(15)
      found_object_file = true
    elseif starts_with(ARGS[i], "-ppd=") or starts_with(ARGS[i], "--preproc_dependency=") then
      if found_dep_file then
        error("Only a single dependency file can be specified.")
      end
      local eq = ARGS[i]:find("=")
      files["dep"] = ARGS[i]:sub(eq + 1)
      found_dep_file = true
    end
  end
  if not found_object_file then
    error("Unable to get the target object file.")
  end
  return files
end

function get_program_id ()
  -- TODO(m): Add things like executable file size too.

  -- Get the help string from the compiler (it includes the version string).
  local result = bcache.run({ARGS[1], "--help"})
  if result.return_code ~= 0 then
    error("Unable to get the compiler version information string.")
  end

  return result.std_out
end

function get_relevant_arguments ()
  local filtered_args = {}

  -- The first argument is the compiler binary without the path.
  table.insert(filtered_args, bcache.get_file_part(ARGS[1]))

  -- Note: We always skip the first arg since we have handled it already.
  local skip_next_arg = true
  for i, arg in ipairs(ARGS) do
    if not skip_next_arg then
      -- Generally unwanted argument (things that will not change how we go
      -- from preprocessed code to binary object files)?
      local first_two_chars = arg:sub(1, 2)
      local is_unwanted_arg = (first_two_chars == "-I") or
                              starts_with(arg, "--include") or
                              starts_with(arg, "--preinclude=") or
                              (first_two_chars == "-D") or
                              starts_with(arg, "--define=") or
                              starts_with(arg, "--c_file=") or
                              starts_with(arg, "--cpp_file=") or
                              starts_with(arg, "--output_file=")

      if not is_unwanted_arg then
        table.insert(filtered_args, arg)
      end
    else
      skip_next_arg = false
    end
  end

  return filtered_args
end

function preprocess_source ()
  -- Check if this is a compilation command that we support.
  local is_object_compilation = false
  local has_object_output = false
  for i, arg in ipairs(ARGS) do
    if arg == "--compile_only" then
      is_object_compilation = true
    elseif starts_with(arg, "--output_file=") then
      has_object_output = true
    elseif starts_with(arg, "--cmd_file=") or starts_with(arg, "-@") then
      error("Response files are currently not supported.")
    end
  end
  if (not is_object_compilation) or (not has_object_output) then
    error("Unsupported compilation command.")
  end

  -- Run the preprocessor step.
  local preprocessed_file = os.tmpname()
  local preprocessor_args = make_preprocessor_cmd(ARGS, preprocessed_file)
  local result = bcache.run(preprocessor_args)
  if result.return_code ~= 0 then
    os.remove(preprocessed_file)
    error("Preprocessing command was unsuccessful.")
  end

  -- Read and return the preprocessed file.
  local f = assert(io.open(preprocessed_file, "rb"))
  local preprocessed_source = f:read("*all")
  f:close()
  os.remove(preprocessed_file)

  return preprocessed_source
end
