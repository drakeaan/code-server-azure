#!/bin/bash

# Allow user to aupply a start dir, default to /home/coder/project
START_DIR=${1:-/home/coder/project}
DIR_DATE=$(date +%F)

if [ -d "/src" ]
then
    START_DIR=${1:-/src/${DIR_DATE}}
fi

# Clone the git repo, if was supplied
if [ -z "${GIT_REPO}"  ]; then
    echo "\$GIT_REPO not specified"
else
    if [ -z ${GIT_CREDENTIALS} ]; then
        echo "\$GIT_CREDENTIALS not specified. Repo must be public."
        git clone $GIT_REPO $START_DIR;
    else
        # Clone an Azure DevOps private repo using the Generate Git Credentials option
        # Format of GIT_CREDENTIALS should be username:password generated by Azure DevOps
        echo "Cloning private repo"
        repoString=$GIT_REPO
        credentialString="@"
        REMOTE_URL="https://${GIT_CREDENTIALS}${repoString/https:\/\//$credentialString}"
        git clone $REMOTE_URL $START_DIR;

        sleep 10

        if [ -d "/src" ]
        then
            git config --global --add safe.directory /$START_DIR
        fi
    fi
fi

if [ "$DISABLE_SSH" != "true" ]; then
    # Start OpenSSH
    echo "Starting OpenSSH..."
    /usr/sbin/sshd &
fi

# Check if we should use --link (do not use link if $PASSWORD is supplied)
if [[ -z "${PASSWORD}" ]]; then
    # Run code-server with the default entrypoint and --link
    echo "\$PASSWORD not specified. Starting code-server --link..."
    /usr/bin/entrypoint.sh --link ${LINK_NAME:-azure} $START_DIR 2>&1 | tee code-server-logs.txt &
    # Run a mini redirect server on port 80 to take the user to the --link URL (keeps Azure alive)
    sleep 5 && /home/coder/miniRedirectServer.py 80 2>&1 | tee redirect-logs.txt
else
    echo "Running code-server on :80 with \$PASSWORD..."
    # Run code-server on port 80
    /usr/bin/entrypoint.sh --bind-addr 0.0.0.0:80 $START_DIR 2>&1 | tee code-server-logs.txt
fi

echo "Installing VS Code extensions"
code-server --install-extension hashicorp.terraform
code-server --install-extension esbenp.prettier-vscode
code-server --install-extension redhat.vscode-yaml
code-server --install-extension ms-python.python
code-server --install-extension lizebang.bash-extension-pack
code-server --install-extension ms-vscode.powershell
code-server --install-extension salesforce.salesforcedx-vscode
code-server --install-extension financialforce.lana

if [ -d "/src" ]
then
    echo "setting safe directory"
    git config --global --add safe.directory /$START_DIR
fi

echo "Removing remote url"
# Delete origin credentials
git remote rm origin