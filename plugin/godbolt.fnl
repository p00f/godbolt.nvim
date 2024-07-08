;  Copyright (C) 2023-2024 Chinmay Dalal
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
