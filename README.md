# choppsv1 Emacsmacport

## What is it.

tl;dr -- Native OSX notifications (i.e., your notification center).

The notification support is added to code forked from YAMAMOTO Mitsuharu's Mac
port (the one got from railwaycat homebrew formula). I add native notification
support to it.

When one does `(require 'mac-notifications)` the notification support is loaded.
Additionally the standard `notifications-notify` is redirected to these native
notifications. This means packages such as `org-notify` and `mu4e-alert` will
Just Work.

Org, mu4e and erc users, Enjoy.

## How do I install these formulae?

`brew install choppsv1/emacsmacport/emacs-mac`

Or `brew tap choppsv1/emacsmacport` and then `brew install emacs-mac`.

## Documentation

Apropos "mac-notifications" to see the various functions one can use if one
wishes more fine-grained control of notificaitons that notifications-notify
supplies.

## Brew help..

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
