local _M = {}

_M.__index = _M

function _M.register(bufnr, client_id, cache_id)
    self[bufnr] = {
        client_id = client_id,
        cache_id = cache_id,
    }
end

function _M.get(bufnr)
    return self[bufnr]
end

return setmetatable({}, _M)
