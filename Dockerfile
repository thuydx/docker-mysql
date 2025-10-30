FROM ubuntu:22.04

LABEL maintainer="Thuy Dinh <thuydx@zendgroup.vn>" \
      author="Thuy Dinh" \
      description="A comprehensive docker image to run MySQL 8 applications"

ENV DATE_TIMEZONE=UTC
ENV DEBIAN_FRONTEND=noninteractive

RUN groupadd -r mysql && useradd -r -g mysql mysql

# Try to fix failures  ERROR: executor failed running [
ENV DOCKER_BUILDKIT=0
ENV COMPOSE_DOCKER_CLI_BUILD=0

RUN sed -i 's|http://|http://vn.|g' /etc/apt/sources.list
RUN apt-get update && apt-get install -y \
    mysql-server \
    mysql-client \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql \
    && mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
	&& chmod 1777 /var/lib/mysql /var/run/mysqld

VOLUME /var/lib/mysql
# copy entrypoint into image
COPY config/ /etc/mysql/
COPY docker-entrypoint.sh /entrypoint.sh

# normalize line endings and make executable to avoid "/bin/bash\r" no-such-file
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh
# ensure Docker uses the script
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306 33060
CMD ["mysqld"]