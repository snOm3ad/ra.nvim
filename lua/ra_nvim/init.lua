local M = {
    config = nil,
    errors = {},
    requests = {}
}
local cache = require("ra_nvim.cache")
local utils = require("ra_nvim.utils")
local renderer = require("ra_nvim.renderer")

function M.request_handler(err, result, ctx)
    table.remove(M.requests, 1)
    if err then
        table.insert(M.errors, {
            err = "Request 'textDocument/InlayHint' failed.",
            inner = err
        })
        return
    end
    local payload = { 
        hints = result, 
        client_id = ctx.client_id, 
        bufnr = ctx.bufnr, 
        uri = ctx.params.textDocument.uri 
    }
    -- prepare cache
    cache:store(payload)
    coroutine.resume(M.worker, M.config)
end


function M.get_inlay_hints(client)
    local params = utils.build_req_params(M.bufnr, client.offset_encoding)
    local status, req_id = client.request("textDocument/inlayHint", params, M.request_handler, M.bufnr)
    if status then
        table.insert(M.requests, req_id)
    end
end

function M.register_client()
    M.bufnr = vim.api.nvim_get_current_buf()

    if vim.api.nvim_buf_is_loaded(M.bufnr) then
        local clients = utils.get_ra_clients(M.bufnr)
        if #clients > 0 then
            local client = clients[1]
            M.client_id = client.id
        end
    end
end

function M.progress_handler(err, response, ctx)
    if err then
        return
    end
    local token = response.token
    local kind = response.value.kind
    if token ~= "rustAnalyzer/Roots Scanned" and kind ~= "end" then
        return
    end
    vim.api.nvim_exec_autocmds("User", {
        pattern = "LspReady",
        data = ctx
    })
end

function M.append_progress_handler()
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

M.worker = coroutine.create(function(_config)
    -- TODO:
    -- after 0.9.1 `LspProgress` should be used, i.e. you no longer append your
    -- own handler, rather you simply attach to the event.
    M.append_progress_handler()
    M.inject_autocmds()

    coroutine.yield()

    renderer.setup()
    renderer.render(cache.hints, cache.file.bufnr)
end)

function M.setup(config)
    M.config = config
    coroutine.resume(M.worker, M.config)
end

function M.inject_autocmds()
    M.gid = vim.api.nvim_create_augroup("RustAnalyzerNvim", {
        clear = true,
    })
    vim.api.nvim_create_autocmd("User", {
        group = M.gid,
        pattern = "LspReady",
        callback = function(metadata)
            local ctx = metadata.data
            if ctx.client_id == M.client_id and metadata.buf == M.bufnr 
                and next(M.requests) == nil and not cache.valid then
                -- send request 
                local client = vim.lsp.get_client_by_id(M.client_id)
                M.get_inlay_hints(client)
            end
        end
    })
    vim.api.nvim_create_autocmd("LspAttach", {
        pattern = "*.rs",
        group = M.gid,
        callback = M.register_client
    })
end

return M
