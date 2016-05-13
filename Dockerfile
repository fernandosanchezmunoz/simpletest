FROM alpine:3.3

#SSH home and port. User is expected to expose a volume for SSH as /data/
VOLUME ["/data/"]

USER=user

RUN apk add --update curl build-base bash iperf nmap nginx openssh rsync && \
#
#get netperf
  curl -LO ftp://ftp.netperf.org/netperf/netperf-2.7.0.tar.gz && \
  tar -xzf netperf-2.7.0.tar.gz  && \
  cd netperf-2.7.0 && ./configure --prefix=/usr && make && make install && \
  rm -rf netperf-2.7.0 netperf-2.7.0.tar.gz && \
  rm -f /usr/share/info/netperf.info && \
  strip -s /usr/bin/netperf /usr/bin/netserver && \
  apk del curl build-base && rm -rf /var/cache/apk/* && \
#SSH preparation
  adduser -D $USER -h /data/ && \
#SSH keys
  mkdir -p $USER/.ssh && chmod 700 $USER/.ssh/ && \
#  echo -e "Port ${SSH_PORT:-22}\n" >> /etc/ssh/sshd_config && \
  echo -e "Port 22\n" >> /etc/ssh/sshd_config && \
#delete cache
  rm -rf /var/cache/apk/*

#COPY SSH keys
  COPY user.pub $USER/.ssh/authorized_keys

#FIXME: SSH port should be configurable
#EXPOSE ${SSH_PORT:-22}
EXPOSE 22

#prepare content for nginx
RUN mkdir -p /tmp/nginx/client-body
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY website /usr/share/nginx/html

#run nginx web server in 80 #FIXME: $WEB_PORT
RUN ["nginx"]
#EXPOSE ${WEB_PORT:-80}
EXPOSE 80

#run iperf tcp server on port $IPERF_TCP_PORT (5001 default)
#RUN ["iperf", "-s", "-D", "-p ${IPERF_TCP_PORT:-5001}"]
#EXPOSE ${IPERF_TCP_PORT:-5001}
RUN ["iperf", "-s", "-D", "-p 5001"]
EXPOSE 5001

#run netperf tcp server on port $NETPERF_TCP_PORT (6001 default)
RUN ["netserver", "-p 6001"]
#FIXME: "-p ${NETPERF_TCP_PORT:-6001}"
EXPOSE 6001
#FIXME:EXPOSE "${NETPERF_TCP_PORT:-6001}"

#entry point is ssh
#ENTRYPOINT ["/etc/init.d/sshd", "start"]
ENTRYPOINT  ["/usr/sbin/sshd", "-D"]