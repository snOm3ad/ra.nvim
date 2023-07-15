local M = {}

function M.build_req_params(bufnr, encoding)
    local lines = vim.api.nvim_buf_line_count(bufnr)
    local last_line = vim.api.nvim_buf_get_lines(bufnr, lines - 1, lines, true)
    -- columns should be 0-based i.e. something like "}" contains 1 character
    -- therefore (-1) to get rid of it, plus another (-1) to get rid of the EOL char.
    local cols = #(last_line[1]) - 2

    return vim.lsp.util.make_given_range_params({ 1, 0 }, { lines, cols }, bufnr, encoding)
end

function M.is_ra_client(client_id)
    local clients = vim.lsp.get_active_clients({
        id = client_id
    })
    if clients ~= nil then
        if clients[1].name == "rust_analyzer" then
            return true
        end
    end
    return false
end


return M
