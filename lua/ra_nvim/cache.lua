local M = {
    count = 0
    storage = {}
}


function M.store(payload)
    local id = M.count
    M.storage[id] = {
        file = {
            bufnr = payload.bufnr,
            uri = payload.uri,
        }
        hints = payload.hints
    }
    M.count = M.count + 1
    return id
end

function M.get(cache_id)
    return M.storage[cache_id]
end

return M
