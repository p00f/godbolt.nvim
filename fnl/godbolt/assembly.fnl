;  Copyright (C) 2021-2023 Chinmay Dalal
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
(var map _G.__godbolt_map)
(var nsid _G.__godbolt_nsid)

; Helper functions
(fn prepare-buf [text name reuse? source-buf]
  "Prepare the assembly buffer: set buffer options and add text"
  (let [buf (if (and reuse? (-> map
                                (. source-buf)
                                (type)
                                (= :table)))
                (table.maxn (. map source-buf))
                (api.nvim_create_buf false true))]
    (api.nvim_buf_set_option buf :filetype :asm)
    (tset (. vim.bo buf) :bufhidden :unload)
    (api.nvim_buf_set_lines buf 0 -1 true
                            (vim.split text "\n" {:trimempty true}))
    (api.nvim_buf_set_name buf name)
    buf))

(fn get-current-line []
  (second (fun.getcurpos)))

(fn find-source [asm-buffer]
  (each [source-buffer asm-buffers (pairs map)]
    (when (->> asm-buffer (. asm-buffers) (not= nil))
      (lua "return source_buffer"))))

(fn get-source-line [source-buffer asm-buffer asm-line]
  (let [source (?. map source-buffer asm-buffer :asm asm-line :source)]
  (if (= (type source) :table)
        source.line
        0)))

(fn cyclic-lookup [array index]
  (. array (+ 1 (% index (length array)))))

(fn highlight-line [buffer line offset source-line cursor-line]
  (let [highlights (. (require :godbolt) :config :highlights)
        offset-line (- source-line (dec offset))
        group (if (= source-line cursor-line)
                "Visual"
                (cyclic-lookup highlights source-line))]
    (api.nvim_buf_add_highlight buffer nsid group (dec line) 0 -1)))

(fn update-hl [source-buffer source-line]
  "Update highlights: used when the cursor moves in the source buffer"
  (api.nvim_buf_clear_namespace source-buffer nsid 0 -1)
  (let [highlighted-source []]
    (each [asm-buffer entry (pairs (. map source-buffer))]
      (api.nvim_buf_clear_namespace asm-buffer nsid 0 -1)
      (each [line v (ipairs entry.asm)]
        (when (and (= (type v.source) :table) (= v.source.file vim.NIL))
          (highlight-line asm-buffer line entry.offset v.source.line source-line)
          (when (not (vim.tbl_contains highlighted-source v.source.line))
            (highlight-line source-buffer v.source.line entry.offset v.source.line source-line)
            (table.insert highlighted-source v.source.line)))))))

(fn update-source [options]
  (update-hl (or (?. options :buf) (fun.bufnr)) (get-current-line)))

(fn remove-asm [source-buffer asm-buffer]
  (api.nvim_buf_clear_namespace asm-buffer nsid 0 -1)
  (tset (. map source-buffer) asm-buffer nil))

(fn remove-source [source-buffer]
  (api.nvim_buf_clear_namespace source-buffer nsid 0 -1)
  (api.nvim_del_augroup_by_name :godbolt)
  (if (->> source-buffer (. map) (not= nil) (and (. (require :godbolt) :config :auto_cleanup)))
        (each [asm-buffer _ (pairs (. map source-buffer))]
          (api.nvim_buf_delete asm-buffer {})))
        (tset map source-buffer nil))

(fn clear-source [options]
  (remove-source (or (?. options :buf) (fun.bufnr))))

(fn update-asm [options]
  (let [asm-buffer (or (?. options :buf) (fun.bufnr))
        source-buffer (find-source asm-buffer)
        asm-line (get-current-line)
        source-line (get-source-line source-buffer asm-buffer asm-line)]
    (update-hl source-buffer source-line)))

(fn clear-asm [options]
  (let [asm-buffer (or (?. options :buf) (fun.bufnr))
        source-buffer (find-source asm-buffer)]
    (remove-asm source-buffer asm-buffer)
    (when (->> source-buffer (. map) (vim.tbl_count) (= 0) (and (. (require :godbolt) :config :auto_cleanup)))
      (remove-source source-buffer))))

(fn setup-aucmd [source-buf asm-buf]
  "Setup autocommands for updating highlights"
  (let [group (api.nvim_create_augroup :godbolt { :clear false })]
    (api.nvim_create_autocmd [ :CursorMoved :BufEnter ] { :callback update-source :buffer source-buf :group group })
    (api.nvim_create_autocmd [ :CursorMoved :BufEnter ] { :callback update-asm :buffer asm-buf :group group })
    (api.nvim_create_autocmd :BufUnload { :callback clear-source :buffer source-buf :group group })
    (api.nvim_create_autocmd :BufUnload { :callback clear-asm :buffer asm-buf :group group }))
  nil)

;; https://stackoverflow.com/a/49209650
(fn make-qflist [err bufnr]
  "Transform compiler output into a form taken by vim's setqflist()"
  (when (next err)
    (icollect [_ v (ipairs err)]
      (let [entry {:text (string.gsub v.text term-escapes "") : bufnr}]
        (when v.tag
          (tset entry :col v.tag.column)
          (tset entry :lnum v.tag.line))
        entry))))

; Highlighting
(fn clear [source-buf]
  "Clear highlights: used when leaving the source buffer"
  (api.nvim_buf_clear_namespace source-buf nsid 0 -1)
  (api.nvim_del_augroup_by_name "Godbolt")
  (each [asm-buf _ (pairs (. map source-buf))]
    (api.nvim_buf_clear_namespace asm-buf nsid 0 -1))
  (tset map source-buf nil))

; Main
(fn display [response begin name reuse?]
  "Display the assembly in a split"
  (let [asm (if (vim.tbl_isempty response.asm)
                (fmt "No assembly to display (~%d lines filtered)"
                     response.filteredCount)
                (accumulate [str "" _ v (pairs response.asm)]
                  (if v.text
                      (.. str "\n" v.text)
                      str)))
        config (. (require :godbolt) :config)
        source-winid (fun.win_getid)
        source-buf (fun.bufnr)
        qflist (make-qflist response.stderr source-buf)
        asm-buf (prepare-buf asm name reuse? source-buf)]
    ;; Open quickfix
    (var qf-winid nil)
    (when (and qflist config.quickfix.enable)
      (fun.setqflist qflist)
      (when config.quickfix.auto_open
        (vim.cmd.copen)
        (set qf-winid (fun.win_getid))))
    ;; Open assembly
    (if (and (not (vim.tbl_isempty response.asm))
             (= "<Compilation failed>" (. response.asm 1 :text)))
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
                {:asm response.asm :offset begin :winid asm-winid})
          (when (not (vim.tbl_isempty response.asm))
            (update-hl source-buf)
            (setup-aucmd source-buf asm-buf))))))

(fn pre-display [begin end compiler options reuse?]
  "Prepare text for displaying and call display"
  (let [lines (api.nvim_buf_get_lines 0 (dec begin) end true)
        text (fun.join lines "\n")
        curl-cmd (m> :godbolt.cmd :build-cmd compiler text options :asm)
        time (os.date :*t)
        hour time.hour
        min time.min
        sec time.sec]
    (fun.jobstart curl-cmd
                  {:on_exit (fn [_ _ _]
                              (let [file (io.open :godbolt_response_asm.json :r)
                                    response (file:read :*all)]
                                (file:close)
                                (os.remove :godbolt_request_asm.json)
                                (os.remove :godbolt_response_asm.json)
                                (display (vim.json.decode response) begin
                                         (fmt "%s %02d:%02d:%02d" compiler hour
                                              min sec)
                                         reuse?)))})))

{: map : nsid : pre-display : update-hl : clear}
