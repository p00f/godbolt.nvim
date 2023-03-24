;  Copyright (C) 2021-2023 Chinmay Dalal
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
     {:languages {:cpp      {:compiler :g122  :options {}}
                  :c        {:compiler :cg122 :options {}}
                  :rust     {:compiler :r1680 :options {}}}
      :quickfix {:enable false    :auto_open false}
      :url "https://godbolt.org"})

(fn setup [cfg]
  (if (= 1 (fun.has :nvim-0.6)
           (do
             (when cfg (each [k v (pairs cfg)]
                         (tset config k v)))))
      (api.nvim_err_writeln "neovim 0.6+ is required")))

{: config : setup}
