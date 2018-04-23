# sshcli-with-passphrase

Docker image based on efrecon/mini-tcl; adds openssh-client to enable the use of
non-empty passphrase SSH keys. The idea is to use "/usr/bin/expect" to interact
with "ssh-agent" so that a script can receive the private ssh key and a passphrase,
and load the key into the ssh-agent. After that, using commands like ssh or scp
should not prompt for the passphrase.

I built this image in order to publish static HTML sites through SSH, since
some hosting providers do not have a more modern way to interact with it.
