FROM ubuntu:20.04
LABEL name=netdevops
LABEL version=0.2.0
LABEL maintainer="m.klose@route4all.com"

RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install \
  apt-transport-https \
  build-essential \
  curl \
  dnsutils \
  git \
  iproute2 \
  iputils-ping \
  jq \
  less \
  lsb-release \
  nano \
  net-tools \
  nmap \
  python3 \
  python3-dev \
  python3-venv \
  software-properties-common \
  tcpdump \
  tmux \
  traceroute \
  unzip \
  vim \
  wget

# Powershell Core & Az Modules
RUN \
  wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb && \
  dpkg -i packages-microsoft-prod.deb && \
  apt-get update && \
  add-apt-repository universe && \
  apt-get install -y powershell && \
  pwsh -Command Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted && \
  pwsh -Command "Set-Variable -Name 'ProgressPreference' -Value 'SilentlyContinue' && Install-Module -Name Az -AllowClobber" && \
  rm packages-microsoft-prod.deb

# Terraform
RUN \
  TF_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M ".current_version") && \
  wget -nv -O terraform.zip https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
  unzip terraform.zip && \
  mv terraform /usr/local/bin && \
  rm terraform.zip

# AWS CLI
RUN \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip -q awscliv2.zip && \
  ./aws/install && \
  rm aws* -rf

# Azure CLI
RUN \
  curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null && \
  AZ_REPO=$(lsb_release -cs) && \
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

RUN apt-get update && apt-get -y install \
  azure-cli

# Clean UP
RUN \
  rm -rf /var/lib/apt/lists/* && \
  apt-get clean

COPY root/* /root/
# Create Python VENV and activate it
RUN \
  python3 -m venv /root/venv && \
  . /root/venv/bin/activate && \
  pip3 install --no-cache-dir -r /root/requirements-buildenv.txt && \ 
  pip3 install --no-cache-dir -r /root/requirements.txt

# Adjust .bashrc
RUN \
  echo "source /root/venv/bin/activate" >> /root/.bashrc && \
  echo "export PYTHONIOENCODING=utf-8" >> /root/.bashrc

# Install Ansible Collections
RUN \
  . /root/venv/bin/activate && \
  ansible-galaxy collection install -r /root/requirements.yml
