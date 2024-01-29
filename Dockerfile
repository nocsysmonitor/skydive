FROM ubuntu:20.04 as builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update \
    && apt-get -y install build-essential git npm openvswitch-common libpcap0.8 libpcap0.8-dev libxml2-dev protobuf-compiler libprotobuf-dev libvirt-dev curl wget\
    && rm -rf /var/lib/apt/lists/*

ARG GO_VERSION=go1.14.14.linux-amd64.tar.gz

WORKDIR /go/src/github.com/skydive-project/skydive
COPY . .
ARG GOPATH=/go
RUN wget https://go.dev/dl/${GO_VERSION} && tar -C /usr/local/ -zxf ${GO_VERSION}
ARG PATH=$PATH:/usr/local/go/bin
RUN make build

FROM ubuntu:20.04 as skydive
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update \
    && apt-get -y install npm openvswitch-common libpcap0.8 libvirt0 \
    && rm -rf /var/lib/apt/lists/*

ARG GO_VERSION=go1.14.14.linux-amd64.tar.gz
COPY --from=builder /go/src/github.com/skydive-project/skydive/${GO_VERSION} /root
RUN tar -C /usr/local/ -zxf /root/${GO_VERSION}
RUN rm /root/${GO_VERSION}
RUN export PATH=$PATH:/usr/local/go/bin

COPY --from=builder /go/src/github.com/skydive-project/skydive/skydive /usr/bin/skydive
COPY contrib/docker/skydive.yml /etc/skydive.yml
ENTRYPOINT ["/usr/bin/skydive", "--conf", "/etc/skydive.yml"]
