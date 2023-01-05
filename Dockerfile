FROM risca/yocto:ubuntu-12.04

# pre-install packages also installed by ${GLSDK}/setup.sh
USER root
RUN apt-get update && apt-get install -y \
      net-tools \
      expect \
      xinetd \
      tftpd \
      nfs-kernel-server \
      minicom \
      build-essential \
      libncurses5-dev \
      uboot-mkimage \
      autoconf \
      automake \
      python \
      git \
      diffstat \
      texinfo \
      gawk \
      chrpath \
      subversion \
      dos2unix \
      m2crypto \
      ia32-libs

USER yoctouser

ARG GLSDK_REL=omap5-uevm_6_03_00_01
ARG GLSDK_BIN=ti-glsdk_${GLSDK_REL}_linux-x64-installer.bin
ENV GLSDK=/home/yoctouser/${GLSDK_REL}

# make sure git name and email is configured
COPY --chown=yoctouser gitconfig ".gitconfig"

COPY ${GLSDK_BIN} /tmp/
RUN /tmp/${GLSDK_BIN} --mode unattended --unattendedmodeui none --prefix "${GLSDK}"

# Apply patches to make bootstrap work
COPY *.patch /tmp/
RUN cd ${GLSDK} \
      && patch -p1 < /tmp/0001-Fix-repo-version-to-v2.6.patch \
      && patch -p1 < /tmp/0002-Remove-yocto-setup-patches.patch \
      && sed -i \
           -e 's#git://git\.ti\.com/glsdk/release-manifest\.git#https://github.com/Risca/glsdk-release-manifest.git#' \
           "${GLSDK}/bin/setup-repo.sh" \
      && sed -i \
           -e 's#git://arago-project\.org/git/projects/oe-layersetup\.git#https://github.com/Risca/glsdk-oe-layersetup.git#' \
           "${GLSDK}/bin/setup-yocto.sh"

# Perform initial setup. This won't install the ducati build tools,
# nor will it fetch sources.
COPY setup.sh.exp "${GLSDK}"
RUN cd "${GLSDK}" && expect setup.sh.exp

ENV PATH=${GLSDK}/bin:/home/yoctouser/gcc-linaro-arm-linux-gnueabihf-4.7-2013.03-20130313_linux/bin:$PATH

# Finally fetch sources. Need to wrap the call in expect to get any progress.
# git will suppress output if tty is missing.
COPY fake_tty.exp "${GLSDK}/"
RUN cd "${GLSDK}" && expect fake_tty.exp ./bin/fetch-sources.sh
RUN cd "${GLSDK}" && ./bin/setup-yocto.sh
RUN mkdir -p "${GLSDK}/yocto-layers/downloads"

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
WORKDIR ${GLSDK}
CMD /bin/bash

COPY compile-git-with-openssl.sh /tmp/
RUN /tmp/compile-git-with-openssl.sh --skip-tests

# TODO:
# * remove leftovers
# * reorganize statements 
# * trim size
