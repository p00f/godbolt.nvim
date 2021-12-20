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

(import-macros {: m> : dec : second : inc} :godbolt.macros)
(local fun vim.fn)
(local api vim.api)
(local cmd vim.cmd)
(local wo-set api.nvim_win_set_option)
(var source-asm-bufs (. _G._private-gb-exports :bufmap))

; Helper functions
(fn prepare-buf [text name]
  "Prepare the assembly buffer: set buffer options and add text"
  (local buf (api.nvim_create_buf false true))
  (api.nvim_buf_set_option buf :filetype :asm)
  (api.nvim_buf_set_lines buf 0 0 false (vim.split text "\n" {:trimempty true}))
  (api.nvim_buf_set_name buf name)
  buf)

(fn setup-aucmd [source-buf asm-buf]
  "Setup autocommands for updating highlights"
  (cmd "augroup Godbolt")
  (cmd (string.format "autocmd CursorMoved <buffer=%s> lua require('godbolt.assembly')['smolck-update'](%s, %s)"
                      source-buf source-buf asm-buf))
  (cmd (string.format "autocmd BufLeave <buffer=%s> lua require('godbolt.assembly').clear(%s)"
                      source-buf source-buf))
  (cmd "augroup END"))

;; https://stackoverflow.com/a/49209650
(fn make-qflist [err bufnr]
  (when (next err)
    (icollect [k v (ipairs err)]
      (do
        (local entry {:text
                      (-> v
                          (. :text)
                          (string.gsub "[\027\155][][()#;?%d]*[A-PRZcf-ntqry=><~]" ""))
                      : bufnr})
        (when (. v :tag)
          (tset entry :col (. v :tag :column))
          (tset entry :lnum (. v :tag :line)))
        entry))))

; Highlighting
(fn clear [source-buf]
  (each [asm-buf _ (pairs (. source-asm-bufs source-buf))]
    (api.nvim_buf_clear_namespace asm-buf (. _G._private-gb-exports :nsid) 0 -1)))

(fn smolck-update [source-buf asm-buf]
  (api.nvim_buf_clear_namespace asm-buf (. _G._private-gb-exports :nsid) 0 -1)
  (let [entry (. source-asm-bufs source-buf asm-buf)
        offset (. entry :offset)
        asm-table (. entry :asm)
        linenum (-> (fun.getcurpos)
                    (second)
                    (- offset)
                    (inc))]
    (each [k v (pairs asm-table)]
      (if (= (type (. v :source)) :table)
          (if (= linenum (. v :source :line))
              (vim.highlight.range asm-buf
                                   (. _G._private-gb-exports :nsid)
                                   :Visual
                                   ;; [start-row start-col] [end-row end-col]
                                   [(dec k) 0] [(dec k) 100]
                                   :linewise true))))))

; Main
(fn display [response begin name]
  (let [asm (accumulate [str "" k v (pairs (. response :asm))]
              (if (. v :text)
                  (.. str "\n" (. v :text))
                  str))
        source-winid (fun.win_getid)
        source-bufnr (fun.bufnr)
        qflist (make-qflist (. response :stderr) source-bufnr)
        asm-buf (prepare-buf asm name)]
    ;; Open quickfix
    (var qf-winid nil)
    (when (and qflist _G.godbolt_config.quickfix.enable)
      (fun.setqflist qflist)
      (when _G.godbolt_config.quickfix.auto_open
        (vim.cmd :copen)
        (set qf-winid (fun.win_getid))))
    ;; Open assembly
    (if (= "<Compilation failed>" (. response :asm 1 :text))
        (vim.notify "godbolt.nvim: Compilation failed")
        (do
          (api.nvim_set_current_win source-winid)
          (cmd :vsplit)
          (cmd (string.format "buffer %d" asm-buf))
          (wo-set 0 :number false)
          (wo-set 0 :relativenumber false)
          (wo-set 0 :spell false)
          (wo-set 0 :cursorline false)
          (if qf-winid
              (api.nvim_set_current_win qf-winid)
              (api.nvim_set_current_win source-winid))
          (when (not (. source-asm-bufs source-bufnr))
            (tset source-asm-bufs source-bufnr {}))
          (tset source-asm-bufs source-bufnr asm-buf
                {:asm (. response :asm) :offset begin})
          (setup-aucmd source-bufnr asm-buf)))))

(fn pre-display [begin end compiler options name]
  "Prepare text for displaying and call display"
  (let [lines (api.nvim_buf_get_lines 0 (dec begin) end true)
        text (fun.join lines "\n")
        curl-cmd (m> :godbolt.init :build-cmd compiler text options :asm)
        time (os.date :*t)
        hour (. time :hour)
        min (. time :min)
        sec (. time :sec)]
    (local _jobid
      (fun.jobstart curl-cmd
        {:on_exit (fn [_ _ _]
                    (local file (io.open :godbolt_response_asm.json :r))
                    (local response (file:read "*all"))
                    (file:close)
                    (os.remove :godbolt_request_asm.json)
                    (os.remove :godbolt_response_asm.json)
                    (display (vim.json.decode response)
                             begin
                             (string.format "%s %02d:%02d:%02d"
                                            (or name compiler)
                                            hour min sec)))}))))


{: pre-display : clear : smolck-update}
