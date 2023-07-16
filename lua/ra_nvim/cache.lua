local M = {
    storage = {}
}


function M.store(payload)
    local bufnr = payload.bufnr
    M.storage[bufnr] = {
        file = {
            bufnr = bufnr,
            uri = payload.uri,
        },
        hints = payload.hints
    }
    return bufnr
end

function M.get(cache_id)
    return M.storage[cache_id]
end

return M
