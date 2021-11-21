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


(fn fzf [ft begin end options exec]
  (let [ft (match ft :cpp :c++ x x)
        cmd (string.format "curl https://godbolt.org/api/compilers/%s" ft)
        lines (get-compiler-list cmd)]

    (fun.fzf#run {:source lines
                  :window {:width 0.9 :height 0.6}
                  :sink (fn [choice]
                          (local compiler (-> choice (vim.split " ") (. 1)))
                          ((. (require :godbolt.assembly) :pre-display)
                           begin end compiler options)
                          (if exec
                            ((. (require :godbolt.execute) :execute)
                             begin end compiler options)))})))

{: fzf}
