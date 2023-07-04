local _M = {}

_M.__index = _M

function _M:store(payload, parser)
    self.client_id = payload.client_id
    self.file = {
        bufnr = payload.bufnr,
        uri = payload.uri,
    }
    self.hints = payload.hints
    self.valid = true
end

function _M:clone()
    return vim.deepcopy(self)
end

return setmetatable({}, _M)
