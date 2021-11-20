;  Copyright (C) 2021 Chinmay Dalal
;
;  This file is part of godbolt.nvim.
;
;  godbolt.nvim is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  godbolt.nvim is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with godbolt.nvim.  If not, see <https://www.gnu.org/licenses/>.

(local fun vim.fn)
(local api vim.api)




; Setup
(var config
  {:cpp {:compiler :g112 :options nil}
   :c {:compiler :cg112 :options nil}
   :rust {:compiler :r1560 :options nil}})

(fn setup [cfg]
  (if vim.g.godbolt_loaded
    nil
    (do (global source-asm-bufs {})
        (global nsid (vim.api.nvim_create_namespace :godbolt))
        (if cfg (each [k v (pairs cfg)]
                  (tset config k v)))
        (set vim.g.godbolt_loaded true))))





; Helper functions
(fn prepare-buf [text]
  "Prepare the assembly buffer: set buffer options and add text"
  (local buf (api.nvim_create_buf false true))
  (api.nvim_buf_set_option buf :filetype :asm)
  (api.nvim_buf_set_lines buf 0 0 false
    (vim.split text "\n" {:trimempty true}))
  buf)

(fn setup-aucmd [source-buf asm-buf]
  "Setup autocommands for updating highlights"
  (vim.cmd "augroup Godbolt")
  (vim.cmd (string.format "autocmd CursorMoved <buffer=%s> lua require('godbolt')['smolck-update'](%s, %s)" source-buf source-buf asm-buf))
  (vim.cmd (string.format "autocmd BufLeave <buffer=%s> lua require('godbolt').clear(%s)" source-buf source-buf))
  (vim.cmd "augroup END"))

(fn build-cmd [compiler text options]
  "Build curl command from compiler, text and flags"
  (local json (fun.json_encode
                {:source text
                 :options {:userArguments options}}))
  (string.format
    (.. "curl https://godbolt.org/api/compiler/'%s'/compile"
        " --data-binary '%s'"
        " --header 'Accept: application/json'"
        " --header 'Content-Type: application/json'")
    compiler json))

(fn get-compiler [compiler options]
  "Get the compiler the user chose or the default one for the language"
  (local ft vim.bo.filetype)
  (if compiler
    (if (= :telescope compiler)
      [((. (require :godbolt.telescope) :compiler-choice) ft) options]
      [compiler options])
    (do
      [(. config ft :compiler) (. config ft :options)])))




; Main
(fn display [response begin]
  (let [asm (accumulate [str ""
                         k v (pairs (. response :asm))]
              (.. str "\n" (. v :text)))
        source-winid (fun.win_getid)
        source-bufnr (fun.bufnr)
        asm-buf (prepare-buf asm)]
      (vim.cmd :vsplit)
      (vim.cmd (string.format "buffer %d" asm-buf))
      (api.nvim_win_set_option 0 :number false)
      (api.nvim_win_set_option 0 :relativenumber false)
      (api.nvim_win_set_option 0 :spell false)
      (api.nvim_win_set_option 0 :cursorline false)
      (api.nvim_set_current_win source-winid)
      (if (not (. source-asm-bufs source-bufnr))
        (tset source-asm-bufs source-bufnr {}))
      (tset source-asm-bufs source-bufnr asm-buf {:asm (. response :asm)
                                                   :offset begin})
      (setup-aucmd source-bufnr asm-buf)))

(fn get-then-display [cmd begin]
  "Get the response from godbolt.org as a lua table"
  (var output_arr [])
  (local jobid (fun.jobstart cmd
                 {:on_stdout (fn [_ data _]
                               (vim.list_extend output_arr data))
                  :on_exit (fn [_ _ _]
                             (local json (fun.join output_arr))
                             (local response (fun.json_decode json))
                             (display response begin))})))

(fn pre-display [begin end compiler options]
  "Prepare text for displaying and call get-then-display"
  (if vim.g.godbolt_loaded
    (let [lines (api.nvim_buf_get_lines 0 (- begin  1) end true)
          text (fun.join lines "\n")
          chosen-compiler (get-compiler compiler options)]
      (get-then-display (build-cmd (. chosen-compiler 1) text (. chosen-compiler 2)) begin))
    (vim.api.nvim_err_writeln "setup function not called")))




; Highlighting
(fn clear [source-buf]
  (each [asm-buf _ (pairs (. source-asm-bufs source-buf))]
    (api.nvim_buf_clear_namespace asm-buf nsid 0 -1)))

(fn smolck-update [source-buf asm-buf]
  (api.nvim_buf_clear_namespace asm-buf nsid 0 -1)
  (local asm-table (. source-asm-bufs source-buf asm-buf :asm))
  (local offset (. source-asm-bufs source-buf asm-buf :offset))
  (local linenum (-> (fun.getcurpos) (. 2) (- offset) (+ 1)))
  (each [k v (pairs asm-table)]
    (if (= (type (. v :source)) :table)
      (if (= linenum (. v :source :line))
        (vim.highlight.range
         asm-buf nsid :Visual
         [(- k 1) 0] [(- k 1) 100]
         :linewise true)))))

{: pre-display : smolck-update : clear : setup}
