FROM ubuntu:22.04

# user definition
ARG UID=1000
ARG GID=1000

# gcc version
ARG GCC_VER="12"

# llvm/clang version
ARG LLVM_VER="16"

# cmake version
ARG CMAKE_VERSION="3.26.3"

# ninja version
ARG NINJA_VERSION="1.11.1"

# conan version
ARG CONAN_VER="2.0.4"

# default compilers
ARG DEFAULT_CPP_COMPILER="clang++"
ARG DEFAULT_C_COMPILER="clang"

# Install necessary packages available from standard repos
RUN apt-get update -qq && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
        software-properties-common wget apt-utils file zip \
        openssh-client gpg-agent socat rsync \
        make git unzip

################################ GCC ##################################################################################

RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get update -qq && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
        gcc-${GCC_VER} g++-${GCC_VER} gdb

# Set installed gcc as default
RUN update-alternatives --install /usr/bin/gcc gcc $(which gcc-${GCC_VER}) 100
RUN update-alternatives --install /usr/bin/g++ g++ $(which g++-${GCC_VER}) 100

################################ CLANG ################################################################################

RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - 2>/dev/null && \
    add-apt-repository -y "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${LLVM_VER} main" && \
    apt-get update -qq && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
        clang-${LLVM_VER} lldb-${LLVM_VER} lld-${LLVM_VER} clangd-${LLVM_VER} \
        llvm-${LLVM_VER}-dev libclang-${LLVM_VER}-dev libclang-cpp${LLVM_VER}-dev \ 
        clang-tidy-${LLVM_VER} clang-tools-${LLVM_VER} llvm-${LLVM_VER}-tools \
        libc++-${LLVM_VER}-dev libc++abi-${LLVM_VER}-dev libclang-common-${LLVM_VER}-dev

# fix include symlink
RUN rm /usr/lib/clang/16/include
RUN rm /usr/lib/clang/16.0.3/include

RUN ln -s /usr/lib/llvm-16/lib/clang/16/include /usr/lib/clang/16/include
RUN ln -s /usr/lib/llvm-16/lib/clang/16/include /usr/lib/clang/16.0.3/include

# Set installed clangd as default
RUN update-alternatives --install /usr/bin/clangd clangd $(which clangd-${LLVM_VER}) 1

# Set the default clang-tidy, so CMake can find it
RUN update-alternatives --install /usr/bin/clang-tidy clang-tidy $(which clang-tidy-${LLVM_VER}) 1

# Set installed clang as default
RUN update-alternatives --install /usr/bin/clang clang $(which clang-${LLVM_VER}) 100
RUN update-alternatives --install /usr/bin/clang++ clang++ $(which clang++-${LLVM_VER}) 100

################################ CMAKE ################################################################################

RUN mkdir -p /tmp/cmake-${CMAKE_VERSION}
RUN mkdir -p /usr/lib/cmake-${CMAKE_VERSION}

RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh -O /tmp/cmake-${CMAKE_VERSION}/cmake_installer.sh
RUN sh /tmp/cmake-${CMAKE_VERSION}/cmake_installer.sh --prefix="/usr/lib/cmake-${CMAKE_VERSION}" --skip-license

RUN update-alternatives --install /usr/bin/cmake cmake /usr/lib/cmake-${CMAKE_VERSION}/bin/cmake 100
RUN update-alternatives --install /usr/bin/ctest ctest /usr/lib/cmake-${CMAKE_VERSION}/bin/ctest 100

RUN rm -r /tmp/cmake-${CMAKE_VERSION}

################################ Ninja build ##########################################################################

RUN mkdir -p /tmp/ninja-${NINJA_VERSION}
RUN mkdir -p /usr/lib/ninja-${NINJA_VERSION}/bin

RUN wget https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip -O /tmp/ninja-${NINJA_VERSION}/ninja-linux.zip
RUN cd /tmp/ninja-${NINJA_VERSION} && unzip ninja-linux.zip && mv ninja /usr/lib/ninja-${NINJA_VERSION}/bin/ninja

RUN update-alternatives --install /usr/bin/ninja ninja /usr/lib/ninja-${NINJA_VERSION}/bin/ninja 100

RUN rm -r /tmp/ninja-${NINJA_VERSION}

################################ TOOLS & LIBS #########################################################################

RUN apt-get update -qq && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends python3 python3-pip \
        less \
        zsh

################################ CLEANUP ##############################################################################

RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

################################ USER #################################################################################

RUN groupadd -g "${GID}" devloper \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" developer

USER developer

# add .local/bin to PATH
ENV PATH="$PATH:/home/developer/.local/bin"

# Install conan
RUN python3 -m pip install --upgrade pip setuptools && \
    python3 -m pip install --user conan==${CONAN_VER}

# Select default compilers
ENV CC="${DEFAULT_C_COMPILER}"
ENV CXX="${DEFAULT_CPP_COMPILER}"

# Install oh-my-zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# Set some env that allows to run appimages without fuse
ENV APPIMAGE_EXTRACT_AND_RUN=1

# Install neovim appimage
RUN wget https://github.com/neovim/neovim/releases/download/v0.9.0/nvim.appimage -O /home/developer/.local/bin/nvim
RUN chmod u+x /home/developer/.local/bin/nvim

RUN git clone --depth 1 https://github.com/wbthomason/packer.nvim /home/developer/.local/share/nvim/site/pack/packer/start/packer.nvim

ADD --chown=developer:developer nvim_config/init.lua /home/developer/.config/nvim/init.lua
ADD --chown=developer:developer nvim_config/lua /home/developer/.config/nvim/lua
RUN nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
ADD --chown=developer:developer nvim_config/after /home/developer/.config/nvim/after

WORKDIR /home/developer/repos

CMD ["zsh"]
