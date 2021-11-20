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

(fn get-compiler-list [cmd]
  (var op [])
  (local jobid (vim.fn.jobstart cmd
                 {:on_stdout (fn [_ data _]
                               (vim.list_extend op data))}))
  (local t (vim.fn.jobwait [jobid]))
  (var final [])
  (each [k v (pairs op)]
    (if (not= k 1)
      (table.insert final v)))
  final)


(fn transform [entry]
  "Get the compiler id"
  {:value (. (vim.split entry " ") 1)
   :display entry
   :ordinal entry})

; FIXME
(fn choice [ft]

  (local pickers (require :telescope.pickers))
  (local finders (require :telescope.finders))
  (local conf (. (require :telescope.config) :values))
  (local actions (require :telescope.actions))
  (local actions-state (require :telescope.actions.state))

  (local ft (match ft
              :cpp :c++
              x x))
  (local cmd (string.format "curl https://godbolt.org/api/compilers/%s" ft))
  (local lines (get-compiler-list cmd))
  (var compiler nil)
  (: (pickers.new nil {:prompt_title "Choose compiler"
                       :finder (finders.new_table {:results lines
                                                   :entry_maker transform})
                       :sorter (conf.generic_sorter nil)
                       :attach_mappings (fn [prompt-bufnr map]
                                         (actions.select_default:replace (fn []
                                                                          (actions.close prompt-bufnr)
                                                                          (local selection (actions-state.get_selected_entry))
                                                                          (set compiler (. selection :value)))))})
     :find)
  compiler)

{:compiler-choice choice}
