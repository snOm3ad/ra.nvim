local M = {
    buffers = {},
    count = 0
}

local co = coroutine
local clients = require("ra_nvim.clients")
local storage = require("ra_nvim.cache")
local renderer = require("ra_nvim.renderer")
local inner = require("ra_nvim.session.record")

local function create_record(client_id, bufnr)
    if client_id == nil then 
        return 
    end
    -- client may exist for another buffer.
    local client = clients.get(client_id)
    if client == nil then
        local clnts = vim.lsp.get_active_clients({ id = client_id })
        local cid = clients.setup(bufnr, clnts[1])
        return inner:new(cid, nil)
    end
    -- TODO: check for success
    local _ = client:add_buf(bufnr)
    return inner:new(client.id, nil)
end

function M.register(bufnr, client_id)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local record = M.buffers[bufnr]

    if record == nil then
        record = create_record(client_id, bufnr)
        M.buffers[bufnr] = record
    else
        -- NOTE: it's possible a new client was registered for the buffer, i.e.
        -- the buffer has more than one client. But we don't care about this
        -- because we only want to work with one of the clients, so as long as
        -- the client we intially registered keeps itself attached to the buffer
        -- then we do nothing.
        local still_linked = #(vim.lsp.get_active_clients({
            id = record.client_id,
            bufnr = bufnr,
        })) == 1
        if still_linked == false then
            -- remove buffer from old client
            clients.remove_buf(record.client_id, bufnr)
            -- assign new client to this buffer
            local new_record = inner:new(client.id, nil)
            record:replace(new_record)
        end
    end

    local client = clients.get(record.client_id)
    if client.is_ready and #client.requests == 0 then
        vim.api.nvim_exec_autocmds("User", {
            pattern = "FireInlayHintsRequest",
            data = {
                client_id = client.id,
                bufnr = bufnr
            }
        })
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
        pattern = "LspClientReady",
        data = ctx,
    })
    M.register(ctx.bufnr, ctx.client_id)
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


function M.inject_autocmds()
    -- TODO: need to subscribe to `BufModifiedSet`
    vim.api.nvim_create_autocmd("User", {
        group = "RustAnalyzerNvim",
        pattern = "LspClientReady",
        callback = function(md)
            local ctx = md.data
            local client = clients.get(ctx.client_id)
            client.is_ready = true
        end
    })
    vim.api.nvim_create_autocmd("User", {
        group = "RustAnalyzerNvim",
        pattern = "FireInlayHintsRequest",
        callback = function(md)
            local ctx = md.data
            local client = clients.get(ctx.client_id)
            if client.has_og_handler then
                local inner = client.inlay_hints_handler
                client.inlay_hints_handler = function(...)
                    local payload = inner(client, ...)
                    local record = M.buffers[payload.bufnr]
                    record.cache_id = storage.store(payload)
                    co.resume(M.painter)
                end
                client.has_og_handler = false
            end
            clients.get_inlay_hints(client.id, ctx.bufnr)
        end
    })
    vim.api.nvim_create_autocmd("BufModifiedSet", {
        group = "RustAnalyzerNvim",
        pattern = "*.rs",
        callback = function(md)
            M.register(md.buf, nil)
        end
    })
end


M.painter = co.create(function()
    -- At this point the storage is ready, we paint...
    while true do
        local bufnr = vim.api.nvim_get_current_buf()
        local record = M.buffers[bufnr]
        if record and record.cache_id then
            local cache = storage.get(record.cache_id)
            if record.renders == 0 then
                renderer.render(cache.hints, cache.file.bufnr)
                record.renders = 1
            else
                renderer.clear(cache.file.bufnr)
                renderer.render(cache.hints, cache.file.bufnr)
                record.renders = record.renders + 1
            end
        end
        co.yield()
    end

end)

function M.setup(config)
    -- TODO:
    -- after 0.9.1 `LspProgress` should be used, i.e. you no longer append your
    -- own handler, rather you simply attach to the event.
    M.append_progress_handler()
    M.inject_autocmds()
    renderer.setup()
end

return M
