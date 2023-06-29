local M = {}

function M.parse(hints)
    -- format: 
    -- {
        -- kind: (optional) tells you whether it's a parameter name or a type.
        -- label: the thing to display, will either be a string or table.
        -- paddingLeft: boolean
        -- paddingRight: boolean
        -- position: table {
            -- character: the column position
            -- line: the line position
        -- }
    -- }

    if type(hints) ~= "table" then
        return
    end

    return hints
end

return M
