FROM ghcr.io/zombiezen/codespaces-nix

# Install Nix
CMD /bin/bash -l
USER vscode
ENV USER vscode
WORKDIR /home/vscode
#CMD /bin/bash -l
#WORKDIR /home/vscode
#RUN curl -L https://nixos.org/nix/install -o nix-install.sh
##RUN sh ./nix-install.sh --no-daemon --yes

# enable nix-env
#RUN echo '. /home/vscode/.nix-profile/etc/profile.d/nix.sh' >> /home/vscode/.bashrc

# Allow unfree packages
RUN mkdir -p /home/vscode/.config/nixpkgs && echo '{ allowUnfree = true; }' >> /home/vscode/.config/nixpkgs/config.nix

# Install cachix
RUN nix-env -iA cachix -f https://cachix.org/api/v1/install && cachix use cachix

# Install devenv
RUN nix-env -i -f https://github.com/cachix/devenv/tarball/latest && cachix use shopware

# Install git
RUN nix-env -i git git-lfs