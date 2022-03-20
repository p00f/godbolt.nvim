;  Copyright (C) 2021-2022 Chinmay Dalal
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
(local {: api : cmd} vim)
(local fun vim.fn)
(local fmt string.format)
(local term-escapes "[\027\155][][()#;?%d]*[A-PRZcf-ntqry=><~]")
(local wo-set api.nvim_win_set_option)
(local config (. (require :godbolt) :config))
(var map nil)
(var nsid nil)

; Helper functions
(fn prepare-buf [text name reuse? source-buf]
  "Prepare the assembly buffer: set buffer options and add text"
  (local buf (if (and reuse? (-> map
                                 (. source-buf)
                                 (type)
                                 (= :table)))
                 (table.maxn (. map source-buf))
                 (api.nvim_create_buf false true)))
  (api.nvim_buf_set_option buf :filetype :asm)
  (api.nvim_buf_set_lines buf 0 -1 true (vim.split text "\n" {:trimempty true}))
  (api.nvim_buf_set_name buf name)
  buf)

(fn setup-aucmd [source-buf asm-buf]
  "Setup autocommands for updating highlights"
  (cmd "augroup Godbolt")
  (cmd (fmt "autocmd CursorMoved <buffer=%s> lua require('godbolt.assembly')['update-hl'](%s, %s)"
            source-buf source-buf asm-buf))
  (cmd (fmt "autocmd BufLeave <buffer=%s> lua require('godbolt.assembly').clear(%s)"
            source-buf source-buf))
  (cmd "augroup END"))

;; https://stackoverflow.com/a/49209650
(fn make-qflist [err bufnr]
  "Transform compiler output into a form taken by vim's setqflist()"
  (when (next err)
    (icollect [k v (ipairs err)]
      (do
        (local entry {:text (string.gsub v.text term-escapes "") : bufnr})
        (when v.tag
          (tset entry :col v.tag.column)
          (tset entry :lnum v.tag.line))
        entry))))

; Highlighting
(fn clear [source-buf]
  "Clear highlights: used when leaving the source buffer"
  (each [asm-buf _ (pairs (. map source-buf))]
    (api.nvim_buf_clear_namespace asm-buf nsid 0 -1)))

(fn update-hl [source-buf asm-buf]
  "Update highlights: used when the cursor moves in the source buffer"
  (api.nvim_buf_clear_namespace asm-buf nsid 0 -1)
  (let [entry (. map source-buf asm-buf)
        offset entry.offset
        asm-table entry.asm
        linenum (-> (fun.getcurpos)
                    (second)
                    (- offset)
                    (inc))]
    (each [k v (pairs asm-table)]
      (when (= (type v.source) :table)
        (when (= linenum v.source.line)
          (vim.highlight.range asm-buf
                               nsid
                               :Visual
                               ;; [start-row start-col] [end-row end-col]
                               [(dec k) 0] [(dec k) 100]
                               :linewise
                               true))))))

; Main
(fn display [response begin name reuse?]
  "Display the assembly in a split"
  (let [asm (accumulate [str ""
                         k v (pairs response.asm)]
              (if v.text
                  (.. str "\n" v.text)
                  str))
        source-winid (fun.win_getid)
        source-buf (fun.bufnr)
        qflist (make-qflist response.stderr source-buf)
        asm-buf (prepare-buf asm name reuse? source-buf)
        quickfix-cfg config.quickfix]
    ;; Open quickfix
    (var qf-winid nil)
    (when (and qflist quickfix-cfg.enable)
      (fun.setqflist qflist)
      (when quickfix-cfg.auto_open
        (vim.cmd :copen)
        (set qf-winid (fun.win_getid))))
    ;; Open assembly
    (if (= "<Compilation failed>" (. response.asm 1 :text))
        (vim.notify "godbolt.nvim: Compilation failed")
        (do
          (api.nvim_set_current_win source-winid)
          (local asm-winid
                 (if (and reuse? (. map source-buf))
                     (. map source-buf asm-buf :winid)
                     (do
                       (cmd :vsplit)
                       (api.nvim_get_current_win))))
          (api.nvim_set_current_win asm-winid)
          (api.nvim_win_set_buf asm-winid asm-buf)
          (wo-set asm-winid :number false)
          (wo-set asm-winid :relativenumber false)
          (wo-set asm-winid :spell false)
          (wo-set asm-winid :cursorline false)
          (if qf-winid
              (api.nvim_set_current_win qf-winid)
              (api.nvim_set_current_win source-winid))
          (when (not (. map source-buf))
            (tset map source-buf {}))
          (tset map source-buf asm-buf
                {:asm response.asm
                 :offset begin
                 :winid asm-winid})
          (update-hl source-buf asm-buf)
          (setup-aucmd source-buf asm-buf)))))

(fn pre-display [begin end compiler options reuse?]
  "Prepare text for displaying and call display"
  (let [lines (api.nvim_buf_get_lines 0 (dec begin) end true)
        text (fun.join lines "\n")
        curl-cmd (m> :godbolt.init :build-cmd compiler text options :asm)
        time (os.date :*t)
        hour time.hour
        min time.min
        sec time.sec]
    (fun.jobstart curl-cmd
                  {:on_exit (fn [_ _ _]
                              (local file
                                     (io.open :godbolt_response_asm.json :r))
                              (local response (file:read :*all))
                              (file:close)
                              (os.remove :godbolt_request_asm.json)
                              (os.remove :godbolt_response_asm.json)
                              (display (vim.json.decode response) begin
                                       (fmt "%s %02d:%02d:%02d" compiler hour
                                            min sec)
                                       reuse?))})))

(fn init []
  (set map {})
  (set nsid (api.nvim_create_namespace :godbolt)))

{: init : map : nsid : pre-display : update-hl : clear}
