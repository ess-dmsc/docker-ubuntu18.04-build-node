FROM ubuntu:18.04

# Prevent tzdata apt-get installation from asking for input.
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install clang-format cloc doxygen gcc-8 g++-8 git graphviz \
        flex lcov mpich python3-pip qt5-default valgrind vim-common tzdata \
        autoconf automake libtool perl ninja-build curl libssl-dev && \
    apt-get -y autoremove && \
    apt-get clean all

RUN curl -LO https://github.com/Kitware/CMake/releases/download/v3.17.3/cmake-3.17.3.tar.gz && \
    tar xf cmake-3.17.3.tar.gz && \
    cd cmake-3.17.3 && \
    ./bootstrap && make && make install

RUN pip3 install conan==1.35.2 coverage==4.4.2 flake8==3.5.0 gcovr==4.1 && \
    rm -rf /root/.cache/pip/*

ENV CONAN_USER_HOME=/conan

RUN mkdir $CONAN_USER_HOME && \
    conan

RUN conan config install http://github.com/ess-dmsc/conan-configuration.git

COPY files/default_profile $CONAN_USER_HOME/.conan/profiles/default

RUN cd /tmp && \
    curl -o cppcheck.tar.gz -L https://github.com/danmar/cppcheck/archive/2.0.tar.gz && \
    tar xf cppcheck.tar.gz && \
    cd cppcheck-2.0 && \
    mkdir build && \
    cd build && \
    sed -i "s|LIST(GET VERSION_PARTS 2 VERSION_PATCH)|  |g" ../cmake/versions.cmake && \
    cmake -GNinja .. && \
    ninja install && \
    cd ../.. && \
    rm -rf cppcheck-2.0 && \
    rm -rf cppcheck.tar.gz

RUN git clone https://github.com/ess-dmsc/build-utils.git && \
    cd build-utils && \
    git checkout c05ed046dd273a2b9090d41048d62b7d1ea6cdf3 && \
    make install

RUN adduser --disabled-password --gecos "" jenkins

RUN chown -R jenkins $CONAN_USER_HOME/.conan

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 --slave /usr/bin/g++ g++ /usr/bin/g++-8
RUN update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-8 800

USER jenkins
WORKDIR /home/jenkins

RUN python3 -m pip install --user black codecov
