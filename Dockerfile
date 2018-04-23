FROM alpine:latest
MAINTAINER Patricio Téllez <pato.tellez@gmail.com>

# Now copy all nice scripts from our subdirectory to the root
COPY scripts/ /scripts/

# Install TCL, TLS and expect (for pure readline) from the main repo
# And run a script to get the tcllib from github. wget does not handle https
# on top of busybox, and installing curl would be rather dumb as we can already
# support http and https (as from the installed packages above)
# untar into the temporary directory and install the tcllib to /usr/lib
# so scripts can find it.
# Adds "sleep 1" because of error "/scripts/wsget.tcl: Text file busy"
RUN apk add --update-cache tcl tcl-tls expect openssh-client bash && \
    chmod u+x /scripts/wsget.tcl && \
    sleep 1 && sync && \
    /scripts/wsget.tcl https://github.com/tcltk/tcllib/archive/tcllib-1-19.tar.gz /tmp/ && \
    tar -zx -C /tmp -f /tmp/tcllib-1-19.tar.gz && \
    tclsh /tmp/tcllib-tcllib-1-19/installer.tcl -no-html -no-nroff -no-examples -no-gui -no-apps -no-wait -pkg-path /usr/lib/tcllib1.19 && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/tcllib*

# tdom compilation and installation
RUN apk add --no-cache tcl-dev build-base && \
    /scripts/wsget.tcl http://tdom.org/downloads/tdom-0.9.0-src.tgz /tmp/ && \
    tar -zx -C  /tmp -f /tmp/tdom-0.9.0-src.tgz && \
    cd /tmp/tdom-0.9.0/unix && \
    ../configure && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/tdom-0.9.0* && \
    apk del build-base tcl-dev

# Export two volumes, one for tcl code and one for data, just in case.
VOLUME /opt/tcl
VOLUME /opt/data

# Make sure code put into the special tcl volume can lazily be filled
# with packages
ENV TCLLIBPATH /opt/tcl /opt/tcl/lib

# Arrange for a nice prompt
COPY scripts/tclshrc /root/.tclshrc
ENTRYPOINT ["bash"]
