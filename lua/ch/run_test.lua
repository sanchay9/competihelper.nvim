local h = require "ch.helpers"
local M = {}

function M.run_test(case, cmd)
    local case_no = string.sub(case, 6)
    local timeout = 2000
    local status = 0
    local result = { "Case #" .. case_no }
    local input_arr = vim.fn.readfile(case)
    local exp_out_arr = vim.fn.readfile("output" .. case_no)
    vim.list_extend(result, { "Input:" })
    vim.list_extend(result, input_arr)
    vim.list_extend(result, { "Expected:" })
    vim.list_extend(result, exp_out_arr)
    local output_arr = {}
    local err_arr = {}
    local job_id = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data, _)
            vim.list_extend(output_arr, data)
            output_arr[#output_arr] = nil
        end,
        on_stderr = function(_, data, _)
            vim.list_extend(err_arr, data)
        end,
        on_exit = function(_, exit_code, _)
            if #output_arr ~= 0 then
                vim.list_extend(result, { "Output:" })
                vim.list_extend(result, output_arr)
            end
            if #err_arr ~= 1 then
                vim.list_extend(result, { "Error:" })
                vim.list_extend(result, err_arr)
                vim.list_extend(result, { "Exit code " .. exit_code })
            end
            if exit_code == 0 then
                if h.comparetables(output_arr, exp_out_arr) then
                    vim.list_extend(result, { "Status: Accepted" })
                    status = 1
                else
                    vim.list_extend(result, { "Status: Wrong Answer" })
                end
            else
                vim.list_extend(result, { "Status: Runtime Error" })
                vim.list_extend(result, { "Exit code " .. exit_code })
            end
        end,
    })
    vim.fn.chansend(job_id, vim.list_extend(vim.fn.readfile(case), { "" }))
    local len = vim.fn.jobwait({ job_id }, timeout)
    if len[1] == -1 then
        vim.list_extend(result, { string.format("Status: Timed out after %d ms", timeout) })
        vim.fn.jobstop(job_id)
    end
    return result, status
end
return M
