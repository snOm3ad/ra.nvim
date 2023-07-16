local M = {
    buffers = {},
    count = 0
}

local co = coroutine
local clients = require("ra_nvim.clients")
local storage = require("ra_nvim.cache")
local renderer = require("ra_nvim.renderer")

local function add_record(bufnr, client_id, cache_id)
    M.buffers[bufnr] = {
        client_id = client_id,
        cache_id = cache_id,
    }
end

function M.register(bufnr, client_id)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local record = M.buffers[bufnr]
    if record == nil then
        -- client may exist for another buffer.
        local client = clients.get(client_id)
        if client ~= nil then
            -- TODO: check success
            local _ = client:add_buf(bufnr)
            add_record(bufnr, client.id, nil)
            if client.is_ready then
                vim.api.nvim_exec_autocmds("User", {
                    pattern = "FireInlayHintsRequest",
                    data = {
                        client_id = client.id,
                        bufnr = bufnr
                    }
                })
            end
        else
            local clnts = vim.lsp.get_active_clients({
                id = client_id
            })
            local cid = clients.setup(bufnr, clnts[1])
            add_record(bufnr, client_id, nil)
        end
    else
        local alive = vim.lsp.get_active_clients({
            id = record.client_id,
            bufnr = bufnr,
        })
        if #alive == 0 then
            -- remove buffer from old client
            clients.remove_buf(record.client_id, bufnr)
            -- assign new client to this buffer
            record.client_id = client_id
            record.cache_id = nil
            vim.tbl_deep_extend("force", M.buffers[bufnr], record)
        end
        if record.cache_id ~= nil then
            return
        end
        -- NOTE: it's possible a new client was registered for the buffer, i.e.
        -- the buffer has more than one client. But we don't care about this
        -- because we only want to work with one of the clients, so as long as
        -- the client we intially registered keeps itself attached to the buffer
        -- then we do nothing.
        local client = clients.get(record.client_id)
        if client.is_ready and #client.requests == 0 then
            vim.api.nvim_exec_autocmds("User", {
                pattern = "FireInlayHintsRequest",
                data = {
                    client_id = record.client_id,
                    bufnr = bufnr
                }
            })
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
            -- TODO: must ensure we don't override this more than once..
            if client.has_og_handler then
                local inner = client.inlay_hints_handler
                client.inlay_hints_handler = function(...)
                    local payload = inner(client, ...)
                    M.buffers[payload.bufnr].cache_id = storage.store(payload)
                    co.resume(M.painter)
                end
                client.has_og_handler = false
            end
            clients.get_inlay_hints(client.id, ctx.bufnr)
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
            renderer.render(cache.hints, cache.file.bufnr)
        end
        co.yield()
    end

end)

function M.setup(config)
    -- TODO:
    -- after 0.9.1 `LspProgress` should be used, i.e. you no longer append your
    -- own handler, rather you simply attach to the event.
    --
    -- TODO:
    -- currently this does __not__ work when there are multiple buffers open,
    -- it loads the inlay hints for the first buffer but fails to load them for
    -- all subsequent buffers.
    --
    -- Create client module with `is_ready` prop, use that to know when we can
    -- fire requests like a madman with no problems at all. Subsequent requests
    -- should be fired whenever
    M.append_progress_handler()
    M.inject_autocmds()
    renderer.setup()
end

return M
