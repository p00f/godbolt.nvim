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

(local fun vim.fn)
(local api vim.api)
(local wo-set api.nvim_win_set_option)
(import-macros {: m> : dec} :godbolt.macros)

(fn prepare-buf [lines]
  "Prepare the output buffer: set buffer options and add text"
  (let [time (os.date :*t)
        hour time.hour
        min time.min
        sec time.sec]
    (local buf (api.nvim_create_buf false true))
    (api.nvim_buf_set_lines buf 0 0 false lines)
    (api.nvim_buf_set_name buf (string.format "%02d:%02d:%02d" hour min sec))
    buf))

(fn display-output [response]
  "Display the program output in a split"
  (local stderr (icollect [k v (pairs response.stderr)]
                  v.text))
  (local stdout (icollect [k v (pairs response.stdout)]
                  v.text))
  (var lines [(.. "exit code: " response.code)])
  (table.insert lines "stdout:")
  (vim.list_extend lines stdout)
  (table.insert lines "stderr:")
  (vim.list_extend lines stderr)
  (local output-buf (prepare-buf lines))
  (local old-winid (fun.win_getid))
  (vim.cmd :split)
  (vim.cmd (.. "buffer " output-buf))
  (wo-set 0 :number false)
  (wo-set 0 :relativenumber false)
  (wo-set 0 :spell false)
  (wo-set 0 :cursorline false)
  (api.nvim_set_current_win old-winid))

(fn execute [begin end compiler options]
  "Make an execution request and call `display-output` with the response"
  (let [lines (api.nvim_buf_get_lines 0 (dec begin) end true)
        text (fun.join lines "\n")]
    (tset options :compilerOptions {:executorRequest true})
    (local cmd (m> :godbolt.cmd :build-cmd compiler text options :exec))
    (fun.jobstart cmd
                  {:on_exit (fn [_ _ _]
                              (local file
                                     (io.open :godbolt_response_exec.json :r))
                              (local response (file:read :*all))
                              (file:close)
                              (os.remove :godbolt_request_exec.json)
                              (os.remove :godbolt_response_exec.json)
                              (display-output (vim.json.decode response)))})))

{: execute}
