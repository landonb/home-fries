
# FIXME: This should be in recipe/, I wonder...

clone_repos () {
	cd ${HOME}/.vim/bundle_

	git clone git@github.com:landonb/dubs_after_dark.git
	git clone git@github.com:landonb/dubs_appearance.git
	git clone git@github.com:landonb/dubs_buffer_fun.git
	git clone git@github.com:landonb/dubs_edit_juice.git
	git clone git@github.com:landonb/dubs_file_finder.git
	git clone git@github.com:landonb/dubs_ftype_mess.git
	git clone git@github.com:landonb/dubs_grep_steady.git
	git clone git@github.com:landonb/dubs_html_entities.git
	git clone git@github.com:landonb/dubs_mescaline.git
	git clone git@github.com:landonb/dubs_project_tray.git
	git clone git@github.com:landonb/dubs_quickfix_wrap.git
	git clone git@github.com:landonb/dubs_rest_fold.git
	git clone git@github.com:landonb/dubs_style_guard.git
	git clone git@github.com:landonb/dubs_syntastic_wrap.git
	git clone git@github.com:landonb/dubs_toggle_textwrap.git
	git clone git@github.com:landonb/dubs_web_hatch.git
	git clone git@github.com:landonb/vim-markdown.git

}

clone_repos
