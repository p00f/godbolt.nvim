(local fun vim.fn)
(local api vim.api)

(fn get [cmd]
  "Get the response from godbolt.org as a lua table"
  (var output_arr [])
  (local jobid (fun.jobstart cmd
                 {:on_stdout (fn [_ data _]
                               (vim.list_extend output_arr data))}))
  (local t (fun.jobwait [jobid]))
  (local json (fun.join output_arr))
  (fun.json_decode json))

(fn build-cmd [compiler text options]
  "Build curl command from compiler, text and flags"
  (local json
    (fun.json_encode
      {:source text
       :options {:userArguments options}}))
  (string.format
    (.. "curl https://godbolt.org/api/compiler/'%s'/compile"
        " --data-binary '%s'"
        " --header 'Accept: application/json'"
        " --header 'Content-Type: application/json'")
    compiler json))

(var config
  {:cpp {:compiler :g112 :options nil}
   :c {:compiler :cg112 :options nil}
   :rust {:compiler :r1560 :options nil}})

(fn setup [cfg]
  (each [k v (pairs cfg)]
    (tset config k v)))

(fn setup-buf [text]
  (local buf (api.nvim_create_buf false true))
  (api.nvim_buf_set_option buf :filetype :asm)
  (api.nvim_buf_set_lines buf 0 0 false
    (vim.split text "\n" {:trimempty true}))
  buf)

(fn display []
  "Display the assembly in a split"
  (let [lines (match (fun.mode)
               :n (api.nvim_buf_get_lines 0 0 -1 true)
               :v (let [begin (- (fun.getline "'<") 1)
                        end (- (fun.getline ">'") 1)]
                    (api.nvim_buf_get_lines 0 begin end true)))
        text (fun.join lines "\n")
        ft vim.bo.filetype
        response (get (build-cmd
                        (. config ft :compiler) text (. config ft :options)))
        asm (accumulate [str ""
                         k v (pairs (. response :asm))]
              (.. str "\n" (. v :text)))
        source-winid (fun.win_getid)
        source-bufnr (fun.bufnr)
        disp-buf (setup-buf asm)]
    (vim.cmd :vsplit)
    (vim.cmd (string.format "buffer %d" disp-buf))
    (api.nvim_set_current_win source-winid)))



; local function setup_buf(for_buf)
;   if M._entries[for_buf].display_bufnr then
;     return M._entries[for_buf].display_bufnr
;   end
;
;   local buf = api.nvim_create_buf(false, false)
;
;   api.nvim_buf_set_option(buf, "buftype", "nofile")
;   api.nvim_buf_set_option(buf, "swapfile", false)
;   api.nvim_buf_set_option(buf, "buflisted", false)
;   api.nvim_buf_set_option(buf, "filetype", "tsplayground")
;   api.nvim_buf_set_var(buf, query_buf_var_name, for_buf)
;
;   vim.cmd(string.format("augroup TreesitterPlayground_%d", buf))
;   vim.cmd "au!"
;   vim.cmd(
;     string.format(
;       [[autocmd CursorMoved <buffer=%d> lua require'nvim-treesitter-playground.internal'.highlight_node(%d)]],
;       buf,
;       for_buf
;     )
;   )
;   vim.cmd(
;     string.format(
;       [[autocmd BufLeave <buffer=%d> lua require'nvim-treesitter-playground.internal'.clear_highlights(%d)]],
;       buf,
;       for_buf
;     )
;   )
;   vim.cmd(
;     string.format(
;       [[autocmd BufWinEnter <buffer=%d> lua require'nvim-treesitter-playground.internal'.update(%d)]],
;       buf,
;       for_buf
;     )
;   )
;   vim.cmd "augroup END"
;
;   local config = configs.get_module "playground"
;
;   for func, mapping in pairs(config.keybindings) do
;     api.nvim_buf_set_keymap(
;       buf,
;       "n",
;       mapping,
;       string.format(':lua require "nvim-treesitter-playground.internal".%s(%d)<CR>', func, for_buf),
;       { silent = true, noremap = true }
;     )
;   end
;   api.nvim_buf_attach(buf, false, {
;     on_detach = function()
;       clear_entry(for_buf)
;     end,
;   })
;
;   return buf
; end
{: display}
