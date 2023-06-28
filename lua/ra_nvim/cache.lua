local _M = {
    valid = false
}

function _M:store(raw_hints, parser)
    self.raw_hints = raw_hints
end

return setmetatable({}, _M)
