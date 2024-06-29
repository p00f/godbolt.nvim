;  Copyright (C) 2023 Chinmay Dalal
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

(import-macros {: defcmd : first} :godbolt.macros)

(fn complete [_ _ _]
  [:fzf :fzy :skim :telescope])

(defcmd :Godbolt
  (fn [opts]
    ((. (require :godbolt.cmd) :godbolt) opts.line1 opts.line2 opts.bang))
  {:bang true :nargs 0 :range "%"})

(defcmd :GodboltCompiler
  (fn [opts]
    ((. (require :godbolt.cmd) :godbolt) opts.line1 opts.line2 opts.bang
                                         (first opts.fargs)))
  {:bang true :nargs 1 : complete :range "%"})

(fn setup-highlights [highlights]
  "Setup highlight groups"
  (icollect [i v (ipairs highlights)]
    (if (= (type v) :string)
        (let [group-name (.. :Godbolt i)]
          (if (= (string.sub v 1 1) "#")
              (vim.cmd.highlight group-name (.. :guibg= v))
              (pcall vim.fn.execute (.. "highlight " v))
              (vim.cmd.highlight group-name :link v))
          group-name))))

(when (not (= 1 vim.g.godbolt_loaded))
  (set vim.g.godbolt_loaded 1)
  (set _G.__godbolt_map {})
  (set _G.__godbolt_exec_buf_map {})
  (set _G.__godbolt_nsid (vim.api.nvim_create_namespace :godbolt))
  (let [config (. (require :godbolt) :config)]
    (when (and config.highlights (not (vim.tbl_isempty config.highlights))
               (not= (. config.highlights 1) :Godbolt1))
      (set config.highlights (setup-highlights config.highlights)))))
