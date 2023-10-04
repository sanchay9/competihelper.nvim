local function prepare_folders()
    return require("plenary.path").new(vim.loop.os_homedir() .. require("plenary.path").path.sep .. "code")
end

local function prepare_files(problem_dir, tests)
    for i, test in pairs(tests) do
        problem_dir:joinpath("input" .. i):write(test["input"], "w")
        problem_dir:joinpath("output" .. i):write(test["output"], "w")
    end
end

local function process(buffer)
    prepare_files(prepare_folders(), vim.fn.json_decode(buffer).tests)
    print "recieved problem"
end

local M = {}

function M.receive()
    print "Listening on port 27121"
    local buffer = ""
    M.server = vim.loop.new_tcp()
    M.server:bind("127.0.0.1", 27121)
    M.server:listen(128, function(err)
        assert(not err, err)
        local client = vim.loop.new_tcp()
        M.server:accept(client)
        client:read_start(function(error, chunk)
            assert(not error, error)
            if chunk then
                buffer = buffer .. chunk
            else
                client:shutdown()
                client:close()
                local lines = {}
                for line in string.gmatch(buffer, "[^\r\n]+") do
                    table.insert(lines, line)
                end
                buffer = lines[#lines]
                vim.schedule(function()
                    process(buffer)
                end)
                M.server:shutdown()
            end
        end)
    end)
    vim.loop.run()
end

return M
