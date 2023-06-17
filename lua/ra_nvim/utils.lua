local M = {}

function M.is_server_ready(client)
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
