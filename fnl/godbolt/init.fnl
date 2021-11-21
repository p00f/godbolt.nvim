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



(if (not vim.g.godbolt_loaded)
  (global gb-exports {}))

; Setup
(var godbolt_config
  {:cpp {:compiler :g112 :options {}}
   :c {:compiler :cg112 :options {}}
   :rust {:compiler :r1560 :options {}}})

(fn setup [cfg]
  (if (fun.has :nvim-0.6)
    (if vim.g.godbolt_loaded
      nil
      (do (tset gb-exports :bufmap {})
          (tset gb-exports :nsid (api.nvim_create_namespace :godbolt))
          (if cfg (each [k v (pairs cfg)]
                    (tset godbolt_config k v)))
          (set vim.g.godbolt_loaded true))
      (api.nvim_err_writeln "neovim 0.6 is required"))))




; Helper functions
(fn build-cmd [compiler text options]
  "Build curl command from compiler, text and options"
  (local json (vim.json.encode {:source text
                                :options options}))
  (string.format
    (.. "curl https://godbolt.org/api/compiler/'%s'/compile"
        " --data-binary '%s'"
        " --header 'Accept: application/json'"
        " --header 'Content-Type: application/json'")
    compiler json))

(fn get-compiler [compiler flags]
  "Get the compiler the user chose or the default one for the language"
  (let [ft vim.bo.filetype]
    (var options (. godbolt_config ft :options))
    (tset options :userArguments flags)
    (if compiler
      (if (= :telescope compiler)
        [((. (require :godbolt.telescope) :compiler-choice) ft) options]
        [compiler options])
      (do
        [(. godbolt_config ft :compiler) (. godbolt_config ft :options)]))))




(fn godbolt [begin end compiler flags]
  (let [pre-display (. (require :godbolt.assembly) :pre-display)
        execute (. (require :godbolt.execute) :execute)]
    (pre-display begin end compiler flags)
    (if vim.b.godbolt_exec
      (execute begin end compiler flags))))

{: setup : build-cmd : get-compiler : godbolt}
