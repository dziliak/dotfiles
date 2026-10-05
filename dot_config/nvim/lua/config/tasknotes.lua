local M = {}

local defaults = {
  mtn = "mtn",
  vault = vim.fn.expand("~/Documents/Obsidian/obsidian_vault"),
}

M.config = vim.deepcopy(defaults)
M._setup = false

local is_list = vim.islist or vim.tbl_islist

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, {
    title = "TaskNotes",
  })
end

local function trim(value)
  return vim.trim(value or "")
end

local function run(args, opts, callback)
  opts = opts or {}

  if vim.fn.executable(M.config.mtn) ~= 1 then
    notify("'mtn' was not found in PATH.\nInstall it with:\n  npm install -g mdbase-tasknotes", vim.log.levels.ERROR)
    return
  end

  local command = { M.config.mtn }
  vim.list_extend(command, args)

  local system_opts = {
    text = true,
  }

  -- Using the vault as cwd also gives mtn a useful fallback if
  -- collectionPath has not been configured.
  if M.config.vault and vim.fn.isdirectory(M.config.vault) == 1 then
    system_opts.cwd = M.config.vault
  end

  vim.system(command, system_opts, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local message = trim(result.stderr)

        if message == "" then
          message = trim(result.stdout)
        end

        if message == "" then
          message = "mtn exited with code " .. tostring(result.code)
        end

        notify(message, vim.log.levels.ERROR)
        return
      end

      if opts.success then
        notify(opts.success)
      end

      if callback then
        callback(result.stdout or "", result)
      end
    end)
  end)
end

local function decode_json(output)
  local ok, result = pcall(vim.json.decode, output)

  if ok then
    return result
  end

  -- Be tolerant if a future mtn version prints a warning before
  -- the actual JSON.
  local first_array = output:find("%[")
  local last_array = output:match(".*()%]")

  if first_array and last_array and last_array >= first_array then
    local candidate = output:sub(first_array, last_array)

    ok, result = pcall(vim.json.decode, candidate)

    if ok then
      return result
    end
  end

  local first_object = output:find("{")
  local last_object = output:match(".*()}")

  if first_object and last_object and last_object >= first_object then
    local candidate = output:sub(first_object, last_object)

    ok, result = pcall(vim.json.decode, candidate)

    if ok then
      return result
    end
  end

  return nil
end

local function unwrap_tasks(data)
  if type(data) ~= "table" then
    return nil
  end

  if is_list(data) then
    return data
  end

  for _, key in ipairs({
    "tasks",
    "records",
    "items",
    "results",
    "data",
  }) do
    if type(data[key]) == "table" and is_list(data[key]) then
      return data[key]
    end
  end

  if type(data.result) == "table" then
    return unwrap_tasks(data.result)
  end

  return nil
end

local function field(raw, name)
  local containers = {
    raw,
    raw.data,
    raw.fields,
    raw.frontmatter,
    raw.record,
  }

  for _, container in ipairs(containers) do
    if type(container) == "table" and container[name] ~= nil then
      return container[name]
    end
  end

  return nil
end

local function value_to_string(value)
  if value == nil then
    return ""
  end

  if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
    return tostring(value)
  end

  if type(value) == "table" then
    if value.value ~= nil then
      return value_to_string(value.value)
    end

    if value.date ~= nil then
      return value_to_string(value.date)
    end

    if is_list(value) then
      local parts = {}

      for _, item in ipairs(value) do
        local text = value_to_string(item)

        if text ~= "" then
          table.insert(parts, text)
        end
      end

      return table.concat(parts, ", ")
    end
  end

  return tostring(value)
end

local function task_path(raw)
  local path = field(raw, "path")

  if type(path) == "string" then
    return path
  end

  if type(raw.file) == "table" then
    path = raw.file.path

    if type(path) == "string" then
      return path
    end
  end

  if type(raw._file) == "table" then
    path = raw._file.path

    if type(path) == "string" then
      return path
    end
  end

  return nil
end

local function filename_title(path)
  if not path then
    return nil
  end

  local name = path:match("([^/]+)$")

  if not name then
    return nil
  end

  return name:gsub("%.md$", "")
end

local function normalize_task(raw)
  local path = task_path(raw)

  local title = value_to_string(field(raw, "title"))

  if title == "" and type(raw.file) == "table" then
    title = value_to_string(raw.file.title or raw.file.name)
  end

  if title == "" then
    title = filename_title(path) or "(untitled)"
  end

  title = title:gsub("%.md$", "")

  return {
    raw = raw,
    path = path,
    title = title,
    status = value_to_string(field(raw, "status")),
    priority = value_to_string(field(raw, "priority")),
    due = value_to_string(field(raw, "due")),
    scheduled = value_to_string(field(raw, "scheduled")),
    tags = value_to_string(field(raw, "tags")),
    contexts = value_to_string(field(raw, "contexts")),
    projects = value_to_string(field(raw, "projects")),
  }
end

local function list_tasks(args, callback)
  local command = { "list" }

  vim.list_extend(command, args or {})
  table.insert(command, "--json")

  run(command, {}, function(output)
    local decoded = decode_json(output)
    local raw_tasks = unwrap_tasks(decoded)

    if not raw_tasks then
      notify("Could not decode output from 'mtn list --json'.", vim.log.levels.ERROR)
      return
    end

    local tasks = {}

    for _, raw in ipairs(raw_tasks) do
      table.insert(tasks, normalize_task(raw))
    end

    callback(tasks)
  end)
end

local function absolute_path(path)
  if not path or path == "" then
    return nil
  end

  path = vim.fn.expand(path)

  if path:sub(1, 1) == "/" then
    return path
  end

  local vault = M.config.vault:gsub("/+$", "")

  return vault .. "/" .. path:gsub("^/+", "")
end

local function task_reference(task)
  if task.path and task.path ~= "" then
    local path = vim.fn.expand(task.path)
    local vault = M.config.vault:gsub("/+$", "")

    if path:sub(1, #vault + 1) == vault .. "/" then
      return path:sub(#vault + 2)
    end

    return path
  end

  return task.title
end

local function show_output(title, output)
  vim.cmd("botright 12new")

  local buffer = vim.api.nvim_get_current_buf()

  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "text"

  local safe_title = title:gsub("[^%w_-]", "_")

  pcall(vim.api.nvim_buf_set_name, buffer, "tasknotes://" .. safe_title .. "/" .. tostring(os.time()))

  local lines = vim.split(output or "", "\n", {
    plain = true,
  })

  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end

  if #lines == 0 then
    lines = { "(no output)" }
  end

  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

  vim.bo[buffer].modifiable = false
end

local function open_task(task)
  local path = absolute_path(task.path)

  if path and vim.fn.filereadable(path) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    return
  end

  -- Fallback if the JSON schema changes and a path cannot be resolved.
  run({ "show", task_reference(task) }, {}, function(output)
    show_output(task.title, output)
  end)
end

local function complete_task(task, callback)
  run({ "complete", task_reference(task) }, {
    success = "Completed: " .. task.title,
  }, callback)
end

local function archive_task(task, callback)
  run({ "archive", task_reference(task) }, {
    success = "Archived: " .. task.title,
  }, callback)
end

local function update_status(task, status, callback)
  run({
    "update",
    task_reference(task),
    "--status",
    status,
  }, {
    success = task.title .. " → " .. status,
  }, callback)
end

local function update_priority(task, priority, callback)
  run({
    "update",
    task_reference(task),
    "--priority",
    priority,
  }, {
    success = task.title .. " priority → " .. priority,
  }, callback)
end

local function prompt_status(task, callback)
  vim.ui.input({
    prompt = "Status: ",
    default = task.status ~= "" and task.status or nil,
  }, function(status)
    status = trim(status)

    if status == "" then
      if callback then
        callback()
      end
      return
    end

    update_status(task, status, callback)
  end)
end

local function prompt_priority(task, callback)
  vim.ui.input({
    prompt = "Priority: ",
    default = task.priority ~= "" and task.priority or nil,
  }, function(priority)
    priority = trim(priority)

    if priority == "" then
      if callback then
        callback()
      end
      return
    end

    update_priority(task, priority, callback)
  end)
end

local function start_timer(task, callback)
  vim.ui.input({
    prompt = "Timer description (optional): ",
  }, function(description)
    local command = {
      "timer",
      "start",
      task_reference(task),
    }

    description = trim(description)

    if description ~= "" then
      table.insert(command, "-d")
      table.insert(command, description)
    end

    run(command, {
      success = "Timer started: " .. task.title,
    }, callback)
  end)
end

local function task_picker(title, args, opts)
  opts = opts or {}

  list_tasks(args, function(tasks)
    local ok, Snacks = pcall(require, "snacks")

    if not ok then
      notify("snacks.nvim could not be loaded.", vim.log.levels.ERROR)
      return
    end

    local items = {}
    local all_have_files = true

    for index, task in ipairs(tasks) do
      local file = absolute_path(task.path)

      if not file or vim.fn.filereadable(file) ~= 1 then
        all_have_files = false
        file = nil
      end

      local searchable = table.concat({
        task.title,
        task.status,
        task.priority,
        task.due,
        task.scheduled,
        task.tags,
        task.contexts,
        task.projects,
      }, " ")

      table.insert(items, {
        idx = index,
        text = searchable,
        file = file,
        task = task,
      })
    end

    local function reopen()
      if opts.reopen == false then
        return
      end

      vim.schedule(function()
        task_picker(title, args, opts)
      end)
    end

    local picker_opts = {
      title = title,
      items = items,
      pattern = opts.pattern,

      format = function(item)
        local task = item.task

        local status = task.status ~= "" and task.status or "unknown"

        local metadata = {}

        if task.priority ~= "" then
          table.insert(metadata, task.priority)
        end

        if task.scheduled ~= "" then
          table.insert(metadata, "scheduled:" .. task.scheduled)
        end

        if task.due ~= "" then
          table.insert(metadata, "due:" .. task.due)
        end

        return {
          {
            string.format("[%-12s] ", status),
            "Comment",
          },
          {
            task.title,
            "Normal",
          },
          {
            #metadata > 0 and ("  " .. table.concat(metadata, "  ")) or "",
            "Comment",
          },
        }
      end,

      confirm = function(picker, item)
        picker:close()

        if not item or not item.task then
          return
        end

        if opts.on_confirm then
          opts.on_confirm(item.task)
        else
          open_task(item.task)
        end
      end,

      actions = {
        task_complete = function(picker, item)
          if not item or not item.task then
            return
          end

          local task = item.task
          picker:close()

          complete_task(task, reopen)
        end,

        task_status = function(picker, item)
          if not item or not item.task then
            return
          end

          local task = item.task
          picker:close()

          prompt_status(task, reopen)
        end,

        task_priority = function(picker, item)
          if not item or not item.task then
            return
          end

          local task = item.task
          picker:close()

          prompt_priority(task, reopen)
        end,

        task_timer = function(picker, item)
          if not item or not item.task then
            return
          end

          local task = item.task
          picker:close()

          start_timer(task, reopen)
        end,

        task_archive = function(picker, item)
          if not item or not item.task then
            return
          end

          local task = item.task
          picker:close()

          archive_task(task, reopen)
        end,
      },

      win = {
        input = {
          keys = {
            ["<C-x>"] = {
              "task_complete",
              mode = { "n", "i" },
              desc = "Complete task",
            },
            ["<C-s>"] = {
              "task_status",
              mode = { "n", "i" },
              desc = "Set status",
            },
            ["<C-p>"] = {
              "task_priority",
              mode = { "n", "i" },
              desc = "Set priority",
            },
            ["<C-t>"] = {
              "task_timer",
              mode = { "n", "i" },
              desc = "Start timer",
            },
          },
        },

        list = {
          keys = {
            ["x"] = {
              "task_complete",
              desc = "Complete task",
            },
            ["s"] = {
              "task_status",
              desc = "Set status",
            },
            ["p"] = {
              "task_priority",
              desc = "Set priority",
            },
            ["t"] = {
              "task_timer",
              desc = "Start timer",
            },
            ["a"] = {
              "task_archive",
              desc = "Archive task",
            },
          },
        },
      },
    }

    if all_have_files then
      picker_opts.preview = "file"
    end

    Snacks.picker.pick(picker_opts)
  end)
end

function M.new(text)
  text = trim(text)

  local function create(value)
    value = trim(value)

    if value == "" then
      return
    end

    run({ "create", value }, {
      success = "Task created.",
    })
  end

  if text ~= "" then
    create(text)
    return
  end

  vim.ui.input({
    prompt = "New task: ",
  }, create)
end

function M.list()
  task_picker("TaskNotes", {})
end

function M.today()
  task_picker("TaskNotes — Today", {
    "--where",
    "due == today() || scheduled == today()",
  })
end

function M.overdue()
  task_picker("TaskNotes — Overdue", {
    "--overdue",
  })
end

function M.due(filter)
  filter = trim(filter)

  local function show(value)
    value = trim(value)

    if value == "" then
      return
    end

    task_picker("TaskNotes — Due " .. value, {
      "--due",
      value,
    })
  end

  if filter ~= "" then
    show(filter)
    return
  end

  vim.ui.input({
    prompt = "Due filter: ",
    default = "today",
  }, show)
end

function M.search(query)
  query = trim(query)

  local function search(value)
    value = trim(value)

    if value == "" then
      return
    end

    run({ "search", value }, {}, function(output)
      show_output("Search " .. value, output)
    end)
  end

  if query ~= "" then
    search(query)
    return
  end

  vim.ui.input({
    prompt = "Search tasks: ",
  }, search)
end

function M.complete(reference)
  reference = trim(reference)

  if reference ~= "" then
    run({ "complete", reference }, {
      success = "Completed: " .. reference,
    })
    return
  end

  task_picker("Complete Task", {}, {
    reopen = false,

    on_confirm = function(task)
      complete_task(task)
    end,
  })
end

function M.status(status)
  status = trim(status)

  task_picker("Set Task Status", {}, {
    reopen = false,

    on_confirm = function(task)
      if status ~= "" then
        update_status(task, status)
      else
        prompt_status(task)
      end
    end,
  })
end

function M.priority(priority)
  priority = trim(priority)

  task_picker("Set Task Priority", {}, {
    reopen = false,

    on_confirm = function(task)
      if priority ~= "" then
        update_priority(task, priority)
      else
        prompt_priority(task)
      end
    end,
  })
end

function M.archive(reference)
  reference = trim(reference)

  if reference ~= "" then
    run({ "archive", reference }, {
      success = "Archived: " .. reference,
    })
    return
  end

  task_picker("Archive Task", {}, {
    reopen = false,

    on_confirm = function(task)
      archive_task(task)
    end,
  })
end

function M.timer_start(reference)
  reference = trim(reference)

  if reference ~= "" then
    run({
      "timer",
      "start",
      reference,
    }, {
      success = "Timer started: " .. reference,
    })
    return
  end

  task_picker("Start Task Timer", {}, {
    reopen = false,

    on_confirm = function(task)
      start_timer(task)
    end,
  })
end

function M.timer_stop()
  run({
    "timer",
    "stop",
  }, {
    success = "Task timer stopped.",
  })
end

function M.timer_status()
  run({
    "timer",
    "status",
  }, {}, function(output)
    notify(trim(output))
  end)
end

function M.timer_log(period)
  local command = {
    "timer",
    "log",
  }

  period = trim(period)

  if period ~= "" then
    table.insert(command, "--period")
    table.insert(command, period)
  end

  run(command, {}, function(output)
    show_output("Timer Log", output)
  end)
end

function M.stats()
  run({ "stats" }, {}, function(output)
    show_output("Stats", output)
  end)
end

function M.doctor()
  if vim.fn.executable(M.config.mtn) ~= 1 then
    notify("'mtn' is not available in PATH.", vim.log.levels.ERROR)
    return
  end

  run({ "--version" }, {}, function(version)
    run({
      "config",
      "--get",
      "collectionPath",
    }, {}, function(collection)
      notify(table.concat({
        "mtn: " .. trim(version),
        "mtn collection: " .. trim(collection),
        "Neovim vault: " .. M.config.vault,
      }, "\n"))
    end)
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  M.config.vault = vim.fn.expand(M.config.vault)

  if M._setup then
    return
  end

  M._setup = true

  vim.api.nvim_create_user_command("TaskNew", function(cmd)
    M.new(cmd.args)
  end, {
    nargs = "*",
    desc = "Create a TaskNotes task",
  })

  vim.api.nvim_create_user_command("TaskList", function()
    M.list()
  end, {
    desc = "List open TaskNotes tasks",
  })

  vim.api.nvim_create_user_command("TaskToday", function()
    M.today()
  end, {
    desc = "Show tasks due or scheduled today",
  })

  vim.api.nvim_create_user_command("TaskOverdue", function()
    M.overdue()
  end, {
    desc = "Show overdue tasks",
  })

  vim.api.nvim_create_user_command("TaskDue", function(cmd)
    M.due(cmd.args)
  end, {
    nargs = "*",
    desc = "Show tasks using an mtn due-date filter",
  })

  vim.api.nvim_create_user_command("TaskSearch", function(cmd)
    M.search(cmd.args)
  end, {
    nargs = "*",
    desc = "Full-text search TaskNotes",
  })

  vim.api.nvim_create_user_command("TaskComplete", function(cmd)
    M.complete(cmd.args)
  end, {
    nargs = "*",
    desc = "Complete a TaskNotes task",
  })

  vim.api.nvim_create_user_command("TaskStatus", function(cmd)
    M.status(cmd.args)
  end, {
    nargs = "?",
    desc = "Change a TaskNotes task status",
  })

  vim.api.nvim_create_user_command("TaskPriority", function(cmd)
    M.priority(cmd.args)
  end, {
    nargs = "?",
    desc = "Change a TaskNotes task priority",
  })

  vim.api.nvim_create_user_command("TaskArchive", function(cmd)
    M.archive(cmd.args)
  end, {
    nargs = "*",
    desc = "Archive a TaskNotes task",
  })

  vim.api.nvim_create_user_command("TaskTimerStart", function(cmd)
    M.timer_start(cmd.args)
  end, {
    nargs = "*",
    desc = "Start a TaskNotes timer",
  })

  vim.api.nvim_create_user_command("TaskTimerStop", function()
    M.timer_stop()
  end, {
    desc = "Stop the active TaskNotes timer",
  })

  vim.api.nvim_create_user_command("TaskTimerStatus", function()
    M.timer_status()
  end, {
    desc = "Show active TaskNotes timer",
  })

  vim.api.nvim_create_user_command("TaskTimerLog", function(cmd)
    M.timer_log(cmd.args)
  end, {
    nargs = "?",
    desc = "Show TaskNotes timer log",
  })

  vim.api.nvim_create_user_command("TaskStats", function()
    M.stats()
  end, {
    desc = "Show TaskNotes statistics",
  })

  vim.api.nvim_create_user_command("TaskDoctor", function()
    M.doctor()
  end, {
    desc = "Check TaskNotes/mtn integration",
  })
end

return M
