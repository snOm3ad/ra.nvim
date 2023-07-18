local record = {}

function record:new(client_id, cache_id)
    return setmetatable({
        client_id = client_id,
        cache_id = cache_id,
        renders = 0,
    }, record)
end

function record:replace(record)
    self = record
end

return record
