local run = require "ch.run_test"

local function iterate_cases()
    local cwd = vim.fn.getcwd()
    local ac, cases = 0, 0
    local results = {}
    local run_cmd = "~/code/a.out"
    for _, input_file in
        ipairs(require("plenary.scandir").scan_dir(cwd, {
            search_pattern = "input%d+",
            depth = 1,
        }))
    do
        local result, status =
            run.run_test(string.sub(input_file, string.len(cwd) - string.len(input_file) + 1), run_cmd)
        vim.list_extend(results, result)
        if status == 1 then
            ac = ac + 1
        end
        cases = cases + 1
    end
    return ac, cases, results
end

local function display_results(ac, cases, results)
    local header = "   RESULTS: " .. ac .. "/" .. cases .. " AC"
    if ac == cases then
        header = header .. " 🎉🎉"
    end
    local contents = { "", header, "" }
    for _, line in ipairs(results) do
        table.insert(contents, line)
    end
    local bufnr = require("ch.helpers").display_right(contents)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
    vim.api.nvim_buf_set_option(bufnr, "filetype", "Results")
    local highlights = {
        ["Status: Accepted"] = "DiffAdd",
        ["Status: Wrong Answer"] = "Error",
        ["Status: Runtime Error"] = "Error",
        ["Case #\\d\\+"] = "DiffChange",
        ["Input:"] = "Underline",
        ["Expected:"] = "Underline",
        ["Output:"] = "Underline",
        ["Error:\n"] = "Underline",
    }
    for match, group in pairs(highlights) do
        vim.fn.matchadd(group, match)
    end

    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>bd<CR>", { noremap = true })
end

local M = {}

function M.process()
    local compile_cmd = "g++ ~/code/" .. vim.fn.expand "%"
    vim.fn.jobstart(compile_cmd, {
        on_exit = function(_, exit_code, _)
            if exit_code == 0 then
                local ac, cases, results = iterate_cases()
                display_results(ac, cases, results)
            end
        end,
        on_stderr = function(_, data, _)
            local err_msg = table.concat(data, "\n")
            vim.api.nvim_err_write(err_msg)
        end,
    })
end

return M
