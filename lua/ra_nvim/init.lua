local M = {
    config = nil,
    ready = false,
}

local function parse()
-- vim.api.nvim_echo({ { vim.inspect(c), nil } }, false, {})
end

function M.request_handler(err, result)
    if err then
        vim.api.nvim_echo({ { vim.inspect(err), nil } }, false, {})
        return
    end
    vim.api.nvim_echo({{ vim.inspect(result), nil }}, false, {})
end

local function build_inlay_hints_params(bufnr, encoding)
    local lines = vim.api.nvim_buf_line_count(bufnr)
    local last_line = vim.api.nvim_buf_get_lines(bufnr, lines - 1, lines, true)
    -- columns should be 0-based i.e. something like "}" contains 1 character
    -- therefore (-1) to get rid of it, plus another (-1) to get rid of the EOL char.
    local cols = #(last_line[1]) - 2

    return vim.lsp.util.make_given_range_params({ 1, 0 }, { lines, cols }, bufnr, encoding)
end

function M.get_inlay_hints(client)
    local params = build_inlay_hints_params(M.bufnr, client.offset_encoding)
    client.request("textDocument/inlayHint", params, M.request_handler, M.bufnr)
end

function M.register_client()
    M.bufnr = vim.api.nvim_get_current_buf()
    local utils = require("ra_nvim.utils")

    if vim.api.nvim_buf_is_loaded(M.bufnr) then
        local clients = utils.get_ra_clients(M.bufnr)
        if #clients > 0 then
            M.client_id = clients[1].id
        end
    end
end

function M.progress_handler(err, response, ctx)
    if err then
        return
    end
    vim.api.nvim_echo({{ vim.inspect(ctx), nil }}, false, {})
    if M.client_id ~= nil then
        if ctx.client_id ~= M.client_id then
            return
        end
    end
    local token = response.token
    local kind = response.value.kind
    if token ~= "rustAnalyzer/Roots Scanned" then
        return
    end
    if kind ~= "end" then
        return
    end
    print("Done...")
    M.ready = true
end

function M.override_handler()
    local old_handler = vim.lsp.handlers["$/progress"]
    if old_handler then
        vim.lsp.handlers["$/progress"] = function(...)
            old_handler(...)
            M.progress_handler(...)
        end
    else
        vim.lsp.handlers["$/progress"] = M.progress_handler
    end
end

function M.setup()
    --M.override_handler()
    M.inject_autocmds()
    -- at this point the client is registered.
    if M.ready == true then
        local client = vim.lsp.get_client_by_id(M.client_id)
        M.get_inlay_hints(client)
    end
end

function M.inject_autocmds()
    M.gid = vim.api.nvim_create_augroup("RustAnalyzerNvim", {
        clear = true,
    })
    vim.api.nvim_create_autocmd("LspAttach", {
        pattern = "*.rs",
        group = M.gid,
        callback = function()
            M.register_client()
            vim.api.nvim_create_autocmd("User LspProgressUpdate", {
                group = M.gid,
                callback = M.progress_handler
            })
        end
    })
end

return M
