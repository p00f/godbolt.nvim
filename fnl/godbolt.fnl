(local fun vim.fn)
(local api vim.api)

(fn get [cmd]
  "Get the response from godbolt.org as a lua table"
  (var output_arr [])
  (local jobid (fun.jobstart cmd
                 {:on_stdout (fn [_ data _]
                               (vim.list_extend output_arr data))}))
  (local t (fun.jobwait [jobid]))
  (local json (accumulate [str ""
                           k v (ipairs output_arr)]
                (.. str v)))
  (fun.json_decode json))

(fn build-cmd [compiler text options]
  "Build curl command from compiler, text and flags"
  (local json
    (fun.json_encode
      {:source text
       :options {:userArguments options}}))
  (string.format
    (.. "curl https://godbolt.org/api/compiler/'%s'/compile"
        " --data-binary '%s'"
        " --header 'Accept: application/json'"
        " --header 'Content-Type: application/json'")
    compiler json))

(var config
  [:cpp {:compiler :g112 :options ""}
   :c {:compiler :cg112 :options ""}
   :rust {:compiler :r1560 :options ""}])

(fn setup [cfg]
  (each [k v (pairs cfg)]
    (tset config k v)))

(fn display []
  "Display the assembly in a split"
  (let [text (match (fun.mode)
              :n (api.nvim_buf_get_lines 0 0 -1)
              :v (let [begin (- (fun.getline "'<") 1)
                       end (- (fun.getline ">'") 1)]
                   (api.nvim_buf_get_lines 0 begin end)))
        ft vim.bo.filetype
        asm (get (build-cmd
                   (. config ft :compiler) text (. config ft :options)))
        winid (fun.win_getid)]
    1))

{: display}
