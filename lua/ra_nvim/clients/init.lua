local M = {
    active = {},
}

local inner = require("ra_nvim.clients.client")
local utils = require("ra_nvim.utils")

function M.get(client_id)
    return M.active[client_id]
end

function M.add_buf(client_id, bufnr)
    local client = M.get(client_id)
    if client == nil then
        -- trying to add a buffer to non-registered client
        return false
    end
    return client:add_buf(bufnr)
end

function M.remove_buf(client_id, bufnr)
    local client = M.get(client_id)
    if client ~= nil then
        return client:remove_buf(bufnr)
    end
end

function M.setup(bufnr, lsp_client)
    local client = inner:new(lsp_client)
    M.active[client.id] = client
    -- buffer should be loaded, otherwise it's not managed 
    if vim.api.nvim_buf_is_loaded(bufnr) then 
        client.buffers[bufnr] = true
    end
    return client.id
end

function M.has_pending_requests(client_id)
    local client = M.get(client_id)
    if client == nil then
        return false
    end
    return #client.requests > 0
end

function M.get_inlay_hints(client_id, bufnr)
    local client = M.get(client_id)
    if client.buffers[bufnr] == nil then
        client:add_buf(bufnr)
    end
    local params = utils.build_req_params(bufnr, client.offset_encoding)
    local status, req_id = client.get("textDocument/inlayHint", params, client.inlay_hints_handler, bufnr)
    if status then
        table.insert(client.requests, req_id)
    end
end

return M
