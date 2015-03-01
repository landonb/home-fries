[user]
	name = YOUR_FULL_NAME_HERE()
	email = YOUR_GITHUB_USERNAME()@users.noreply.github.com
[alias]
  up = pull origin
  st = status
  di = diff
  co = checkout
  ci = commit
  br = branch
  sta = stash
[color]
	status = auto
[core]
  # Using `most` looks like using `less`, except the switch,
  # +s +'/---', advances most to the first change in the diff
  # (effectively just skipping the first two lines of the diff...),
  # and `most` doesn't map Vim keys like `less` does... so I guess
  # most isn't quite more than less so much as it is just neither
  # less nor more.
  #   pager = most +s +'/---'
  pager = less -R
[merge]
  tool = meld
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

