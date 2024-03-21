@@@@@@@@@@@@@@@@@@
Bash Aliases Hints
@@@@@@@@@@@@@@@@@@
.. Okay, just one.

Hint: There are lots of way to run the native command
      and not the alias, e.g., ::

        command rm

        \rm

        "rm"

        'rm'

        env rm

        /usr/bin/env rm

      will call the real ``/bin/rm`` and not the alias.

- Also: While I do like having aliases spread across multiple
        files, when I split what was one file into what's now
        32 files, it increased new session boot from .66 secs.
        to a little over 1 sec. #PROFILING

