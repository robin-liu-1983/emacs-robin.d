;;; wiki-summary.el --- View Wikipedia summaries in Emacs easily.

;; Copright (C) 2015 Danny Gratzer <jozefg@cmu.edu>

;; Author: Danny Gratzer
;; URL: https://github.com/jozefg/wiki-summary.el
;; Package-Version: 20150408.1422
;; Keywords: wikipedia, utility
;; Package-Requires: ((emacs "24"))
;; Version: 0.1

;;; Commentary:

;; It's often the case when reading some document in Emacs (be it
;; code text or prose) that I come across a word or phrase that I
;; don't know. In order to simplify my feedback loop when wiki-summary
;; lets me look up something in a couple seconds.
;;
;; To use this package, simply call M-x wiki-summary (or bind it to a key).
;; This will prompt you for an article title to search. For convience,
;; this will default to the word under the point. When you hit enter
;; this will query Wikipedia and if an article is found, bring up the
;; title in a separate window. Spaces will be properly escaped so
;; something like "Haskell (programming language)" will bring up the
;; intended page.
;;
;; I'm not sure exactly what else people would want out of this package.
;; Feature request issues are welcome.

(require 'url)
(require 'json)
(require 'thingatpt)

(eval-when-compile
  ; This stops the compiler from complaining.
  (defvar url-http-end-of-headers))

;;;###autoload
(defun wiki-summary/make-api-query (s)
  "Given a wiki page title, generate the url for the API call
   to get the page info"
  (let ((pre "https://en.wikipedia.org/w/api.php?continue=&action=query&titles=")
        (post "&prop=extracts&exintro=&explaintext=&format=json&redirects")
        (term (url-hexify-string (replace-regexp-in-string " " "_" s))))
    (concat pre term post)))

;;;###autoload
(defun wiki-summary/extract-summary (resp)
  "Given the JSON reponse from the webpage, grab the summary as a string"
  (let* ((query (plist-get resp 'query))
         (pages (plist-get query 'pages))
         (info (cadr pages)))
    (plist-get info 'extract)))

;;;###autoload
(defun wiki-summary/format-summary-in-buffer (summary)
  "Given a summary, stick it in the *wiki-summary* buffer and display the buffer"
  (let ((buf (generate-new-buffer "*wiki-summary*")))
    (with-current-buffer buf
      (princ summary buf)
      (fill-paragraph)
      (goto-char (point-min))
      (text-mode)
      (read-only-mode))
    (display-buffer buf)))

;;;###autoload
(defun wiki-summary (s)
  "Return the wikipedia page's summary for a term"
  (interactive
   (list
    (read-string (concat
                  "Wikipedia Article"
                  (if (thing-at-point 'word)
                      (concat " (" (thing-at-point 'word) ")")
                    "")
                  ": ")
                 nil
                 nil
                 (thing-at-point 'word))))
  (save-excursion
    (url-retrieve (wiki-summary/make-api-query s)
       (lambda (events)
         (message "") ; Clear the annoying minibuffer display
         (goto-char url-http-end-of-headers)
         (let ((json-object-type 'plist)
               (json-key-type 'symbol)
               (json-array-type 'vector))
           (let* ((result (json-read))
                  (summary (wiki-summary/extract-summary result)))
             (if summary
                 (wiki-summary/format-summary-in-buffer summary)
               (message "No article found"))))))))

(provide 'wiki-summary)

;;; wiki-summary.el ends here