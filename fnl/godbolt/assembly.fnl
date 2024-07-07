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

(import-macros {: m> : dec : second : inc : first} :godbolt.macros)
(local {: api : cmd} vim)
(local fun vim.fn)
(local fmt string.format)
(local term-escapes "[\027\155][][()#;?%d]*[A-PRZcf-ntqry=><~]")
(local wo-set api.nvim_win_set_option)
(var map {})
(local nsid-static (vim.api.nvim_create_namespace :godbolt_highlight))
(local nsid (vim.api.nvim_create_namespace :godbolt_cursor))

(fn get-highlight-groups [highlights]
  "Get highlight groups from the configuration"
  (icollect [i hl (ipairs highlights)]
    (when (= (type hl) :string)
      (let [group-name (.. :Godbolt i)]
        (if (= (string.sub hl 1 1) "#")
            ;; if it's a hex value, set the highlight group
            (api.nvim_set_hl 0 group-name {:bg hl})
            (not (vim.tbl_isempty (api.nvim_get_hl 0 {:name group-name})))
            ;; if it's an existing highlight group, link it
            (api.nvim_set_hl 0 group-name {:link hl}))
        group-name))))

; Helper functions
(fn prepare-buf [text name reuse? source-buf]
  "Prepare the assembly buffer: set buffer options and add text"
  (let [buf (if (and reuse? (= :table (type (. map source-buf))))
                (table.maxn (. map source-buf))
                (api.nvim_create_buf false true))]
    (tset vim.bo buf :modifiable true)
    (api.nvim_buf_set_lines buf 0 -1 true
                            (vim.split text "\n" {:trimempty true}))
    (api.nvim_buf_set_name buf name)
    (doto (. vim.bo buf)
      (tset :filetype :asm)
      (tset :bufhidden :unload)
      (tset :modifiable false))
    buf))

(fn get-current-line []
  (first (api.nvim_win_get_cursor 0)))

(fn get-entry-source-line [entry asm-line]
  "Get the source line from an entry"
  (let [source (?. entry :asm asm-line :source)]
    (when (and source (= (type source) :table) (= source.file vim.NIL))
      (+ source.line (dec entry.offset)))))

(fn get-source-line [source-buffer asm-buffer asm-line]
  "Get the source line from a source-asm buffer pair"
  (get-entry-source-line (?. map source-buffer asm-buffer) asm-line))

(fn cyclic-lookup [array index]
  (. array (->> array (length) (% index) (+ 1))))

(fn get-source-highlights [source-buffer namespace-id]
  (let [extmarks (api.nvim_buf_get_extmarks source-buffer namespace-id 0 -1
                                            {:details false
                                             :hl_name false
                                             :overlap false
                                             :type :highlight})]
    (icollect [_ [_ line _] (ipairs extmarks)]
      line)))

(fn update-cursor [source-buffer cursor-line]
  "Update cursor highlights: used when the cursor moves in the source buffer"
  (api.nvim_buf_clear_namespace source-buffer nsid 0 -1)
  (let [source-highlights (get-source-highlights source-buffer nsid)]
    (each [asm-buffer entry (pairs (. map source-buffer))]
      (api.nvim_buf_clear_namespace asm-buffer nsid 0 -1)
      (each [asm-line _ (ipairs entry.asm)]
        (let [source-line (get-entry-source-line entry asm-line)]
          (when (and source-line (= cursor-line source-line))
            (api.nvim_buf_add_highlight asm-buffer nsid :Visual (dec asm-line)
                                        0 -1)
            (when (not (vim.tbl_contains source-highlights (dec source-line)))
              (api.nvim_buf_add_highlight source-buffer nsid :Visual
                                          (dec source-line) 0 -1)
              (table.insert source-highlights (dec source-line)))))))))

(fn update-source [source-buf]
  (update-cursor source-buf (get-current-line)))

(fn init-highlight [source-buffer asm-buffer]
  "Initial multi-coloured highlighting"
  (api.nvim_buf_clear_namespace asm-buffer nsid-static 0 -1)
  (let [source-highlights (get-source-highlights source-buffer nsid-static)
        highlights (get-highlight-groups (. (require :godbolt) :config
                                            :highlights))
        entry (. map source-buffer asm-buffer)]
    (each [asm-line _ (ipairs entry.asm)]
      (let [source-line (get-entry-source-line entry asm-line)]
        (when source-line
          (let [group (cyclic-lookup highlights source-line)]
            (api.nvim_buf_add_highlight asm-buffer nsid-static group
                                        (dec asm-line) 0 -1)
            (when (not (vim.tbl_contains source-highlights (dec source-line)))
              (api.nvim_buf_add_highlight source-buffer nsid-static group
                                          (dec source-line) 0 -1)
              (table.insert source-highlights (dec source-line)))))))))

(fn remove-source [source-buffer]
  (api.nvim_buf_clear_namespace source-buffer nsid-static 0 -1)
  (api.nvim_buf_clear_namespace source-buffer nsid 0 -1)
  (api.nvim_clear_autocmds {:group :Godbolt :buffer source-buffer})
  (when (and (. (require :godbolt) :config :auto_cleanup) (. map source-buffer))
    (each [asm-buffer _ (pairs (. map source-buffer))]
      (api.nvim_buf_delete asm-buffer {})))
  (tset map source-buffer nil))

(fn remove-asm [source-buffer asm-buffer]
  (api.nvim_buf_clear_namespace asm-buffer nsid-static 0 -1)
  (api.nvim_buf_clear_namespace asm-buffer nsid 0 -1)
  (tset (. map source-buffer) asm-buffer nil))

(fn update-asm [source-buffer asm-buffer]
  (let [asm-line (get-current-line)
        source-line (get-source-line source-buffer asm-buffer asm-line)]
    (update-cursor source-buffer source-line)))

(fn clear-asm [source-buffer asm-buffer]
  (remove-asm source-buffer asm-buffer)
  (when (and (. (require :godbolt) :config :auto_cleanup)
             (= 0 (vim.tbl_count (. map source-buffer))))
    (remove-source source-buffer)))

(fn setup-aucmd [source-buf asm-buf]
  "Setup autocommands for updating highlights"
  (let [group (api.nvim_create_augroup :Godbolt {:clear false})]
    (when (= 0 (length (api.nvim_get_autocmds {: group :buffer source-buf})))
      (api.nvim_create_autocmd [:CursorMoved :BufEnter]
                               {: group
                                :callback #(update-source source-buf)
                                :buffer source-buf})
      (api.nvim_create_autocmd [:BufUnload]
                               {: group
                                :callback #(remove-source source-buf)
                                :buffer source-buf}))
    (api.nvim_create_autocmd [:CursorMoved :BufEnter]
                             {: group
                              :callback #(update-asm source-buf asm-buf)
                              :buffer asm-buf})
    (api.nvim_create_autocmd [:BufUnload]
                             {: group
                              :callback #(clear-asm source-buf asm-buf)
                              :buffer asm-buf})))

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
            (init-highlight source-buf asm-buf)
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

{: pre-display}
