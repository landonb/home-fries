# BEGIN PERSONALIZABLE
[user]
	name = YOUR_FULL_NAME_HERE()
	email = YOUR_GITHUB_USERNAME()@users.noreply.github.com
# ENDIN PERSONALIZABLE
[alias]
  up = pull origin
  st = status
  di = diff
  #df = diff
  dd = !git --no-pager diff $@
  co = checkout
  ci = commit
  br = branch
  sta = stash
  # Some other ideas I found online...
  #unstage = reset HEAD --
  #last = log -1 HEAD
  # From http://haacked.com/archive/2014/07/28/github-flow-aliases/
  #up = !git pull --rebase --prune $@ && git submodule update --init --recursive
  # From digikam-4.13.0/README
  #up = pull --rebase -v --stat
  # git commit -a/--all        stage modified and deleted, but not new
  # git commit -v/--verbose    show diff of being committed at bottom of commit message...
  #ci = commit -a -v
  # FIXME: Add aliases/shortcuts for common things you do, like undoing last commit.
  undoci = reset --soft HEAD~1
[color]
  #status = auto
  # Use always so piping pipes colors, e.g., git log --stat | less.
  #ui = auto
  ui = always
[core]
  # Using `most` looks like using `less`, except the switch,
  # +s +'/---', advances most to the first change in the diff
  # (effectively just skipping the first two lines of the diff...),
  # and `most` doesn't map Vim keys like `less` does... so I guess
  # most isn't quite more than less so much as it is just neither
  # less nor more.
  #   pager = most +s +'/---'
  pager = less -R
  # I like a blank line at the end of every file so that when I
  # jump the cursor to the end of a file, it then rests at the first
  # column of a new line rather than at the last column of some line
  # of characters. But git complains when you add files that have a
  # trailing new line. So tell git not to worry or bark at you.
  # https://stackoverflow.com/questions/27059239/git-new-blank-line-at-eof
# FIXME: Make sure you're not disabling all whitespace checks...
  whitespace = -blank-at-eof
[merge]
  #tool = meld
  #tool = vimdiff
  tool = diffconflicts
[mergetool]
	keepBackup = false
# See .gitattributes file:
#  you'll need, e.g.: *.so diff=hexdiff
# NOTE: The .gitattributes file only works for [lb]
#       if it's in the project folder and not in ~/.
# See: man 5 gitattributes
[diff "hexdiff"]
  #textconv = hexdump -v -C
  #command = hexdump -v -C
  #command = "echo -- "
  # See ~/.dubs/bin/githexdiff
  command = githexdiff
[diff "melddiff"]
  # See ~/.dubs/bin/gitmelddiff
  command = gitmelddiff
[mergetool "diffconflicts"]
  cmd = diffconflicts vim $BASE $LOCAL $REMOTE $MERGED
  trustExitCode = true

#[push]
#  default = simple

# From digikam-4.13.0/README
#
#[core]
#  editor = mcedit
#[push]
#  default = tracking
#[color]
#  # turn on color
#  diff = auto
#  status = auto
#  branch = auto
#  interactive = auto
#  ui = auto
[color "branch"]
  current = green bold
  local = green
  remote = red bold
[color "diff"]
  meta = yellow bold
  frag = magenta bold
  old = red bold
  new = green bold
[color "status"]
  added = green bold
  changed = yellow bold
  untracked = red
# EXPLAIN: What command is 'sh'? Is it `git show`?
[color "sh"]
  branch = yellow

