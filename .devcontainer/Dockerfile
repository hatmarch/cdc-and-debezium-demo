FROM quay.io/mhildenb/cloudnative-workspaces-quarkus:1.0

# NOTE: If you need to run yum to install anything, you'll need to register the RHEL container using docker BUILDKIT to pass secrets
# If this is not supported by VSCode Remote, then you'll need to create a new base image outside of vscode / .devcontainer and make that image
# the base container to this one
USER root

# install stern
RUN cd /usr/local/bin && \
    wget https://github.com/wercker/stern/releases/download/1.6.0/stern_linux_amd64 && \
    mv stern_linux_amd64 stern && chmod 755 stern && \
# instal knative client
    wget -qO- https://mirror.openshift.com/pub/openshift-v4/clients/serverless/latest/kn-linux-amd64-0.10.0.tar.gz | tar zxvf - -C /usr/local/bin && \
# instal hey
    wget https://storage.googleapis.com/hey-release/hey_linux_amd64 && \
    mv hey_linux_amd64 hey && chmod 755 hey && \
# install istioctl
    curl -L https://github.com/istio/istio/releases/download/1.4.0/istioctl-1.4.0-linux.tar.gz | tar -zxvf - -C /usr/local/bin && chmod 755 /usr/local/bin/istioctl

# install AWS cli
RUN curl "https://d1vvhvl2y92vvt.cloudfront.net/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && rm awscliv2.zip && rm -rf ./aws && ln -s /usr/local/bin/aws2 /usr/local/bin/aws

USER jboss