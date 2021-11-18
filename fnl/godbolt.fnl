(local fun vim.fn)

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

(fn display [range]
  (local text (fun.getline range)))
