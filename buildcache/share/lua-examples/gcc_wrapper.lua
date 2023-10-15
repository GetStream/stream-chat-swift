-- match(.*(gcc|g\+\+|clang|clang\+\+).*)

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
-- This is a re-implementation of the C++ class gcc_wrapper_t.
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

local function make_preprocessor_cmd (args, preprocessed_file)
  local preprocess_args = {}

  -- Drop arguments that we do not want/need.
  local drop_next_arg = false
  for i, arg in ipairs(args) do
    local drop_this_arg = drop_next_arg
    drop_next_arg = false
    if arg == "-c" then
      drop_this_arg = true
    elseif arg == "-o" then
      drop_this_arg = true
      drop_next_arg = true
    end
    if not drop_this_arg then
      table.insert(preprocess_args, arg)
    end
  end

  -- Append the required arguments for producing preprocessed output.
  table.insert(preprocess_args, "-E")
  table.insert(preprocess_args, "-P")
  table.insert(preprocess_args, "-o")
  table.insert(preprocess_args, preprocessed_file)

  return preprocess_args
end

local function is_source_file (path)
  local ext = bcache.get_extension(path):lower()
  return (ext == ".cpp") or (ext == ".cc") or (ext == ".cxx") or (ext == ".c")
end


-------------------------------------------------------------------------------
-- Wrapper interface implementation.
-------------------------------------------------------------------------------

function get_capabilities ()
  -- We can use hard links with GCC since it will never overwrite already
  -- existing files.
  return { "hard_links" }
end

function get_build_files ()
  local files = {}
  local found_object_file = false
  for i = 2, #ARGS do
    local next_idx = i + 1
    if (ARGS[i] == "-o") and (next_idx <= #ARGS) then
      if found_object_file then
        error("Only a single target object file can be specified.")
      end
      files["object"] = ARGS[next_idx]
      found_object_file = true
    elseif (ARGS[i] == "-ftest-coverage") then
      error("Code coverage data is currently not supported.")
    end
  end
  if not found_object_file then
    error("Unable to get the target object file.")
  end
  return files
end

function get_program_id ()
  -- TODO(m): Add things like executable file size too.

  -- Get the version string for the compiler.
  local result = bcache.run({ARGS[1], "--version"})
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
      -- Does this argument specify a file (we don't want to hash those).
      local is_arg_plus_file_name = (arg == "-I") or (arg == "-MF") or
                                    (arg == "-MT") or (arg == "-MQ") or
                                    (arg == "-o")

      -- Generally unwanted argument (things that will not change how we go
      -- from preprocessed code to binary object files)?
      local first_two_chars = arg:sub(1, 2)
      local is_unwanted_arg = (first_two_chars == "-I") or
                              (first_two_chars == "-D") or
                              (first_two_chars == "-M") or
                              is_source_file(arg)

      if is_arg_plus_file_name then
        skip_next_arg = true
      elseif not is_unwanted_arg then
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
    if arg == "-c" then
      is_object_compilation = true
    elseif arg == "-o" then
      has_object_output = true
    elseif arg:sub(1, 1) == "@" then
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
