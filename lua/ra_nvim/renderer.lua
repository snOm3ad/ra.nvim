local M = {}

-- we'll need the buffer number

function M.setup(cache)
    M.ns = vim.api.nvim_create_namespace("RaNvim/InlayHints")
end

return M
