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
(import-macros {: m>} :macros)

; Execute
(fn echo-output [response]
  (if (= 0 (. response :code))
      (let [output (accumulate [str "" k v (pairs (. response :stdout))]
                     (.. str "\n" (. v :text)))]
        (api.nvim_echo [[(.. "Output:" output)]] true {}))
      (let [err (accumulate [str "" k v (pairs (. response :stderr))]
                  (.. str "\n" (. v :text)))]
        (api.nvim_err_writeln err))))

(fn execute [begin end compiler options]
  (let [lines (api.nvim_buf_get_lines 0 (- begin 1) end true)
        text (fun.join lines "\n")]
    (tset options :compilerOptions {:executorRequest true})
    (local cmd (m> :godbolt.init :build-cmd compiler text options))
    (var output_arr [])
    (local _jobid
           (fun.jobstart cmd
                         {:on_stdout (fn [_ data _]
                                       (vim.list_extend output_arr data))
                          :on_exit (fn [_ _ _]
                                     (echo-output (-> output_arr
                                                      (fun.join)
                                                      (vim.json.decode))))}))))

{: execute}
