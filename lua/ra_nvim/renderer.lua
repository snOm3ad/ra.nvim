local M = {}

function M.setup(cache)
    M.ns = vim.api.nvim_create_namespace("RaNvim")
    --TODO: example
    vim.api.nvim_set_hl(M.ns, "RaNvimInlayHints", {
        fg = "#d3d3d3",
        bg = "#36383c",
    })
    vim.api.nvim_set_hl_ns(M.ns)

    --vim.api.nvim_echo({{ vim.inspect(cache.hints), nil }}, false, {})
    for _, v in pairs(cache.hints) do
        local label = v.label
        local text = ""
        if type(label) == "string" then
            text = label
        elseif type(label) == "table" then
            -- ignore location for now..
            for _, v in pairs(label) do
                text = text .. v.value
            end
        else
            print("wtf")
        end

        local line = v.position.line
        local column = v.position.character - 1

        vim.api.nvim_buf_set_extmark(cache.file.bufnr, M.ns, line, column, {
           virt_text = {{ text, "RaNvimInlayHints" }},
           virt_text_pos = "eol",
        })
    end

end

return M
