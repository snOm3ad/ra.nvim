local M = {
    config = nil,
}
local utils = require("ra_nvim.utils")
local session = require("ra_nvim.session")

function M.setup(config)
    M.config = config
    M.gid = vim.api.nvim_create_augroup("RustAnalyzerNvim", {
        clear = true
    })
    vim.api.nvim_create_autocmd("LspAttach", {
        pattern = "*.rs",
        group = M.gid,
        callback = function(args)
            if utils.is_ra_client(args.data.client_id) then
                session.register(args.buf, args.data.client_id)
            end
        end
    })
    session.setup(config)
end

return M
