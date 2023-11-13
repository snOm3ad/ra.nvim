local client = {}
client.__index = client


function client:new(lsp_client)
    return setmetatable({ 
        id = lsp_client.id, 
        buffers = {},
        encoding = lsp_client.offset_encoding,
        is_ready = false,
        has_og_handler = true,
        get = lsp_client.request,
        requests = {},
        errors = {},
    }, client)
end

-- TODO: these functions are not carried over to the `client` objects

function client:inlay_hints_handler(err, result, ctx)
    table.remove(self.requests, 1)
    if err then
        table.insert(self.errors, {
            err = "Request 'textDocument/InlayHint' failed.",
            inner = err,
        })
        return
    end
    local payload = {
        hints = result,
        client_id = self.id,
        bufnr = ctx.bufnr,
        uri = ctx.params.textDocument.uri,
    }
    return payload
end

function client:add_buf(bufnr)
    if self.buffers[bufnr] ~= nil then
        return true
    end
    self.buffers[bufnr] = true
    return true
end

function client:remove_buf(bufnr)
    self.buffers[bufnr] = nil
    return true
end

return client
