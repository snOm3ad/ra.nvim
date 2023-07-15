
local client = {}
local mt_client { __index = client }


function client:new(lsp_client)
    return setmetatable({ 
        id = lsp_client.id, 
        buffers = {},
        encoding = lsp_client.offset_encoding,
        M.get = lsp_client.request,
        requests = {},
        errors = {},
    }, client_mt)
        

function client:add_buff(bufnr)
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
