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

(import-macros {: m>} :godbolt.macros)
(local fun vim.fn)
(local api vim.api)


(fn setup [cfg]
  (if (fun.has :nvim-0.6)
      (if (not vim.g.godbolt_loaded)
          (do
            (tset _G :_private-gb-exports {})
            (tset _G._private-gb-exports :bufmap {})
            (tset _G._private-gb-exports :nsid (api.nvim_create_namespace :godbolt))
            (set vim.g.godbolt_config
                 {:cpp {:compiler :g112 :options {}}
                  :c {:compiler :cg112 :options {}}
                  :rust {:compiler :r1560 :options {}}})
            (if cfg (each [k v (pairs cfg)]
                      (tset vim.g.godbolt_config k v)))
            (set vim.g.godbolt_loaded true)))
      (api.nvim_err_writeln "neovim 0.6 is required")))

(fn build-cmd [compiler text options]
  "Build curl command from compiler, text and options"
  (var json (vim.json.encode {:source text : options}))
  (local file (io.open :godbolt_request.json :w))
  (file:write json)
  (io.close file)
  (local ret (string.format (.. "curl https://godbolt.org/api/compiler/'%s'/compile"
                                " --data-binary @godbolt_request.json"
                                " --header 'Accept: application/json'"
                                " --header 'Content-Type: application/json'"
                                " --output godbolt_response.json")
                            compiler))
  ret)

(fn godbolt [begin end compiler-arg]
  (if vim.g.godbolt_loaded
      (let [pre-display (. (require :godbolt.assembly) :pre-display)
            execute (. (require :godbolt.execute) :execute)
            ft vim.bo.filetype]
        (var options (if (. vim.g.godbolt_config :ft)
                         (vim.deepcopy (. vim.g.godbolt_config :ft :options))
                         {}))
        (if compiler-arg
            (let [flags (vim.fn.input {:prompt "Flags: " :default ""})]
              (tset options :userArguments flags)
              (match compiler-arg
                (where fuzzy
                       (or (= :telescope fuzzy) (= :fzf fuzzy) (= :skim fuzzy)
                           (= :fzy fuzzy)))
                (m> :godbolt.fuzzy :fuzzy fuzzy ft begin end options
                    (= true vim.b.godbolt_exec))
                _ (do
                    (pre-display begin end compiler-arg options)
                    (if vim.b.godbolt_exec
                        (execute begin end compiler-arg options)))))
            (do
              (local def-comp (. vim.g.godbolt_config ft :compiler))
              (pre-display begin end def-comp options)
              (if vim.b.godbolt_exec
                  (execute begin end def-comp options)))))
      (api.nvim_err_writeln "setup function not called")))

{: setup : build-cmd : godbolt}

