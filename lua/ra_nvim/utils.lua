local M = {}

function M.build_req_params(bufnr, encoding)
    local lines = vim.api.nvim_buf_line_count(bufnr)
    local last_line = vim.api.nvim_buf_get_lines(bufnr, lines - 1, lines, true)
    -- columns should be 0-based i.e. something like "}" contains 1 character
    -- therefore (-1) to get rid of it, plus another (-1) to get rid of the EOL char.
    local cols = #(last_line[1]) - 2

    return vim.lsp.util.make_given_range_params({ 1, 0 }, { lines, cols }, bufnr, encoding)
end

function M.get_ra_clients(buffer)
    local ra_clients = {}
    local clients = vim.lsp.get_active_clients({
        bufnr = buffer
    })
    for _, c in pairs(clients) do
        if c.name == "rust_analyzer" then
            table.insert(ra_clients, c)
        end
    end
    return ra_clients
end


return M
