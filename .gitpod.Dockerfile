FROM gitpod/workspace-base

# Install Nix
USER root
RUN adduser gitpod \
  && mkdir -m 0755 /nix && chown gitpod /nix \
  && mkdir -p /etc/nix && echo 'sandbox = false' > /etc/nix/nix.conf

CMD /bin/bash -l
USER gitpod
ENV USER gitpod
WORKDIR /home/gitpod
RUN curl -L https://nixos.org/nix/install -o nix-install.sh
RUN sh ./nix-install.sh --no-daemon --yes

# enable nix-env
RUN echo '. /home/gitpod/.nix-profile/etc/profile.d/nix.sh' >> /home/gitpod/.bashrc

# Allow unfree packages
RUN mkdir -p /home/gitpod/.config/nixpkgs && echo '{ allowUnfree = true; }' >> /home/gitpod/.config/nixpkgs/config.nix

# Install cachix
RUN . /home/gitpod/.nix-profile/etc/profile.d/nix.sh \
    && nix-env -iA cachix -f https://cachix.org/api/v1/install \
    && cachix use cachix

# Install devenv
RUN . /home/gitpod/.nix-profile/etc/profile.d/nix.sh \
    && nix-env -i -f https://github.com/cachix/devenv/tarball/latest \
    && cachix use shopware

# Install git
RUN . /home/gitpod/.nix-profile/etc/profile.d/nix.sh \
    && nix-env -i git git-lfs