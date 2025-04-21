;; fennel-ls: macro-file
(fn m> [mod fun ...]
  `((. (require ,mod) ,fun) ,...))

; These don't need to be macros but it's nice to have tiny helpers in a single file
(fn first [table]
  `(. ,table 1))

(fn second [table]
  `(. ,table 2))

(fn dec [n]
  `(- ,n 1))

(fn inc [n]
  `(+ ,n 1))

(fn defcmd [from to opts]
  `(vim.api.nvim_create_user_command ,from ,to ,(or opts {})))

(fn wo-set [window option value]
  `(vim.api.nvim_set_option_value ,option ,value {:win ,window}))

(fn bo-set [buffer option value]
  `(vim.api.nvim_set_option_value ,option ,value {:buf ,buffer}))

{: m> : first : second : dec : inc : defcmd : wo-set : bo-set}
