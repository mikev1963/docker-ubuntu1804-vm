FROM ubuntu:18.04
LABEL maintainer="Michael A. Ventarola"
ENV container docker

# Install dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       apt-utils \
       python-setuptools \
       openssh-server \
       python-pip \
       software-properties-common \
       rsyslog systemd systemd-cron sudo \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

COPY initctl_faker .
RUN chmod +x initctl_faker && rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

# SSH login fix. Otherwise user is kicked off after login
RUN mkdir /var/run/sshd
RUN echo "y" | ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config


# Remove unnecessary getty and udev targets that result in high CPU usage when using
# multiple containers with Molecule (https://github.com/ansible/molecule/issues/1104)
RUN rm -f /lib/systemd/system/systemd*udev* \
  && rm -f /lib/systemd/system/getty.target

EXPOSE 22
RUN systemctl enable ssh

# Install local users in container
COPY useradd.sh /
RUN chmod +x /useradd.sh && /useradd.sh

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
CMD ["/lib/systemd/systemd"]
