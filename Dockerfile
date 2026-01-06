# syntax=docker/dockerfile:1

############################
# 1) Builder
############################
FROM scientificlinux/sl:6 AS builder

WORKDIR /home/pfred
RUN mkdir -p /home/pfred/bin /tmp/src

# Working SL6.10 obsolete repos (OS + fastbugs + security)
RUN rm -f /etc/yum.repos.d/*.repo && \
  cat > /etc/yum.repos.d/sl6-obsolete.repo <<'EOF'
[sl6-os]
name=Scientific Linux 6.10 - OS (obsolete)
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/os/
enabled=1
gpgcheck=0
sslverify=0
ip_resolve=4

[sl6-fastbugs]
name=Scientific Linux 6.10 - Fastbugs (obsolete)
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/updates/fastbugs/
enabled=1
gpgcheck=0
sslverify=0
ip_resolve=4

[sl6-security]
name=Scientific Linux 6.10 - Security (obsolete)
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/updates/security/
enabled=1
gpgcheck=0
sslverify=0
ip_resolve=4
EOF

RUN yum -y clean all && yum -y makecache

RUN yum -y update && \
    yum -y install \
      ca-certificates \
      curl \
      wget \
      gcc gcc-c++ gcc-gfortran \
      python-devel \
      readline-devel \
      zlib-devel \
      perl \
      perl-DBI \
      perl-DBD-mysql \
      make \
      tar \
    && yum clean all

ENV PFRED_PREFIX=/home/pfred/bin
ENV R_PREFIX=/home/pfred/bin/R2.6.0
ENV PATH=/home/pfred/bin/R2.6.0/bin:$PATH
ENV LD_LIBRARY_PATH=/home/pfred/bin/R2.6.0/lib64:/home/pfred/bin/R2.6.0/lib:$LD_LIBRARY_PATH
ENV RHOMES=/home/pfred/bin/R2.6.0/lib64/R
ENV PYTHONPATH=/home/pfred/bin/site-packages:/home/pfred/bin/site-packages/rpy:$PYTHONPATH

WORKDIR /tmp/src

RUN curl -L -o numpy-1.4.1.tar.gz "https://sourceforge.net/projects/numpy/files/NumPy/1.4.1/numpy-1.4.1.tar.gz/download" && \
    curl -L -o R-2.6.0.tar.gz "https://cran.r-project.org/src/base/R-2/R-2.6.0.tar.gz" && \
    curl -L -o rpy-1.0.2.tar.gz "https://sourceforge.net/projects/rpy/files/rpy/1.0.2/rpy-1.0.2.tar.gz/download" && \
    curl -L -o pls_2.1-0.tar.gz "https://cran.r-project.org/src/contrib/Archive/pls/pls_2.1-0.tar.gz" && \
    curl -L -o randomForest_4.6-10.tar.gz "https://cran.r-project.org/src/contrib/Archive/randomForest/randomForest_4.6-10.tar.gz" && \
    curl -L -o e1071_1.5-27.tar.gz "https://cran.r-project.org/src/contrib/Archive/e1071/e1071_1.5-27.tar.gz" && \
    for f in *.tar.gz; do tar -xvf "$f"; done

RUN cd /tmp/src/numpy-1.4.1 && \
    python setup.py build --fcompiler=gnu95 && \
    python setup.py install --prefix=/home/pfred/bin/numpy

RUN cd /tmp/src/R-2.6.0 && \
    ./configure --prefix=/home/pfred/bin/R2.6.0 --enable-R-shlib --with-x=no && \
    make -j"$(nproc)" && \
    make install

RUN cd /tmp/src/rpy-1.0.2 && \
    python setup.py install --prefix=/home/pfred/bin/rpy && \
    R CMD INSTALL /tmp/src/pls_2.1-0.tar.gz && \
    R CMD INSTALL /tmp/src/randomForest_4.6-10.tar.gz && \
    R CMD INSTALL /tmp/src/e1071_1.5-27.tar.gz

WORKDIR /home/pfred/bin/site-packages
RUN mkdir -p rpy && \
    mv /home/pfred/bin/numpy/lib64/python2.6/site-packages/numpy . && \
    mv /home/pfred/bin/rpy/lib64/python2.6/site-packages/* rpy && \
    rm -rf /home/pfred/bin/numpy /home/pfred/bin/rpy


############################
# 2) Runtime
############################
FROM scientificlinux/sl:6 AS pfredenv

WORKDIR /home/pfred

RUN rm -f /etc/yum.repos.d/*.repo && \
  cat > /etc/yum.repos.d/sl6-obsolete.repo <<'EOF'
[sl6-os]
name=Scientific Linux 6.10 - OS (obsolete)
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/os/
enabled=1
gpgcheck=0
sslverify=0
ip_resolve=4

[sl6-fastbugs]
name=Scientific Linux 6.10 - Fastbugs (obsolete)
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/updates/fastbugs/
enabled=1
gpgcheck=0
sslverify=0
ip_resolve=4

[sl6-security]
name=Scientific Linux 6.10 - Security (obsolete)
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/updates/security/
enabled=1
gpgcheck=0
sslverify=0
ip_resolve=4
EOF

RUN yum -y clean all && yum -y makecache

RUN yum -y update && \
    yum -y install \
      ca-certificates \
      java-1.8.0-openjdk \
      perl perl-DBI perl-DBD-mysql \
      wget \
      libgfortran \
      libXcomposite libXcursor libXi libXtst libXrandr \
      alsa-lib mesa-libGL libXdamage libXScrnSaver \
      curl \
    && yum clean all

ENV PFRED_PREFIX=/home/pfred/bin
ENV R_PREFIX=/home/pfred/bin/R2.6.0
ENV PATH=/home/pfred/bin/R2.6.0/bin:$PATH
ENV LD_LIBRARY_PATH=/home/pfred/bin/R2.6.0/lib64:/home/pfred/bin/R2.6.0/lib:$LD_LIBRARY_PATH
ENV RHOMES=/home/pfred/bin/R2.6.0/lib64/R
ENV PYTHONPATH=/home/pfred/bin/site-packages:/home/pfred/bin/site-packages/rpy:$PYTHONPATH

COPY --from=builder /home/pfred/bin /home/pfred/bin

# Optional sanity check: verify R starts
RUN R --version

RUN mkdir -p scripts scratch

COPY ./entrypoint.sh entrypoint.sh
COPY ./setup_env.sh setup_env.sh
RUN chmod a+x entrypoint.sh setup_env.sh

ENTRYPOINT ["./entrypoint.sh"]
