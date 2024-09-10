(require 'url)
(require 'info)

(defvar info-downloader-default-url '("https://ayatakesi.github.io/emacs/29.4/emacs-ja.info"
                                      "https://ayatakesi.github.io/lispref/29.4/elisp-ja.info")
  "デフォルトのInfo fileダウンロードURL")

(defvar info-downloader-avarable-version '(29.4 29.3 29.2 29.1
                                           28.2 28.1
                                           27.2 27.1
                                           26.3 26.2 26.1))

(defvar info-downloader-install-dir (expand-file-name "~/.emacs.d/info/")
  "ダウンロードしたInfo fileをインストールするディレクトリ")

(defun info-downloader-install (&optional urls)
  "Infoファイルをダウンロードしてインストールします。
URLSが指定されていない場合は、`info-downloader-default-url'を使用します。"
  (interactive)
  (let ((urls (or urls info-downloader-default-url)))
    (unless (file-exists-p info-downloader-install-dir)
      (make-directory info-downloader-install-dir t))
    (dolist (url urls)
      (let* ((filename (string-replace "-ja" "" (file-name-nondirectory url)))
             (install-path (expand-file-name filename info-downloader-install-dir)))
        (url-copy-file url install-path t)
        (when (string-match "\\.gz$" filename)
          (call-process "gunzip" nil nil nil install-path)
          (setq install-path (replace-regexp-in-string "\\.gz$" "" install-path)))
        (message "Infoファイルがインストールされました: %s" install-path)))
    (info-downloader-generate-dir-file)
    (message "すべてのInfoファイルがインストールされ、dirファイルが生成されました。")))

(defun info-downloader-generate-dir-file ()
  (interactive)
  "info-downloader-install-dir内のすべてのinfoファイルからdirファイルを生成します。"
  (let ((dir-file (expand-file-name "dir" info-downloader-install-dir))
        (info-files (directory-files info-downloader-install-dir t "\\.info$")))
    (with-temp-file dir-file
      (insert "This is the file .../info/dir, which contains the\n")
      (insert "topmost node of the Info hierarchy, called (dir)Top.\n")
      (insert "The first time you invoke Info you start off looking at this node.\n")
      (insert ?)
      (insert "\nFile: dir,	Node: Top	This is the top of the INFO tree\n")
      (insert "* Menu:\n\n")
      (dolist (file info-files)
        (insert (with-temp-buffer
                  (insert-file-contents file)
                  (goto-char (point-min))
                  (when (re-search-forward "^START-INFO-DIR-ENTRY$" nil t)
                    (let ((start (point)))
                      (when (re-search-forward "^END-INFO-DIR-ENTRY$" nil t)
                        (beginning-of-line)
                        (buffer-substring start (point)))))))))))

;; パッケージがロードされたときにInfo-directory-listを更新
;; (add-to-list 'Info-directory-list info-downloader-install-dir)
(add-hook 'elpaca-after-init-hook
          (lambda ()
            (add-to-list 'Info-directory-list
                         info-downloader-install-dir)))

(provide 'info-downloader)
