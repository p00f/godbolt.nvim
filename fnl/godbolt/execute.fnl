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

(local fun vim.fn)
(local api vim.api)
(local wo-set api.nvim_win_set_option)
(import-macros {: m> : dec} :godbolt.macros)
(var exec-buf-map {})

(fn prepare-buf [lines source-buf reuse?]
  "Prepare the output buffer: set buffer options and add text"
  (let [time (os.date :*t)
        hour time.hour
        min time.min
        sec time.sec
        buf (if (and reuse? (. exec-buf-map source-buf))
                (. exec-buf-map source-buf)
                (api.nvim_create_buf false true))]
    (tset exec-buf-map source-buf buf)
    (api.nvim_buf_set_lines buf 0 -1 false lines)
    (api.nvim_buf_set_name buf (string.format "%02d:%02d:%02d" hour min sec))
    buf))

(fn display-output [response source-buf reuse?]
  "Display the program output in a split"
  (let [stderr (icollect [k v (pairs response.stderr)] v.text)
        stdout (icollect [k v (pairs response.stdout)]
                 v.text)
        lines [(.. "exit code: " response.code)]]
    ;; fill output buffer
    (table.insert lines "stdout:")
    (vim.list_extend lines stdout)
    (table.insert lines "stderr:")
    (vim.list_extend lines stderr)
    ;; display output window
    (let [exists (not= nil (. exec-buf-map source-buf))
          output-buf (prepare-buf lines source-buf reuse?)
          old-winid (fun.win_getid)]
      (when (not (and reuse? exists))
        (vim.cmd :split)
        (vim.cmd (.. "buffer " output-buf))
        (wo-set 0 :number false)
        (wo-set 0 :relativenumber false)
        (wo-set 0 :spell false)
        (wo-set 0 :cursorline false))
      (api.nvim_set_current_win old-winid))))

(fn execute [begin end compiler options reuse?]
  "Make an execution request and call `display-output` with the response"
  (let [lines (api.nvim_buf_get_lines 0 (dec begin) end true)
        text (fun.join lines "\n")
        source-buf (fun.bufnr)]
    (tset options :compilerOptions {:executorRequest true})
    (let [cmd (m> :godbolt.cmd :build-cmd compiler text options :exec)]
      (fun.jobstart cmd
                    {:on_exit (fn [_ _ _]
                                (let [file (io.open :godbolt_response_exec.json
                                                    :r)
                                      response (file:read :*all)]
                                  (file:close)
                                  (os.remove :godbolt_request_exec.json)
                                  (os.remove :godbolt_response_exec.json)
                                  (display-output (vim.json.decode response)
                                                  source-buf reuse?)))}))))

{: execute}
