local M = {
    config = nil,
}
local utils = require("ra_nvim.utils")
local session = require("ra_nvim.session")
local renderer = require("ra_nvim.renderer")
local co = coroutine


M.worker = co.create(function(_config)
    -- TODO:
    -- after 0.9.1 `LspProgress` should be used, i.e. you no longer append your
    -- own handler, rather you simply attach to the event.
    --
    -- TODO:
    -- currently this does __not__ work when there are multiple buffers open,
    -- it loads the inlay hints for the first buffer but fails to load them for
    -- all subsequent buffers.
    --
    -- Create client module with `is_ready` prop, use that to know when we can
    -- fire requests like a madman with no problems at all. Subsequent requests
    -- should be fired whenever
    M.append_progress_handler()
    M.inject_autocmds()

    co.yield()

    renderer.setup()
    while true do
        renderer.render(cache.hints, cache.file.bufnr)
        co.yield()
    end

end)

function M.setup(config)
    M.config = config
    session.setup()
    vim.api.nvim_create_autocmd("LspAttach", {
        pattern = "*.rs",
        group = M.gid,
        callback = function(args)
            if utils.is_ra_client(args.data.client_id) then
                session.register(args.buf, args.data.client_id)
            end
        end
    })
end

function M.inject_autocmds()
    M.gid = vim.api.nvim_create_augroup("RustAnalyzerNvim", {
        clear = true,
    })
    -- mistake is here... this only gets fired once.
    -- need to make sure to 
    vim.api.nvim_create_autocmd("User", {
        group = M.gid,
        pattern = "RaServerReady",
        callback = function(metadata)
            local ctx = metadata.data
            if ctx.client_id == client.client_id and metadata.buf == M.bufnr 
                and next(client.requests) == nil and not cache.valid then
                -- send request 
                session.get_inlay_hints(ctx)
                co.resume(M.worker, M.config)
            end
        end
    })
end

return M
