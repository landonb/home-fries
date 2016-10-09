#####
Curly
#####

``Curly`` is a recipe for you making a private dotfiles overlay.

``Curly`` is designed to work with
`Home-fries
<https://github.com/landonb/home-fries>`__,
but it can work on its own, too,
or with your dotfile system.

Usefulness
==========

``Curly`` is useful for storing secure files, user-specific files,
and machine-specific things in a repository that you do not want
to publish publicly.

This might include ``~/.ssh/`` keys, ``~/.gitconfig``, etc.

``curly`` helps manage these files, for instance, by making
symlinks from ``~/.ssh`` to the private keys you've stored in
the repo.

``curly`` also helps you stay productive on multiple machines by making
it easy to keep each machine in sync. You can use a USB drive or
cloud storage location to maintain git clones in an encrypted
``encfs`` mount that makes it quick and painless to keep multiple
development machines current.

Usage
=====

Clone this project to ``~/.curly`` or whatever you'd like to
call it and read/run its ``./setup.sh``.

``curly`` will set up a new, private repo for you will symlinks
into ``~/.curly`` (or wherever) so you can add to the new repo
but also stay current with changes in ``curly``.

Obviously, you'll need to edit files and add your own private
dotfiles and whatnot to make this project useful to you.

