FROM codercom/code-server:latest

USER coder

# Apply VS Code settings
COPY settings.json /root/.local/share/code-server/User/settings.json
COPY InstallAz.ps1 /root/.local/InstallAz.ps1

# Use our custom entrypoint script and our python server
COPY azure-entrypoint.sh /usr/bin/azure-entrypoint.sh
COPY miniRedirectServer.py /home/coder/miniRedirectServer.py

# Use bash shell
ENV SHELL=/bin/bash

# Ensure it runs on port 80
ENV PORT=80

USER root

# Add support for SSHing into the app (https://docs.microsoft.com/en-us/azure/app-service/configure-custom-container?pivots=container-linux#enable-ssh)
RUN sudo apt-get update && apt-get install wget && apt-get install -y openssh-server \
     && chown -R root:root /root \
     && echo "root:Docker!" | chpasswd \
     && chown -R root:root /temp \
     && chown -R coder:coder /home/coder \
     && chown -R root:root /root

# Install Azure CLI and Powershell Core
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb \
     && sudo dpkg -i packages-microsoft-prod.deb \
     && sudo apt-get update \
     && sudo apt-get install -y powershell
     
RUN sudo apt-get install -y nodejs
RUN sudo apt-get install -y npm

# Install Google Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
     && sudo apt-get install -y ./google-chrome-stable_current_amd64.deb

# Install Salesforce CLI
RUN npm install sfdx-cli --global

# If we ever want to install Azure Powershell cmdlets.
# RUN pwsh /root/.local/InstallAz.ps1

COPY sshd_config /etc/ssh/
EXPOSE 80 2222

# Fix SSH bug
RUN mkdir -p /var/run/sshd
RUN mkdir /home/coder/project

ENTRYPOINT ["/usr/bin/azure-entrypoint.sh"]