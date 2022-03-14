FROM gitlab/gitlab-ce:11.4.7-ce.0
MAINTAINER Mondoo Inc. <hello@mondoo.com>


# Install required packages
RUN apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
      policykit-1 \
      libc6-dev \
      gcc \
      curl \
      netcat \
    && rm -rf /var/lib/apt/lists/*

# Allow to access embedded tools
ENV PATH /opt/gitlab/embedded/bin:/opt/gitlab/bin:/assets:$PATH

# Resolve error: TERM environment variable not set.
ENV TERM xterm

# Expose web & ssh
EXPOSE 443 80 22

# Define data volumes
# VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

# Wrapper to handle signal, trigger runit and reconfigure GitLab
CMD ["/assets/wrapper"]

HEALTHCHECK --interval=60s --timeout=30s --retries=5 \
CMD /opt/gitlab/bin/gitlab-healthcheck --fail --max-time 10