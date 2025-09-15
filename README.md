# expreg-supplement
Improves comment and content-line handling  in expreg
- Splits block/line comments into individual lines; each #, //, ;;, ;, -- … can be selected separately on first expand.
- Select from the first non-blank character to end of line (skips indentation).

## Installation

```elisp
(use-package expreg-supplement
  :straight (:host github :repo "bommbo/expreg-supplement")
```
