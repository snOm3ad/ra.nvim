local record = {}

function record:new(client_id, cache_id)
    return setmetatable({
        client_id = client_id,
        cache_id = cache_id,
        renders = 0,
    }, record)
end

function record:replace(record)
    local me = self
    self = record
    self.renders = me.renders
end

return record
