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

(import-macros {: m>} :godbolt.macros)
(local fun vim.fn)
(local api vim.api)

(var config
     {:cpp      {:compiler :g112  :options {}}
      :c        {:compiler :cg112 :options {}}
      :rust     {:compiler :r1560 :options {}}
      :quickfix {:enable false    :auto_open false}})

(fn setup [cfg]
  (if (= 1 (fun.has :nvim-0.6)
           (do
             (m> :godbolt.assembly :init)
             (when cfg (each [k v (pairs cfg)]
                         (tset config k v)))))
      (api.nvim_err_writeln "neovim 0.6+ is required")))

(fn build-cmd [compiler text options exec-asm?]
  "Build curl command from compiler, text and options"
  (let [json (vim.json.encode {:source text : options})
        file (-> :godbolt_request_%s.json
                 (string.format exec-asm?)
                 (io.open :w))]
    (file:write json)
    (io.close file)
    (string.format (.. "curl https://godbolt.org/api/compiler/'%s'/compile"
                       " --data-binary @godbolt_request_%s.json"
                       " --header 'Accept: application/json'"
                       " --header 'Content-Type: application/json'"
                       " --output godbolt_response_%s.json")
                   compiler exec-asm? exec-asm?)))

(fn godbolt [begin end reuse? compiler]
  (let [pre-display (. (require :godbolt.assembly) :pre-display)
        execute (. (require :godbolt.execute) :execute)
        fuzzy (. (require :godbolt.fuzzy) :fuzzy)
        ft vim.bo.filetype
        compiler (or compiler (. config ft :compiler))]
    (var options (if (. config ft)
                     (vim.deepcopy (. config ft :options))
                     {}))
    (let [flags (vim.fn.input
                  {:prompt "Flags: "
                   :default (or options.userArguments "")})]
      (tset options :userArguments flags)
      (let [fuzzy? (accumulate [matches false
                                k v (pairs [:telescope :fzf :skim :fzy])]
                     (if (= v compiler) true matches))]
        (if fuzzy?
            (fuzzy ft begin end options
                   (= true vim.b.godbolt_exec)
                   reuse?)
            (do
              (pre-display begin end compiler options reuse?)
              (when vim.b.godbolt_exec
                (execute begin end compiler options))))))))

{: config : setup : build-cmd : godbolt}
