
# sshcli-with-passphrase

Docker image based on efrecon/mini-tcl; adds openssh-client to enable the use of
non-empty passphrase SSH keys. The idea is to use "/usr/bin/expect" to interact
with "ssh-agent" so that a script can receive the private ssh key and a passphrase,
and load the key into the ssh-agent. After that, using commands like ssh or scp
should not prompt for the passphrase.

I built this image in order to publish static HTML sites through SSH, since
some hosting providers do not have a more modern way to interact with it.

## Usage

To use this image, one could build a script like this:

```bash
#!/bin/bash

# Parameters:
#  $1: The private SSH Key
#  $2: The private SSH Key passphrase
#  $3: The local file to copy
#  $4: The remote user
#  $5: The remote server
#  $6: The remote path for the file destination
#  $7: The known_host server id

# Working directory
WORK_DIR=`dirname $0`

# Write the private key
echo "$1" > $WORK_DIR/private.key
chmod 600 $WORK_DIR/private.key

# Write the known_host file
mkdir -p ~/.ssh
echo "$7" >> ~/.ssh/known_hosts

# Start SSH Agent
eval $(ssh-agent -s)

/usr/bin/expect <<EOF
spawn /usr/bin/ssh-add $WORK_DIR/private.key
expect "Enter passphrase for $WORK_DIR/private.key:"
send "$2\n";
expect "Identity added: $WORK_DIR/private.key ($WORK_DIR/private.key)"
interact
EOF

scp "$3" $4@$5:$6

# Kill the agent, we don't want private keys unnatended
ssh-agent -k
rm -f $WORK_DIR/private.key
```

The basic steps are:

 1. All the information comes from the command line
 2. The key and passphrase are the first two Parameters
 3. To avoid any prompts, we add the known_host ID
 4. We use `expect` to interact with `ssh-add`
 5. After the `ssh-agent` has the private key loaded, we use the ssh commands
 6. At the end we delete the private key, and kill the agent

Let's say we name this script `scp-with-private-key.sh`, then we can run Docker
like this:

```bash
$ docker run -v `pwd`:`pwd` --rm patotech/sshcli-with-passphrase      \
         `pwd`/scp-with-private-key.sh "$SSH_KEY" "$SSH_KEY_PHRASE"   \
                                       "$LOCAL_FILE_PATH" "$SSH_USER" \
                                       "$SSH_HOST" "$SSH_REMOTE_DIR"  \
                                       "$SSH_KNOWN_HOST"
```

Some things to have in mind when building your own script:

 1. Make sure to kill the agent; any root user could get access to the process
    and the keys in it if the process is not terminated
 2. It would be best to clone the repo and use your own private one; this is
    only an example.
 3. Another option is to load the key into ssh-agent with a time limit

## References

Some links and references that could be usefull:

 * [I based this image on this project](https://github.com/efrecon/mini-tcl)
 * [Usefull StackOverflow Link](https://stackoverflow.com/questions/4780893/use-expect-in-bash-script-to-provide-password-to-ssh-command)
 * [Reference for `expect`](https://gist.github.com/Fluidbyte/6294378)
