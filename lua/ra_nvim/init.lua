local M = {
    config = nil,
}

function M.setup(config)
    M.gid = vim.api.nvim_create_augroup("RustAnalyzerNvim", {
        clear = true
    })
    vim.api.nvim_create_autocmd("LspAttach", {
        pattern = "*.rs",
        group = M.gid,
        callback = function(args)
            local utils = require("ra_nvim.utils")
            if utils.is_ra_client(args.data.client_id) then
                local session = require("ra_nvim.session")
                session.register(args.buf, args.data.client_id)
                session.setup(config)
            end
        end
    })
end

return M
