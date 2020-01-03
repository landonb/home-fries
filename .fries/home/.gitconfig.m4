# vim:tw=0:ts=2:sw=2:et:norl:

# BEG PERSONALIZABLE

[user]
  name = YOUR_FULL_NAME_HERE()
  email = YOUR_GITHUB_USERNAME()@users.noreply.github.com

# END PERSONALIZABLE

[alias]

  ad = add -p

  ci = commit
  # git commit -a/--all        stage modified and deleted, but not new
  # git commit -v/--verbose    show diff of being committed at bottom of commit message...
  #cia = commit -a -v
  ci- = commit -m

  #undoci = reset --soft HEAD~1
  undo = reset --soft @~1

  st = status

  #br = branch
  br = branch -avv

  co = checkout

  # Hmmm.
  #or = remote -v
  re = remote -v

  # 2017-05-19 18:00: Took ya long enough!
  ls = ls-files

  #up = pull origin
  # From http://haacked.com/archive/2014/07/28/github-flow-aliases/
  #up = !git pull --rebase --prune $@ && git submodule update --init --recursive
  # From digikam-4.13.0/README
  #up = pull --rebase -v --stat
  # 2016-10-09: sync_stick's been rolling rebase and autostash, and I like.
  #   2016-09-28: I think I found a better 'git pull'/'git up'
  #   http://gitready.com/advanced/2009/02/11/pull-with-rebase.html
  #   http://aanandprasad.com/git-up/
  #  Git 2.9 or later:
  up = pull --rebase --autostash

  #last = log -1 HEAD
  last = !git --no-pager log -1 HEAD

  yank = reset --soft HEAD~1

  #unstage = reset HEAD --
  unstage = reset HEAD

  # git log options:
  #   %Cred     red text
  #   %C(cyan)  Choose from: (normal, black, red, green, yellow, blue, magenta, cyan and white)
  #   %h        abbreviated commit hash
  #   %Creset   reset text color
  #   %x0       print a byte from hex code (09: \t)
  #   %an       author name
  #   %x09      TAB
  #   %ad       author date (format respects --date= option)
  #   %x09      TAB
  #   %d        ref names, like the --decorate option of git-log(1)
  #   %s        subject
  #   %<(<N>[,trunc|ltrunc|mtrunc]) make the next placeholder take at least N columns...
  #     * 79c812f My Name  Fri Mar 1q0 17:05:27 2017  Update README.
  #     * 2deef48 My Name  Thu Mar 9 13:02:57 2017 Fix something.
  #     %<(24) is 24 chars for the "Fri Mar 10 17:05:27 2017" date. %>(24) to right justify.
  #   If you add a ` ` (space) after % of a placeholder, a space is inserted immediately
  #   before the expansion if and only if the placeholder expands to a non-empty string.
  log1 = log --graph --decorate --abbrev-commit --date=local \
    --pretty="%C(yellow)%h%x09%C(cyan)%<(12)%an%x09%C(blue)%>(24)%ad%C(auto)%x09%D%s"
    # Interesting: %+s will linefeed between meta and subject.
    # Also, %C(auto) will use colors like git log normally does
    #   (which it does because color.ui=always).
    #   --pretty="%C(auto)%h%x09%<(12)%an%x09%>(24)%ad%x09%d%s"
    # NOTE: I cannot get a space between the %D ref name and the %s subject, oh well.
  # 2016-11-19 This one's useful.
  #  https://www.leaseweb.com/labs/2013/08/git-tip-beautiful-colored-and-readable-output/
  lg = log --graph --abbrev-commit --date=relative \
    --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'

  # 2016-11-21: Should this be a thing?:
  pom = push origin master

  di = diff
  #df = diff
  dd = !git --no-pager diff $@

  #sta = stash

  # Git command to show tag creation dates.
  # ALA CARTE: Add --graph to see branching lines. Not super helpful.
  tags = log --date-order --tags --simplify-by-decoration --pretty='format:%C(green)%ad %C(red)%h %C(reset)%D' --date=short

  # 2017-06-06: About tizzle!
  sup = submodule update --init --remote

[color]
  #status = auto
  # Use always so piping pipes colors, e.g., git log --stat | less.
  #ui = auto
  ui = always
[core]
  # Thoughts on using `most` not `less` for the pager:
  #   Using `most` looks like using `less`, except the switch,
  #   +s +'/---', advances `most` to the first change in the diff
  #   (effectively just skipping the first two lines of the diff...),
  #   and `most` doesn't map Vim keys like `less` does... so I guess
  #   most isn't quite more than less so much as it is just neither
  #   less nor more.
  #     pager = most +s +'/---'
  # Here's how you'd do this from the command line:
  #     git config --global core.pager "less -R"
  #   Configure `git diff|log|mergetool` to use less to display text. With -R,
  #   less interprets ANSI color codes, otherwise they're raw, e.g., [ESCapes234.
  # See also: bash's export EDITOR= command.
  pager = less -R

  # Thoughts on whitespace:
  #   I like a blank line at the end of every file so that when I
  #   jump the cursor to the end of a file, it then rests at the first
  #   column of a new line rather than at the last column of some line
  #   of characters. But git complains when you add files that have a
  #   trailing new line. So tell git not to worry or bark at you.
  #     https://stackoverflow.com/questions/27059239/git-new-blank-line-at-eof
  #whitespace = cr-at-eol
  whitespace = -blank-at-eof

[color]
  # We enable color one by one,
  #   branch = auto
  #   diff = auto
  #   status = auto
  #   interactive = auto
  # Or we could just do 'em all.
  # NOTE: Use `always` so piping pipes colors, e.g., git log --stat | less.
  # CAVEAT: You'll want to `git -c color.ui=off` if parsing output,
  #   otherwise the color codes will break your string comparisons.
  #ui = auto
  ui = always
[color "branch"]
  current = green bold
  local = green
  remote = red bold
  #current = yellow reverse
  #local = yellow
  #remote = green
[color "diff"]
  meta = yellow bold
  frag = magenta bold
  old = red bold
  new = green bold
  #meta = yellow bold
  #frag = magenta bold
  #old = red bold
  #new = green bold
[color "status"]
  added = green bold
  changed = yellow bold
  untracked = red
  #added = yellow
  #changed = green
  #untracked = cyan
# EXPLAIN: What command is 'sh'? Is it `git show`?
[color "sh"]
  branch = yellow

[merge]
  # Choose which merge tool to use by default.
  #tool = meld
  #tool = vimdiff
  #tool = diffconflicts
  tool = meld
[mergetool]
  # `git mergetool` makes intermediate *.orig files but
  # doesn't delete them unless we tell it to delete them.
  keepBackup = false

# 2016-11-19: I find `git diff` adequate, and I rarely merge in git,
# and I couldn't get githexdiff to work (was it ever called?), so
# this section can be deleted. Keeping for posterity for now.
#
#  #[diff]
#  #  # Choose which diff tool to use by default.
#  #  diff = meld
#  # See .gitattributes file:
#  #  you'll need, e.g.: *.so diff=hexdiff
#  # NOTE: The .gitattributes file only works for [lb]
#  #       if it's in the project folder and not in ~/.
#  # See: man 5 gitattributes
#  # For list of tools:
#  #   git difftool --tool-help
#  # 2016-11-19: I can only get `git difftool --tool=diffconflicts` to work
#  #                     Trying `git difftool --tool=hexdiff` says no no no.
#  [diff "hexdiff"]
#    #textconv = hexdump -v -C
#    #command = hexdump -v -C
#    #command = "echo -- "
#    # See ~/.dubs/bin/githexdiff
#    command = githexdiff
#  [diff "melddiff"]
#    # To access:
#    #  git difftool
#    # See ~/.dubs/bin/gitmelddiff
#    command = gitmelddiff
#  [mergetool "diffconflicts"]
#    cmd = diffconflicts vim "$BASE" "$LOCAL" "$REMOTE" "$MERGED"
#    trustExitCode = true

