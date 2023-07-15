local M = {
    buffers = {}
}

local co = coroutine
local clients = require("ra_nvim.client")
local storage = require("ra_nvim.cache")

function M.register(bufnr, client_id)
   local record = M.buffers[bufnr]

   if record == nil then
       -- client may exist for another buffer.
       local client = clients.get(client_id)
       if client ~= nil then
           -- TODO: check success
           local _ = client:add_buf(client.id, bufnr)
       else
           client = vim.lsp.get_active_clients({
               id = client_id
           })
           local cid = clients.setup(bufnr, client)
           M.buffers[bufnr] = {
               client_id = cid,
               cache_id = nil,
           }
       end
   else
       local alive = vim.lsp.get_active_clients({
           id = record.client_id,
           bufnr = bufnr,
       })
       -- client no longer manages this buffer
       if alive == nil then
           record.client_id = client_id
           record.cache_id = nil
           vim.tbl_deep_extend("force", M.buffers[bufnr], record)
           clients.remove_buf(client_id, bufnr)
       end
       -- NOTE: it's possible a new client was registered for the buffer, i.e.
       -- the buffer has more than one client. But we don't care about this
       -- because we only want to work with one of the clients, so as long as
       -- the client we intially registered keeps itself attached to the buffer
       -- then we do nothing.
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
        pattern = "LspClientReady"
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

function M.inject_autocmd(_config)
    vim.api.nvim_create_autocmd("User", {
        group = "RustAnalyzerNvim",
        pattern = "LspClientReady",
        callback = function(md)
            local ctx = md.data
            -- TODO: figure this API
            local inner = clients.request_handler
            clients.request_handler = function(...)
                local payload = inner(...)
                storage
            end
        end
    })
    vim.api.nvim_create_autocmd("User", {
        group = "RustAnalyzerNvim",
        pattern = "InlayHintsReady",
        callback = function(md)
            local ctx = md.data
            
        end
    })
end

M.worker = co.create(function(_config)
    M.append_progress_handler()
    M.inject_autocmds()

end)

function M.setup(config)
    co.resume(M.worker, config)
end

return M
