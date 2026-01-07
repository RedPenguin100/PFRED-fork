# syntax=docker/dockerfile:1

############################
# 1) Builder Stage
############################
FROM scientificlinux/sl:6 AS builder

WORKDIR /tmp/src

# 1.1 Fix Repos for SL6 (Vault Mirrors)
# Uses printf to prevent Legacy Builder 'heredoc' crashes
RUN rm -f /etc/yum.repos.d/*.repo && \
    printf '[sl6-os]\n\
name=Scientific Linux 6.10 - OS (obsolete)\n\
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/os/\n\
enabled=1\n\
gpgcheck=0\n\
sslverify=0\n\
\n\
[sl6-fastbugs]\n\
name=Scientific Linux 6.10 - Fastbugs (obsolete)\n\
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/updates/fastbugs/\n\
enabled=1\n\
gpgcheck=0\n\
sslverify=0\n\
\n\
[sl6-security]\n\
name=Scientific Linux 6.10 - Security (obsolete)\n\
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/updates/security/\n\
enabled=1\n\
gpgcheck=0\n\
sslverify=0\n' > /etc/yum.repos.d/sl6-obsolete.repo

# 1.2 Install Build Dependencies
RUN yum -y clean all && yum -y makecache && \
    yum -y install \
      wget tar make gcc gcc-c++ gcc-gfortran \
      python-devel readline-devel zlib-devel \
      perl perl-DBI perl-DBD-mysql \
      ca-certificates \
    && yum clean all

# 1.3 Download Source Files
RUN wget --no-check-certificate -O numpy-1.4.1.tar.gz "https://sourceforge.net/projects/numpy/files/NumPy/1.4.1/numpy-1.4.1.tar.gz/download" && \
    wget --no-check-certificate -O R-2.6.0.tar.gz "https://cran.r-project.org/src/base/R-2/R-2.6.0.tar.gz" && \
    wget --no-check-certificate -O rpy-1.0.2.tar.gz "https://sourceforge.net/projects/rpy/files/rpy/1.0.2/rpy-1.0.2.tar.gz/download" && \
    wget --no-check-certificate -O pls_2.1-0.tar.gz "https://cran.r-project.org/src/contrib/Archive/pls/pls_2.1-0.tar.gz" && \
    wget --no-check-certificate -O randomForest_4.6-10.tar.gz "https://cran.r-project.org/src/contrib/Archive/randomForest/randomForest_4.6-10.tar.gz" && \
    wget --no-check-certificate -O e1071_1.5-27.tar.gz "https://cran.r-project.org/src/contrib/Archive/e1071/e1071_1.5-27.tar.gz" && \
    for f in *.tar.gz; do tar -xvf "$f"; done

# 1.4 Prepare Directories
RUN mkdir -p /home/pfred/bin

# 1.5 Build Numpy (Python 2.6)
RUN cd /tmp/src/numpy-1.4.1 && \
    python setup.py build --fcompiler=gnu95 && \
    python setup.py install --prefix=/home/pfred/bin/numpy

# 1.6 Build R 2.6.0
RUN cd /tmp/src/R-2.6.0 && \
    ./configure --prefix=/home/pfred/bin/R2.6.0 --enable-R-shlib --with-x=no && \
    make -j"$(nproc)" && \
    make install

# 1.7 Setup Environment for R Compilation
ENV PATH=/home/pfred/bin/R2.6.0/bin:$PATH
ENV LD_LIBRARY_PATH=/home/pfred/bin/R2.6.0/lib64:/home/pfred/bin/R2.6.0/lib
ENV RHOMES=/home/pfred/bin/R2.6.0/lib64/R

# 1.8 Build RPy and R Packages
RUN cd /tmp/src/rpy-1.0.2 && \
    python setup.py install --prefix=/home/pfred/bin/rpy && \
    R CMD INSTALL /tmp/src/pls_2.1-0.tar.gz && \
    R CMD INSTALL /tmp/src/randomForest_4.6-10.tar.gz && \
    R CMD INSTALL /tmp/src/e1071_1.5-27.tar.gz

# 1.9 Reorganize site-packages
WORKDIR /home/pfred/bin/site-packages
RUN mkdir -p rpy && \
    mv /home/pfred/bin/numpy/lib64/python2.6/site-packages/numpy . && \
    mv /home/pfred/bin/rpy/lib64/python2.6/site-packages/* rpy && \
    rm -rf /home/pfred/bin/numpy /home/pfred/bin/rpy

############################
# 2) Runtime Stage
############################
FROM scientificlinux/sl:6 AS pfredenv

WORKDIR /home/pfred

# 2.1 Fix Repos (Again) - Uses printf for Legacy Builder
RUN rm -f /etc/yum.repos.d/*.repo && \
    printf '[sl6-os]\n\
name=Scientific Linux 6.10 - OS (obsolete)\n\
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/os/\n\
enabled=1\n\
gpgcheck=0\n\
sslverify=0\n\
\n\
[sl6-fastbugs]\n\
name=Scientific Linux 6.10 - Fastbugs (obsolete)\n\
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/updates/fastbugs/\n\
enabled=1\n\
gpgcheck=0\n\
sslverify=0\n\
\n\
[sl6-security]\n\
name=Scientific Linux 6.10 - Security (obsolete)\n\
baseurl=https://linux2.yz.yamagata-u.ac.jp/pub/Linux/scientific/obsolete/6.10/x86_64/updates/security/\n\
enabled=1\n\
gpgcheck=0\n\
sslverify=0\n' > /etc/yum.repos.d/sl6-obsolete.repo

# 2.2 Install Runtime Dependencies
RUN yum -y clean all && yum -y makecache && \
    yum -y install \
      wget tar bzip2 \
      java-1.8.0-openjdk \
      perl perl-DBI perl-DBD-mysql \
      libgfortran \
      libXcomposite libXcursor libXi libXtst libXrandr \
      alsa-lib mesa-libGL libXdamage libXScrnSaver \
    && yum clean all

# 2.3 Copy Artifacts from Builder
COPY --from=builder /home/pfred/bin /home/pfred/bin

# 2.4 Environment Variables (Strictly Legacy)
ENV PFRED_PREFIX=/home/pfred/bin
ENV R_PREFIX=/home/pfred/bin/R2.6.0
ENV R_BIN=/home/pfred/bin/R2.6.0/bin
ENV LD_LIBRARY_PATH=/home/pfred/bin/R2.6.0/lib64:/home/pfred/bin/R2.6.0/lib:$LD_LIBRARY_PATH
ENV RHOMES=/home/pfred/bin/R2.6.0/lib64/R
ENV PYTHONPATH=/home/pfred/bin/site-packages:/home/pfred/bin/site-packages/rpy:$PYTHONPATH
ENV PATH=$R_BIN:$PATH

# 2.5 Interactive Shell Support
RUN echo "export PATH=$PATH" >> ~/.bashrc && \
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> ~/.bashrc && \
    echo "export PYTHONPATH=$PYTHONPATH" >> ~/.bashrc

# 2.6 Scripts and Entrypoint
RUN mkdir -p scripts scratch
COPY ./entrypoint.sh entrypoint.sh
COPY ./setup_env.sh setup_env.sh
RUN chmod +x entrypoint.sh setup_env.sh

ENTRYPOINT ["./entrypoint.sh"]