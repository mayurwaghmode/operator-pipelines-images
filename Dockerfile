FROM registry.fedoraproject.org/fedora:34

LABEL description="Cli tools for operator certification pipeline"
LABEL summary="This image contains tools required for operator bundle certification pipeline."

ARG USER_UID=1000

USER root

# setup certificates
COPY certs/* /etc/pki/ca-trust/source/anchors/
RUN /usr/bin/update-ca-trust

# This is just a temporary workaround until we figure out how to
# override CA bundle in OCP
RUN cp /etc/pki/tls/certs/ca-bundle.crt /etc/pki/tls/certs/custom-ca-bundle.crt

ENV REQUESTS_CA_BUNDLE="/etc/pki/tls/certs/custom-ca-bundle.crt"

RUN dnf update -y && \
    dnf install -y \
    findutils \
    git \
    gcc \
    jq \
    krb5-devel \
    krb5-workstation \
    openssl-devel \
    pip \
    python3-devel && \
    dnf clean all

COPY config/krb5.conf /etc/krb5.conf

RUN curl -LO https://github.com/operator-framework/operator-sdk/releases/download/v1.8.1/operator-sdk_linux_amd64 && \
    chmod +x operator-sdk_linux_amd64 && \
    mv operator-sdk_linux_amd64 /usr/local/bin/operator-sdk

# Install opm CLI
RUN curl -LO https://github.com/operator-framework/operator-registry/releases/download/v1.17.5/linux-amd64-opm && \
    chmod +x linux-amd64-opm && \
    mv linux-amd64-opm /usr/local/bin/opm

RUN useradd -ms /bin/bash -u "${USER_UID}" user

WORKDIR /home/user

COPY . ./

RUN pip3 install .

# set dir ownership
RUN chgrp -R 0 /home/user /etc/passwd
RUN chmod -R g=u /home/user /etc/passwd

USER "${USER_UID}"
