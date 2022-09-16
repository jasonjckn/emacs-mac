;;; image-dired-external.el --- External process support for Image-Dired  -*- lexical-binding: t -*-

;; Copyright (C) 2005-2022 Free Software Foundation, Inc.

;; Author: Mathias Dahl <mathias.rem0veth1s.dahl@gmail.com>
;; Keywords: multimedia

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'dired)
(require 'exif)

(require 'image-dired-util)

(declare-function image-dired-display-image "image-dired")
(declare-function clear-image-cache "image.c" (&optional filter))

(defvar image-dired-dir)
(defvar image-dired-main-image-directory)
(defvar image-dired-rotate-original-ask-before-overwrite)
(defvar image-dired-thumb-height)
(defvar image-dired-thumb-width)
(defvar image-dired-thumbnail-storage)

(defgroup image-dired-external nil
  "External process support for Image-Dired."
  :prefix "image-dired-"
  :link '(info-link "(emacs) Image-Dired")
  :group 'image-dired)

(defcustom image-dired-cmd-create-thumbnail-program
  (if (executable-find "gm") "gm" "convert")
  "Executable used to create thumbnail.
Used together with `image-dired-cmd-create-thumbnail-options'."
  :type 'file
  :version "29.1")

(defcustom image-dired-cmd-create-thumbnail-options
  (let ((opts '("-size" "%wx%h" "%f[0]"
                "-resize" "%wx%h>"
                "-strip" "jpeg:%t")))
    (if (executable-find "gm") (cons "convert" opts) opts))
  "Options of command used to create thumbnail image.
Used with `image-dired-cmd-create-thumbnail-program'.
Available format specifiers are: %w which is replaced by
`image-dired-thumb-width', %h which is replaced by `image-dired-thumb-height',
%f which is replaced by the file name of the original image and %t
which is replaced by the file name of the thumbnail file."
  :version "29.1"
  :type '(repeat (string :tag "Argument")))

(defcustom image-dired-cmd-pngnq-program
  ;; Prefer pngquant to pngnq-s9 as it is faster on my machine.
  ;;   The project also seems more active than the alternatives.
  ;; Prefer pngnq-s9 to pngnq as it fixes bugs in pngnq.
  ;; The pngnq project seems dead (?) since 2011 or so.
  (or (executable-find "pngquant")
      (executable-find "pngnq-s9")
      (executable-find "pngnq"))
  "The file name of the `pngquant' or `pngnq' program.
It quantizes colors of PNG images down to 256 colors or fewer
using the NeuQuant algorithm."
  :version "29.1"
  :type '(choice (const :tag "Not Set" nil) file))

(defcustom image-dired-cmd-pngnq-options
  (if (executable-find "pngquant")
      '("--ext" "-nq8.png" "%t") ; same extension as "pngnq"
    '("-f" "%t"))
  "Arguments to pass `image-dired-cmd-pngnq-program'.
Available format specifiers are the same as in
`image-dired-cmd-create-thumbnail-options'."
  :type '(repeat (string :tag "Argument"))
  :version "29.1")

(defcustom image-dired-cmd-pngcrush-program (executable-find "pngcrush")
  "The file name of the `pngcrush' program.
It optimizes the compression of PNG images.  Also it adds PNG textual chunks
with the information required by the Thumbnail Managing Standard."
  :type '(choice (const :tag "Not Set" nil) file))

(defcustom image-dired-cmd-pngcrush-options
  `("-q"
    "-text" "b" "Description" "Thumbnail of file://%f"
    "-text" "b" "Software" ,(emacs-version)
    ;; "-text b \"Thumb::Image::Height\" \"%oh\" "
    ;; "-text b \"Thumb::Image::Mimetype\" \"%mime\" "
    ;; "-text b \"Thumb::Image::Width\" \"%ow\" "
    "-text" "b" "Thumb::MTime" "%m"
    ;; "-text b \"Thumb::Size\" \"%b\" "
    "-text" "b" "Thumb::URI" "file://%f"
    "%q" "%t")
  "Arguments for `image-dired-cmd-pngcrush-program'.
Available format specifiers are the same as in
`image-dired-cmd-create-thumbnail-options', with %q for a
temporary file name (typically generated by pnqnq)."
  :version "26.1"
  :type '(repeat (string :tag "Argument")))

(defcustom image-dired-cmd-optipng-program (executable-find "optipng")
  "The file name of the `optipng' program."
  :version "26.1"
  :type '(choice (const :tag "Not Set" nil) file))

(defcustom image-dired-cmd-optipng-options '("-o5" "%t")
  "Arguments passed to `image-dired-cmd-optipng-program'.
Available format specifiers are described in
`image-dired-cmd-create-thumbnail-options'."
  :version "26.1"
  :type '(repeat (string :tag "Argument"))
  :link '(url-link "man:optipng(1)"))

(defcustom image-dired-cmd-create-standard-thumbnail-options
  (append '("-size" "%wx%h" "%f[0]")
          (unless (or image-dired-cmd-pngcrush-program
                      image-dired-cmd-pngnq-program)
            (list
             "-set" "Thumb::MTime" "%m"
             "-set" "Thumb::URI" "file://%f"
             "-set" "Description" "Thumbnail of file://%f"
             "-set" "Software" (emacs-version)))
          '("-thumbnail" "%wx%h>" "png:%t"))
  "Options for creating thumbnails according to the Thumbnail Managing Standard.
Available format specifiers are the same as in
`image-dired-cmd-create-thumbnail-options', with %m for file modification time."
  :version "26.1"
  :type '(repeat (string :tag "Argument")))

(defcustom image-dired-cmd-rotate-original-program "jpegtran"
  "Executable used to rotate original image.
Used together with `image-dired-cmd-rotate-original-options'."
  :type 'file)

(defcustom image-dired-cmd-rotate-original-options
  '("-rotate" "%d" "-copy" "all" "-outfile" "%t" "%o")
  "Arguments of command used to rotate original image.
Used with `image-dired-cmd-rotate-original-program'.
Available format specifiers are: %d which is replaced by the
number of (positive) degrees to rotate the image, normally 90 or
270 \(for 90 degrees right and left), %o which is replaced by the
original image file name and %t which is replaced by
`image-dired-temp-image-file'."
  :version "26.1"
  :type '(repeat (string :tag "Argument")))

(defcustom image-dired-temp-rotate-image-file
  (expand-file-name ".image-dired_rotate_temp"
                    (locate-user-emacs-file "image-dired/"))
  "Temporary file for rotate operations."
  :type 'file)

(defcustom image-dired-cmd-write-exif-data-program "exiftool"
  "Program used to write EXIF data to image.
Used together with `image-dired-cmd-write-exif-data-options'."
  :type 'file)

(defcustom image-dired-cmd-write-exif-data-options '("-%t=%v" "%f")
  "Arguments of command used to write EXIF data.
Used with `image-dired-cmd-write-exif-data-program'.
Available format specifiers are: %f which is replaced by
the image file name, %t which is replaced by the tag name and %v
which is replaced by the tag value."
  :version "26.1"
  :type '(repeat (string :tag "Argument")))


;;; Util functions

(defun image-dired--check-executable-exists (executable)
  (unless (executable-find (symbol-value executable))
    (error "Executable %S not found" executable)))


;;; Creating thumbnails

(defun image-dired-thumb-size (dimension)
  "Return thumb size depending on `image-dired-thumbnail-storage'.
DIMENSION should be either the symbol `width' or `height'."
  (cond
   ((eq 'standard image-dired-thumbnail-storage) 128)
   ((eq 'standard-large image-dired-thumbnail-storage) 256)
   ((eq 'standard-x-large image-dired-thumbnail-storage) 512)
   ((eq 'standard-xx-large image-dired-thumbnail-storage) 1024)
   (t (cl-ecase dimension
        (width image-dired-thumb-width)
        (height image-dired-thumb-height)))))

(defvar image-dired--generate-thumbs-start nil
  "Time when `display-thumbs' was called.")

(defvar image-dired-queue nil
  "List of items in the queue.
Each item has the form (ORIGINAL-FILE TARGET-FILE).")

(defvar image-dired-queue-active-jobs 0
  "Number of active jobs in `image-dired-queue'.")

(defvar image-dired-queue-active-limit (min 4 (max 2 (/ (num-processors) 2)))
  "Maximum number of concurrent jobs permitted for generating images.
Increase at own risk.  If you want to experiment with this,
consider setting `image-dired-debug' to a non-nil value to see
the time spent on generating thumbnails.  Run `image-clear-cache'
and remove the cached thumbnail files between each trial run.")

(defun image-dired-pngnq-thumb (spec)
  "Quantize thumbnail described by format SPEC with pngnq(1)."
  (let ((process
         (apply #'start-process "image-dired-pngnq" nil
                image-dired-cmd-pngnq-program
                (mapcar (lambda (arg) (format-spec arg spec))
                        image-dired-cmd-pngnq-options))))
    (setf (process-sentinel process)
          (lambda (process status)
            (if (and (eq (process-status process) 'exit)
                     (zerop (process-exit-status process)))
                ;; Pass off to pngcrush, or just rename the
                ;; THUMB-nq8.png file back to THUMB.png
                (if (and image-dired-cmd-pngcrush-program
                         (executable-find image-dired-cmd-pngcrush-program))
                    (image-dired-pngcrush-thumb spec)
                  (let ((nq8 (cdr (assq ?q spec)))
                        (thumb (cdr (assq ?t spec))))
                    (rename-file nq8 thumb t)))
              (message "command %S %s" (process-command process)
                       (string-replace "\n" "" status)))))
    process))

(defun image-dired-pngcrush-thumb (spec)
  "Optimize thumbnail described by format SPEC with pngcrush(1)."
  ;; If pngnq wasn't run, then the THUMB-nq8.png file does not exist.
  ;; pngcrush needs an infile and outfile, so we just copy THUMB to
  ;; THUMB-nq8.png and use the latter as a temp file.
  (when (not image-dired-cmd-pngnq-program)
    (let ((temp (cdr (assq ?q spec)))
          (thumb (cdr (assq ?t spec))))
      (copy-file thumb temp)))
  (let ((process
         (apply #'start-process "image-dired-pngcrush" nil
                image-dired-cmd-pngcrush-program
                (mapcar (lambda (arg) (format-spec arg spec))
                        image-dired-cmd-pngcrush-options))))
    (setf (process-sentinel process)
          (lambda (process status)
            (unless (and (eq (process-status process) 'exit)
                         (zerop (process-exit-status process)))
              (message "command %S %s" (process-command process)
                       (string-replace "\n" "" status)))
            (when (memq (process-status process) '(exit signal))
              (let ((temp (cdr (assq ?q spec))))
                (delete-file temp)))))
    process))

(defun image-dired-optipng-thumb (spec)
  "Optimize thumbnail described by format SPEC with optipng(1)."
  (let ((process
         (apply #'start-process "image-dired-optipng" nil
                image-dired-cmd-optipng-program
                (mapcar (lambda (arg) (format-spec arg spec))
                        image-dired-cmd-optipng-options))))
    (setf (process-sentinel process)
          (lambda (process status)
            (unless (and (eq (process-status process) 'exit)
                         (zerop (process-exit-status process)))
              (message "command %S %s" (process-command process)
                       (string-replace "\n" "" status)))))
    process))

(defun image-dired-create-thumb-1 (original-file thumbnail-file)
  "For ORIGINAL-FILE, create thumbnail image named THUMBNAIL-FILE."
  (image-dired--check-executable-exists
   'image-dired-cmd-create-thumbnail-program)
  (let* ((width (int-to-string (image-dired-thumb-size 'width)))
         (height (int-to-string (image-dired-thumb-size 'height)))
         (modif-time (format-time-string
                      "%s" (file-attribute-modification-time
                            (file-attributes original-file))))
         (thumbnail-nq8-file (replace-regexp-in-string ".png\\'" "-nq8.png"
                                                       thumbnail-file))
         (spec
          (list
           (cons ?w width)
           (cons ?h height)
           (cons ?m modif-time)
           (cons ?f original-file)
           (cons ?q thumbnail-nq8-file)
           (cons ?t thumbnail-file)))
         (thumbnail-dir (file-name-directory thumbnail-file))
         process)
    (when (not (file-exists-p thumbnail-dir))
      (with-file-modes #o700
        (make-directory thumbnail-dir t))
      (message "Thumbnail directory created: %s" thumbnail-dir))

    ;; Thumbnail file creation processes begin here and are marshaled
    ;; in a queue by `image-dired-create-thumb'.
    (setq process
          (apply #'start-process "image-dired-create-thumbnail" nil
                 image-dired-cmd-create-thumbnail-program
                 (mapcar
                  (lambda (arg) (format-spec arg spec))
                  (if (memq image-dired-thumbnail-storage
                            image-dired--thumbnail-standard-sizes)
                      image-dired-cmd-create-standard-thumbnail-options
                    image-dired-cmd-create-thumbnail-options))))

    (setf (process-sentinel process)
          (lambda (process status)
            ;; Trigger next in queue once a thumbnail has been created
            (cl-decf image-dired-queue-active-jobs)
            (image-dired-thumb-queue-run)
            (when (= image-dired-queue-active-jobs 0)
              (image-dired-debug-message
               (format-time-string
                "Generated thumbnails in %s.%3N seconds"
                (time-subtract nil
                               image-dired--generate-thumbs-start))))
            (if (not (and (eq (process-status process) 'exit)
                          (zerop (process-exit-status process))))
                (message "Thumb could not be created for %s: %s"
                         (abbreviate-file-name original-file)
                         (string-replace "\n" "" status))
              (set-file-modes thumbnail-file #o600)
              (clear-image-cache thumbnail-file)
              ;; PNG thumbnail has been created since we are
              ;; following the XDG thumbnail spec, so try to optimize
              (when (memq image-dired-thumbnail-storage
                          image-dired--thumbnail-standard-sizes)
                (cond
                 ((and image-dired-cmd-pngnq-program
                       (executable-find image-dired-cmd-pngnq-program))
                  (image-dired-pngnq-thumb spec))
                 ((and image-dired-cmd-pngcrush-program
                       (executable-find image-dired-cmd-pngcrush-program))
                  (image-dired-pngcrush-thumb spec))
                 ((and image-dired-cmd-optipng-program
                       (executable-find image-dired-cmd-optipng-program))
                  (image-dired-optipng-thumb spec)))))))
    process))

(defun image-dired-thumb-queue-run ()
  "Run a queued job if one exists and not too many jobs are running.
Queued items live in `image-dired-queue'."
  (while (and image-dired-queue
              (< image-dired-queue-active-jobs
                 image-dired-queue-active-limit))
    (cl-incf image-dired-queue-active-jobs)
    (apply #'image-dired-create-thumb-1 (pop image-dired-queue))))

(defun image-dired-create-thumb (original-file thumbnail-file)
  "Add a job for generating ORIGINAL-FILE thumbnail to `image-dired-queue'.
The new file will be named THUMBNAIL-FILE."
  (setq image-dired-queue
        (nconc image-dired-queue
               (list (list original-file thumbnail-file))))
  (run-at-time 0 nil #'image-dired-thumb-queue-run))

(defun image-dired-refresh-thumb ()
  "Force creation of new image for current thumbnail."
  (interactive nil image-dired-thumbnail-mode)
  (let* ((file (image-dired-original-file-name))
         (thumb (expand-file-name (image-dired-thumb-name file))))
    (clear-image-cache (expand-file-name thumb))
    (image-dired-create-thumb file thumb)))

(defun image-dired-rotate-original (degrees)
  "Rotate original image DEGREES degrees."
  (image-dired--check-executable-exists
   'image-dired-cmd-rotate-original-program)
  (if (not (image-dired-image-at-point-p))
      (message "No image at point")
    (let* ((file (image-dired-original-file-name))
           (spec
            (list
             (cons ?d degrees)
             (cons ?o (expand-file-name file))
             (cons ?t image-dired-temp-rotate-image-file))))
      (unless (eq 'jpeg (image-type file))
        (user-error "Only JPEG images can be rotated"))
      (if (not (= 0 (apply #'call-process image-dired-cmd-rotate-original-program
                           nil nil nil
                           (mapcar (lambda (arg) (format-spec arg spec))
                                   image-dired-cmd-rotate-original-options))))
          (error "Could not rotate image")
        (image-dired-display-image image-dired-temp-rotate-image-file)
        (if (or (and image-dired-rotate-original-ask-before-overwrite
                     (y-or-n-p
                      "Rotate to temp file OK.  Overwrite original image? "))
                (not image-dired-rotate-original-ask-before-overwrite))
            (progn
              (copy-file image-dired-temp-rotate-image-file file t)
              (image-dired-refresh-thumb))
          (image-dired-display-image file))))))


;;; EXIF support

(defun image-dired-get-exif-file-name (file)
  "Use the image's EXIF information to return a unique file name.
The file name should be unique as long as you do not take more than
one picture per second.  The original file name is suffixed at the end
for traceability.  The format of the returned file name is
YYYY_MM_DD_HH_MM_DD_ORIG_FILE_NAME.jpg.  Used from
`image-dired-copy-with-exif-file-name'."
  (let (data no-exif-data-found)
    (if (not (eq 'jpeg (image-type (expand-file-name file))))
        (setq no-exif-data-found t
              data (format-time-string
                    "%Y:%m:%d %H:%M:%S"
                    (file-attribute-modification-time
                     (file-attributes (expand-file-name file)))))
      (setq data (exif-field 'date-time (exif-parse-file
                                         (expand-file-name file)))))
    (while (string-match "[ :]" data)
      (setq data (replace-match "_" nil nil data)))
    (format "%s%s%s" data
            (if no-exif-data-found
                "_noexif_"
              "_")
            (file-name-nondirectory file))))

(defun image-dired-thumbnail-set-image-description ()
  "Set the ImageDescription EXIF tag for the original image.
If the image already has a value for this tag, it is used as the
default value at the prompt."
  (interactive nil image-dired-thumbnail-mode)
  (if (not (image-dired-image-at-point-p))
      (message "No thumbnail at point")
    (let* ((file (image-dired-original-file-name))
           (old-value (or (exif-field 'description (exif-parse-file file)) "")))
      (if (eq 0
              (image-dired-set-exif-data file "ImageDescription"
                                         (read-string "Value of ImageDescription: "
                                                      old-value)))
          (message "Successfully wrote ImageDescription tag")
        (error "Could not write ImageDescription tag")))))

(defun image-dired-set-exif-data (file tag-name tag-value)
  "In FILE, set EXIF tag TAG-NAME to value TAG-VALUE."
  (image-dired--check-executable-exists
   'image-dired-cmd-write-exif-data-program)
  (let ((spec
         (list
          (cons ?f (expand-file-name file))
          (cons ?t tag-name)
          (cons ?v tag-value))))
    (apply #'call-process image-dired-cmd-write-exif-data-program nil nil nil
           (mapcar (lambda (arg) (format-spec arg spec))
                   image-dired-cmd-write-exif-data-options))))

(provide 'image-dired-external)

;; Local Variables:
;; nameless-current-name: "image-dired"
;; End:

;;; image-dired-external.el ends here