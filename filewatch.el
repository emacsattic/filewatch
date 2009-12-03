;;; -*-  auto-recompile: t -*-
;;filewatch --- watches files for you, and does stuff if they get modified..
;;; Time-stamp: <2002-06-21 01:10:33 deego>
;;; GPL'ed as under the GNU license..
;; Time-stamp: <2001-01-18 16:36:37 deego>
;; GPL'ed under GNU'S public license..
;; Copyright (C) Deepak Goel 2000
;; Emacs Lisp Archive entry
;; Filename: filewatch.el
;; Package: filewatch
;; Author: Deepak Goel <deego@glue.umd.edu>

;; Version: 2.0.4alpha

;;; Version:
(setq filewatch-version "2.0.4alpha")
(defun filewatch-version () filewatch-version)

(setq fw-version filewatch-version)
(defun fw-version () filewatch-version)


;;; Author(s)
;;; -- Deepak Goel (deego@glue.umd.edu)


;; See also: 
;;; 2002-06-21 T01:10:14-0400 (Friday)    D. Goel
 ;; just also saw an analog.el on emacs lisp list.. which does sth similar



;;; Thanks to 
;;;  James Cooley

;;; You will need to download this generalprofile.el
;;; which comes with filewatch, edit it to your needs, and also download
;;; timerfunctions.el. Please have an emacs installed on your system,
;;; pref. emacs20 or higher.  You also need runshell.el to run filewatch..


;;;====================================================
;;;AVAILABILITY: This code and associated files can be gotten from
;;;http://www.glue.umd.edu/~deego/emacs.html
;;;====================================================
;;;CONTRIBUTIONS: are most welcome, and will lead to invitation for
;;;co-authorship, providing you agree to GNU-freeness..
;;;====================================================
;;;COMMENTARY: 
;;;The userguide is now obsolete..  All information you need is now
;;;available here--> Filewatch will watch a list of files for you..
;;;whenever one of those files has been changed, it will return you
;;;the name of the file, and run a pre-defined command on the name of
;;;the file..  (Using this, for instance, you can auto-process your
;;;.tex files realtime as they updated, and view them, thus
;;;effectively having a near-WYSIWIG, and hence the old name
;;;autoview.el ).  

;;;U should set up your own fw-command as follows: Create a
;;;file generalprofile.el, and in it, set up your own
;;;fw-command.  If you are Sam, and want to instead use
;;;samprofile.el, setq fw-profile-feature to 'samprofile in your
;;;.emacs.

;;;The defaults here assume that u like to edit a .tex.e file, and you
;;;want process it via elder, and then gv it.  You don't have to use
;;;these defaults, but if you use these exact same defaults, you will
;;;obviously need to have the following on your system: latex, elder,
;;;runshell.el.  THE FOLLOWING IS A *MUST* NO MATTER WHAT YOU DO: YOU
;;;NEED TO DOWNLOAD TIMERFUNCTIONS.EL AVAILABLE FROM THIS VERY WEBSITE
;;;FOR FILEWATCH.EL TO WORK.  I realize that a large number of people
;;;use latex *without* elder, so if anyone mails me their own
;;;profile-file they set up either for latex or for other
;;;applications, that will be really wonderful.



;;;====================================================
;;;QUICK START: Drop this somewhere in your emacs load-path, and add
;;; (require 'filewatch) to your .emacs. 
;;;
;;; USAGE:
;;; Thereafter, (if u like: dedicate an emacs to filewatch).  In
;;; emacs, type M-x filewatch to use it.  
;;; You may like to add
;;; (setq fw-files '("myfile1" "myfile2" ) to your .emacs. 
;;; 
;;; If you like to use fw-add-file a lot, add this to your .emacs:
;;; (global-set-key "\C-cf" 'fw-add-file)

;;; if u r the non-emacs type who likes to do things from unix-shell: 
;;;if u add
;;;alias filewatch 'emacs -l ~/emacs/filewatch.el -f filewatch'
;;; to your .aliases (tcsh) then, typing filewatch will start it..
;;; if there are certain .tex files u edit heavily, u can add them to yr
;;; fw-files list by editing yr .emacs..
 


;;;====================================================

;;;====================================================

;USER OPTIONS BEGIN
;;;====================================================

(require 'cl)
(require 'timerfunctions)

;;;(require 'runshell)
;;;PROFILES ARE SET HERE: 

(defvar fw-loudly nil)

(defvar fw-profile-feature 'generalprofile
" U should set up your own fw-command as follows: Create a file
generalprofile.el, and in it, set up your own fw-command.  If
you are Sam, and want to instead use samprofile.el, setq
fw-profile-feature to samprofile.el in your .emacs."
)



;;;(defvar fw-overrule-error nil)

;;;(defvar fw-ext ".tex.e")

;;; (defvar fw-view-command
;;;      (concat "/bin/cp " *file* ".ps  autoview.ps; " 
;;; "gv -nowatch -scale 2 autoview.ps &")
;;; )
;;; FOR ME:

(defvar  fw-command 'fw-default-command
"Please setq this to 'your-command you like, and define that command."
)



(defvar fw-files '("~/more/tex/myarticle.tex"
		   "~/more/tex/article2.tex")
  "This is the list of files to watch.  The first file found that is
modified from when it was modified last will be returned and processed
upon.")


(defun fw-get-default-last-modified-times (files)
  (if (null files) nil
    (cons nil
	  (mapcar
	   (lambda (arg) (current-time))
	   (cdr files))))
)


(defvar fw-last-modified-times 
  (fw-get-default-last-modified-times fw-files)
  "This is the list of last-processed times assumed for each file.  
If the new processed time is detected to be later than this time, the
file is assumed to have been updated.  By default, I set it to be NIl
for the first file, and current-time for others, which means you would
be interested in initially viewing the first file on the list as soon as
filewatch loads up, while others show up only if they are modified.

")

(defun fw-update-information ()
  "If you change stuff in the middle of running..
If you change fw-files in the middle of the program, then this
function will try to ensure no errors. "
  (interactive)
  (setq fw-last-modified-times 
	(fw-get-default-last-modified-times fw-files))
)

;;;====================================================
;;;====================================================

(defvar fw-repeat-time 6
"Argument to tf-run-with-idle-timer"

)
(defvar fw-initial-time 6
"Argument to tf-run-with-idle-timer"
)

(defvar  fw-include-runtime nil
"Argument to tf-run-with-idle-timer"
)



;;;====================================================
;USER OPTIONS END
; overrule-error => show gv even if error-found..

;;;====================================================



(defun fw-get-last-modified-time (file)
  "Gets file's last modified-time."
					;We need not just the last
					; 16 significant bits, but all..
;;;    (second (sixth (file-attributes file))) 
  (sixth (file-attributes file))
)

; this ensures initial processing..
; (setq *last-modified-time* nil)
;(setq *last-modified-time* (fw-ignore-errors (last-modified-time-my *file*)))

; (defun elatstart ()
;  "Automatically elatexes *file* whenever needed. The main function
; here.. Does so by running elatrun whenever it finds it idle.. Does not
; work for more than a day continuously.
; "
;   (interactive)
;   (cd *directory*)
;   (run-with-idle-timer *initialtime* "repeat" 'elatrestartrun)
; )

; ;;;====================================================
; (defun elatrestartrun ()
;   "Internal."
;  (setq *begintime* (cadr (current-time)))
;  (elatrun)
; )
; ;;;====================================================
; (defun elatrun ()
; "Whenever emacs is idle for *initialtime* sec., this function is
; called by elatstart. This function then runs elat on the file.  Then,
; sets a one-time-timer to run itself for time + repeat seconds in case
; emacs remains idle.... which
; will do the same and so on.., so that as long as emacs is idle,
; elatrun will run every repeat seconds. Does not work for more than a
; day continuosly because i am using \(cadr \(current-time\)\). 
; WHEN I SAY IT WILL REPEAT EVERY *repeattime* SECONDS, I MEAN THAT THE
; TIME TO RUN ELAT IS *NOT* COUNTED TOWARDS THAT. IN FACT, I GO TO GREAT
; LENGTHS TO ENSURE THAT---SEE KEEPTRACK BELOW..
; "
; (let ((keeptrack (cadr (current-time))))
;  (cd *directory*)
;  (elat)
;  (setq *begintime* (+ *begintime* (- (cadr (current-time)) keeptrack)))
;  (run-with-idle-timer (+ *repeattime* (- (cadr (current-time))
; 					 *begintime*)) 
		      
		      
; ; the one below is no good---doesn't even respect the users' options.
; ; (run-at-time nil *repeattime* 'elat)
; ; (run-at-time nil *repeattime* 'elatwhenidle)

; )


;;;###autoload
(defalias 'filewatch 'fw-start)

;;;###autoload
(defun fw-load-profile-file ()
  (if (not (fw-ignore-errors (require fw-profile-feature)))
      (fw-ignore-errors (load fw-profile-feature)))
)


;;;###autoload
(defun fw-start (&rest files)
"The main function.
If this function is passed a list of files, it adds them to the
file-list to watch *after* loading your profile-file..
"
  (interactive)
  (fw-load-profile-file)
  (mapcar (lambda (file)
	    (add-to-list 'fw-files file))
	  files)
  (fw-update-information)
  (tf-run-with-idle-timer fw-initial-time  t fw-repeat-time t
			  fw-include-runtime 'fw-once)
)

;;;====================================================
;;;(global-set-key "\C-cv" 'elatview)
;;; (defun elatview ()
;;;   "Ghostview command."
;;;   (interactive)
;;;   (shell-command (concat "cd " *directory*))
;;;   (shell-command *view-command*))

;;;(global-set-key "\C-ce" 'elat)

;;;(defun elatwhenidle ()
;;;  (run-with-idle-timer 5 nil 'elat))

(defun fw-once ()
"One instance of processing. Bound to C-cC-e.

Finds the first file from the list that has been modified, if any, and
runs fw-command on it. "
  (interactive)
  (fw-message "INVOKED")
  (let* ((new-times
	  (mapcar 'fw-get-last-modified-time fw-files))
	 (current-file (fw-do-time-stuff 
			new-times))
	 )
    (fw-message (concat "File: " (if (stringp current-file) 
				     current-file
				   (format "%S" current-file))))
    (if (not (null current-file))
	(apply fw-command (list current-file)) 
					; the fw-command here should
					 ; NOT be quoted, since it
					 ; evaluates to a symbol!
      ))  
  )

(defun fw-do-time-stuff (new-times)
  "Finds file to process.  Kinda internal
Also updates fw-last-modified-times.
old-times-copy is a *copy* of global-times..
"
  (let ((pos (filewatch-internal-find-pos 
	      (copy-tree fw-last-modified-times)
	      new-times 0)))
    (if pos 
	(progn
	  (fw-message "CHANGING MODIFIED TIME")
	  (setq fw-last-modified-times
		(fw-replace pos (copy-tree fw-last-modified-times)
			    (copy-tree (nth pos new-times))))))
					; don't wanna use setf
    (if pos (nth pos fw-files) pos)
    ))


(defun filewatch-internal-find-pos (ls1 ls2 pos)
  "Finds the first pos where ls2 (new-times) exceeds ls1 (old-times).
Always call this fcn with a pos of 0. the list-lengths should please
be same.. If can't find any such pos, return  nil.
"
  (if (null ls1)
      (if (not (null ls2))
	  (error "I told you lengths be same!")
	nil) ;; return nil if no such pos..
    (if (fw-time> (car ls2) (car ls1))
	pos
      (filewatch-internal-find-pos (cdr ls1) (cdr ls2) (+ 1 pos))))
)


(defun fw-time> (ls2 ls1)
  " tells if ls2 is greater.. 
list1 and list2 can be times in various format.. Each can be upto 2--3
integers long (see documentation of current-time).  Moreover,
sometimes one of the lists can be nil, because that has special
meaning in this package.  Nil means time is effectively (- infinity).
Thus, this function assumes each list has the leftmost as the most
significant digit..etc.. "
  (or 
   (and (null ls1) (not (null ls2)))
   (and (not (null ls2))
	(let ((diff (- (car ls2) (car ls1))))
	  (or 
	   (> diff 0)
	   (and (= diff 0) (fw-time> (cdr ls2) (cdr ls1)))))))
)





;;;====================================================

;;;   (let* 
;;;       ((newtime (last-modified-time-my (concat *file* *ext*)))
;;;        (modifiedp (not (equal *last-modified-time* newtime))))


;;;     (setq *last-modified-time* newtime)
;;;     (if modifiedp
;;; 	(progn
;;; 	  (get-buffer-create "*Shell Command Output*")
;;; 	  (get-buffer-create "*Previous Shell Command Output*")
;;; 	  (kill-region (point-min) (point-max))
;;; 	  (insert-buffer "*Shell Command Output*")
;;; 	  (switch-to-buffer "*Shell Command Output*")
;;; 	  (kill-region (point-min) (point-max))
;;; 	  (shell-command "echo Running elat now.")
;;; 	  (shell-command (concat "cd " *directory*))
;;; 	  (shell-command *command*)
;;; 	  (switch-to-buffer "*Shell Command Output*")
;;; 	  (goto-char (point-min))
;;; 	  (search-forward "about the first error" nil t)
;;; 	  (let (error-found)
;;; 	    (if 
;;; 		(or
;;; 		 (search-forward "Error" nil "go-to-end-otherwise")
;;; 		 (progn
;;; 		   (goto-char (point-min))
;;; 		   (search-forward "Undefined control sequence" nil "go-to-end-otherwise"))
;;; 		 (progn
;;; 		   (goto-char (point-min))
;;; 		   (search-forward "Emergency stop" nil "go-to-end-otherwise")))
;;; 					; (fw-ignore-errors (bold-region
;;; 					;		(- (point) 7)
;;; 					;		(point))))
;;; 		(setq error-found t))
;;; 	    (if error-found
;;; 		(progn
;;; 		  (insert "[[[<---**ERROR**DETECTED**DURING**RUN**!!***]]]")
;;; 		  (ding t)
;;; 		  (ding t)
;;; 		  (ding t)
;;; 		  (ding t)
;;; 		  (ding t)
;;; 		  (recenter 9)
		  
;;; 		  ))			; else gv..
;;; 	    (if *viewp* 
;;; 		(if (or *overrule-error*  (not error-found))
;;; 		    (progn
;;; 		      (fw-ignore-errors (delete-process 
;;; 				      "*Async Shell Command*"))
		      
;;; 		      (elatview
;;; 		       )))))
	    
;;; 	  (switch-to-buffer "*Shell Command Output*")
;;; 	  (insert (current-time-my))
;;; 	  (line-to-top-of-window)
;;; 					;	  (shell-command "echo Done")
;;; 	  )))
;;;   )



;;;====================================================
;;;====================================================
; The following might be useful in a batch mode..

; (defun do-upon-revert (file sittime action &optional skip-initial)
;   "NOT CURRENTLY IN USE.
; If a file exists and has been modified, perform action.
; The action is performed by default the first time this function is
; launched, unless skip-initial is non-nil. Any action is
; performed only if the file exists. Is basically a generalization of
; auto-revert-buffer, and helps me auto-process my latex documents. This
; process is more suited for background batch type jobs, and will not be
; used here any more. The problem with background jobs, however, is that
; the sit-for won't work, so I had better comment it out.. But that
; would mean continuous CPU wastage.."
;   (let ((aatime (last-modified-time-my file)) bbtime modifiedp)
;     (if (and aatime (not skip-initial)) (eval action))
;     (while (> 1 0)
;       (sit-for sittime)
;       (setq bbtime (last-modified-time-my file))
;       (setq modifiedp (equal aatime bbtime))
;       (setq aatime bbtime)
;       (if (and modifiedp aatime)
; 	  (eval action)))))



;;;====================================================
;;; If you really want to use my defined latex default's they follow here:
;;;====================================================

;;;###autoload
(defun fw-dir-file-ext (file)
  " Used by filewatch's default file-viewer function. 
Given a file's pathname, returns a list of directory, filename
and extension.  The extension contains the ., and the directory
contains the /"
  (interactive "s String: ")
  (with-temp-buffer 
    (insert file)
    (goto-char (point-max))
    (let ((aa (progn
		(goto-char (point-max))
		(search-backward "/" nil t)))
	  (bb (progn
		(goto-char (point-max))
		(search-backward "." nil t))))
      (setq aa (if (null aa) (point-min) (+ aa 1)))
      (if (null bb) (setq bb (point-max)))
      (if (> aa bb) (setq bb (point-max))) ;that means that the . occurs in
				   ;the pathname rather than filename.
      (let ((cc
	     (list 
	      (buffer-substring (point-min) aa)
	      (buffer-substring aa bb)
	      (buffer-substring bb (point-max)))))
	(if (interactive-p) (message (format "%S" cc)))
	cc)))
)




(defvar fw-latex-default-view-p t
"worry only if u use fw-latex-functions.. "
)

(defun fw-default-command (file)
  "The default command to run on file.. If the user does not specify
any!  We prefer to use runshell which is built on top of
(e)shell. Please get it! This also needs emacs' default 'cl.
"

  (require 'runshell)
  (runshell-set-for-shell)
  (fw-ignore-errors (kill-buffer "*shell*"))
  (shell)
  (let ((dir-file-ext (fw-dir-file-ext file)))
    (runshell-cd (first dir-file-ext))
    (runshell-command (concat "latex " (second dir-file-ext)))
    (runshell-command (concat "latex " (second dir-file-ext)))
    (runshell-command (concat "dvips " (second dir-file-ext)))
    (runshell-input-dont-wait (concat "gv  " (second dir-file-ext)))
    (switch-to-buffer "*shell*")
    (goto-char (point-max))
    (fw-look-for-latex-error)
    (recenter 10)

))
  

(defun fw-message (&rest args)
  "Returns nil if didn't play.. "
 (if fw-loudly  (progn
		  (apply 'message args)
		  (first args))
   nil
		  )
)

(defun fw-message-slowly (&rest args)
  
  (if (apply 'fw-message args)
      (sit-for 1)))


(defun fw-replace (pos list val)
  (if (zerop pos) (cons val (cdr list))
    (cons (car list) (fw-replace (- pos 1) (cdr list) val))
))


;;;###autoload
(defun fw-add-file (file)
  "Adds a file to the filewatch list.  
Also resets defaults: means: the latest file you have thus added  is
assumed to be modified, while all other files in the list are assumed
to have been unmodified (until any further changes you make).   " 
  (interactive "f File: ")
  (add-to-list 'fw-files file)
  (fw-update-information)
)


(defun fw-signal-latex-error (&optional point)
  "should return a string, that can then be used to signal error,
if needed.."
  (if point (goto-char point))
  (ding t)
  (ding t)
  (ding t)
  (ding t)
  (recenter 10)
  (message "LATEX ERROR DETECTED" )
)

(defun fw-look-for-latex-error ()
  (interactive)
  (let ((ref-pt (point))
	(found-pt nil)
	(case-fold-search nil)
	(error-list 
	 '(   
	   "error"  "Error" "Undefined control" 
	    "Missing " "or forgotten"  "\n!"
	    "capacity exceeded"
	    )))
    (while (and (not (null error-list)) (null found-pt))
      (goto-char ref-pt)
      (setq found-pt (search-backward (car error-list) nil t))
      ;;(fw-message-slowly "found-pt %S" found-pt)
      (setq error-list (cdr error-list))
      ;;(fw-message-slowly "Error-list %S" error-list))
      )
    (if found-pt
	(progn
	  (goto-char found-pt)
	  (message "LATEX ERROR DETECTED")
	  found-pt
	  )
      (progn
	(message "No latex error detected ")
	nil)))
)


;;;Tue Jan 23 17:42:08 2001
;;;###autoload
(defmacro fw-ignore-errors (&rest body)
  "Like ignore-errors, but tells the error.."
  (let ((err (gensym)))
    (list 'condition-case err (cons 'progn body)
	 (list 'error
	       (list 'message
		     (list 'concat
			   "IGNORED ERROR: "
			   (list 'error-message-string err)))))
))

;;;====================================================
(provide 'filewatch)

;;;filewatch.el ends here..
