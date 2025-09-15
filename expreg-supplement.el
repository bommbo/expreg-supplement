;;; expreg-supplement.el --- Supplemental expanders for expreg -*- lexical-binding: t; -*-

;; Copyright (C) 2025 bommbo
;; Author: bommbo
;; URL: https://github.com/bommbo/expreg-supplement
;; Version: 1.0.0
;; Package-Requires: ((emacs "30.1"))
;; Keywords: convenience, expreg, region, comment

;;; Commentary:
;; 1. Strip trailing newline from comment regions (tree-sitter & syntax-ppss).
;; 2. Add `content-line'  : first non-blank char → end of line.
;; 3. Add `trailing-comment' : comment start → end of line (language-agnostic).
;; Global, zero config, loads after expreg.

;;; Code:

(with-eval-after-load 'expreg
  ;; ------------------------------------------------------------------
  ;; 1. Remove trailing newline from tree-sitter comment nodes
  ;; ------------------------------------------------------------------
  (defun expreg-supplement--treesit ()
	"Return tree-sitter regions with trailing newline removed from comments."
	(when (treesit-parser-list)
	  (let ((parsers (append (treesit-parser-list)
							 (and (fboundp #'treesit-local-parsers-at)
								  (treesit-local-parsers-at (point)))))
			result)
		(dolist (parser parsers)
		  (let* ((node (treesit-node-at (point) parser))
				 (root (treesit-parser-root-node parser))
				 (lang (treesit-parser-language parser)))
			(while node
			  (let* ((beg (treesit-node-start node))
					 (end (treesit-node-end node))
					 (type (treesit-node-type node)))
				(when (and (string-match-p (rx bos (or "comment" "line_comment")) type)
						   (> end 0)
						   (eq ?\n (char-before end)))
				  (setq end (1- end)))
				(unless (treesit-node-eq node root)
				  (push (cons (intern (format "treesit--%s" lang))
							  (cons beg end))
						result)))
			  (setq node (treesit-node-parent node)))))
		result)))

  ;; Also strip newline from syntax-ppss comment regions
  (advice-add #'expreg--comment :filter-return
			  (lambda (regions)
				(mapcar (lambda (r)
						  (let ((end (cddr r)))
							(if (and (> end 0) (eq ?\n (char-before end)))
								(cons (car r) (cons (cadr r) (1- end)))
							  r)))
						regions)))

  ;; ------------------------------------------------------------------
  ;; 2. Content-line: first non-blank character to end of line
  ;; ------------------------------------------------------------------
  (defun expreg-supplement--content-line ()
	"Select from first non-blank character to end of line."
	(save-excursion
	  (forward-line 0)
	  (skip-chars-forward " \t")
	  (let ((beg (point)))
		(end-of-line)
		(list `(content-line . ,(cons beg (point)))))))

  ;; ------------------------------------------------------------------
  ;; 3. Trailing-comment: language-agnostic end-of-line comment
  ;; ------------------------------------------------------------------
  (defun expreg-supplement--trailing-comment ()
	"Select comment from comment-start to end of line, adapting to language."
	(let* ((bol (line-beginning-position))
		   (eol (line-end-position))
		   ;; Use mode's own comment regex, fallback to common starters
		   (skip-re (or comment-start-skip
						(rx (group (or "#" ";" "//" "--" "/*"))
							(* space)))))
	  (when-let ((start (save-excursion
						  (goto-char bol)
						  (when (re-search-forward skip-re eol t)
							(match-beginning 0)))))
		(list `(trailing-comment . ,(cons start eol))))))

  ;; Register all expanders (highest priority)
  (add-to-list 'expreg-functions 'expreg-supplement--treesit t)
  (add-to-list 'expreg-functions 'expreg-supplement--content-line t)
  (add-to-list 'expreg-functions 'expreg-supplement--trailing-comment t))

(provide 'expreg-supplement)
;;; expreg-supplement.el ends here
