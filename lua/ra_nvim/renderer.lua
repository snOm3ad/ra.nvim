local M = {}

function M.render(hints, bufnr)
    for _, v in pairs(hints) do
        local label = v.label
        local text = ""
        if type(label) == "string" then
            text = label
        elseif type(label) == "table" then
            -- ignore location for now..
            for _, v in pairs(label) do
                text = text .. v.value
            end
        end

        local line = v.position.line
        local column = v.position.character - 1

        vim.api.nvim_buf_set_extmark(bufnr, M.ns, line, column, {
           virt_text = {{ text, M.hl_group }},
           virt_text_pos = "eol",
        })
    end
end

function M.setup()
    M.ns = vim.api.nvim_create_namespace("RaNvim")
    M.hl_group = "RaNvimInlayHints"
    vim.api.nvim_set_hl(M.ns, M.hl_group, {
        fg = "#d3d3d3",
        bg = "#36383c",
    })
    vim.api.nvim_set_hl_ns(M.ns)
end

function M.clear(bufnr)
    if vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
    end
end

return M
