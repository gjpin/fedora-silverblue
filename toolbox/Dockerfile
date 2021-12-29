FROM registry.fedoraproject.org/fedora-toolbox:35

# Install extra packages
RUN dnf update -y
COPY extra-packages /
RUN dnf -y install $(<extra-packages)
RUN rm /extra-packages

# Configure SSHD
RUN printf "Port 2222\nListenAddress localhost\nPermitEmptyPasswords yes\n" >> /etc/ssh/sshd_config \
	&& /usr/libexec/openssh/sshd-keygen rsa \
	&& /usr/libexec/openssh/sshd-keygen ecdsa \
	&& /usr/libexec/openssh/sshd-keygen ed25519