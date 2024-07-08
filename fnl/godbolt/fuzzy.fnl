;  Copyright (C) 2021-2024 Chinmay Dalal
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

(import-macros {: m> : first} :godbolt.macros)

(local fun vim.fn)
(local pre-display (. (require :godbolt.assembly) :pre-display))
(local execute (. (require :godbolt.execute) :execute))

;; fnlfmt: skip
(fn transform [entry]
  "Get the compiler id from the selected entry for telescope"
  {:value (-> entry (vim.split " ") (first))
   :display entry
   :ordinal entry})

(fn fzf [entries begin end options exec reuse?]
  (let [maxlen (accumulate [current-maxlen -1 _ v (pairs entries)]
                 (let [len (fun.len v)]
                   (if (> len current-maxlen) len current-maxlen)))
        width (-> maxlen (/ vim.o.columns) (+ 0.05))]
    (fun.fzf#run {:source entries
                  :window {: width :height 0.6}
                  :sink (fn [choice]
                          (let [compiler (-> choice (vim.split " ") (first))]
                            (pre-display begin end compiler options reuse?)
                            (when exec
                              (execute begin end compiler options))))})))

; Same as fzf, just s/fzf/skim/g
(fn skim [entries begin end options exec reuse?]
  (let [maxlen (accumulate [current-maxlen -1 _ v (pairs entries)]
                 (let [len (fun.len v)]
                   (if (> len current-maxlen) len current-maxlen)))
        width (-> maxlen (/ vim.o.columns) (+ 0.05))]
    (fun.skim#run {:source entries
                   :window {: width :height 0.6}
                   :sink (fn [choice]
                           (let [compiler (first (vim.split choice " "))]
                             (pre-display begin end compiler options reuse?)
                             (when exec
                               (execute begin end compiler options))))})))

;; fnlfmt: skip
(fn telescope [entries begin end options exec reuse?]
  (let [pickers (require :telescope.pickers)
        finders (require :telescope.finders)
        conf (. (require :telescope.config) :values)
        actions (require :telescope.actions)
        actions-state (require :telescope.actions.state)]
    (: (pickers.new {}
         {:prompt_title "Choose compiler"
          :finder (finders.new_table {:results entries
                                      :entry_maker transform})
          :sorter (conf.generic_sorter nil)
          :attach_mappings (fn [prompt-bufnr _map]
                             (actions.select_default:replace
                               (fn []
                                 (actions.close prompt-bufnr)
                                 (let [compiler (. (actions-state.get_selected_entry) :value)]
                                   (pre-display begin end compiler options reuse?)
                                   (when exec
                                     (execute begin end compiler options))))))})
       :find)))

(fn fzy [entries begin end options exec reuse?]
  (m> :fzy :pick_one entries "Choose compiler: " (fn [text] text)
      (fn [choice]
        (let [compiler (first (vim.split choice " "))]
          (pre-display begin end compiler options reuse?)
          (when exec
            (execute begin end compiler options))))))

;; fnlfmt: skip
(fn fuzzy [picker ft begin end options exec reuse?]
  (let [ft (match ft
             :cpp :c++
             x x)
        url (. (require :godbolt) :config :url)
        cmd (string.format "curl %s/api/compilers/%s" url ft)]
    (var output [])
    (fun.jobstart cmd
      {:on_stdout (fn [_ data _]
                    (vim.list_extend output data))
       :on_exit (fn [_ _ _]
                  (let [entries (icollect [k v (ipairs output)]
                                  (when (not= k 1) v))]
                    ((match picker
                       :fzf fzf
                       :skim skim
                       :telescope telescope
                       :fzy fzy)
                     entries begin end options exec reuse?)))
       :stdout_buffered true})))

{: fuzzy}
