# Dockerfile Drone

FROM google/golang

ENV DRONE_SERVER_PORT :80

ADD . /gopath/src/github.com/drone/drone/
WORKDIR /gopath/src/github.com/drone/drone

RUN apt-get update
RUN apt-get -y install zip libsqlite3-dev sqlite3 1> /dev/null 2> /dev/null
RUN make deps build embed install

EXPOSE 80

ENV DRONE_DATABASE_DATASOURCE /var/lib/drone/drone.sqlite
ENV DRONE_DATABASE_DRIVER sqlite3

VOLUME ["/var/lib/drone"]

ENTRYPOINT ["/usr/local/bin/droned"]
