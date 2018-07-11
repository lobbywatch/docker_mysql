# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

# Copied from https://github.com/mysql/mysql-docker/tree/mysql-server/5.7

# Build image cmd: docker build -t debian-mysql-server-5.7 .

FROM debian:sid

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql \
  \
  && printf "\nalias ll='ls -l'\nalias l='ls -lA'\n" >> /root/.bashrc \
  # Map Ctrl-Up and Ctrl-Down to history based bash completion
  && printf '"\\e[1;5A": history-search-backward\n"\\e[1;5B": history-search-forward\n"\\e[1;5C": forward-word\n"\\e[1;5D": backward-word' > /etc/inputrc \
  \
  && apt-get update \
  # Install minimal admin utils
  && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils less nano procps \
  # Install MySQL server
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libpwquality-tools mysql-server-5.7 \
  # Clean cache
  && rm -rf /var/lib/apt/lists/* \
  \
  && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
  && touch /var/log/mysqld.log \
  && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /var/log/mysqld.log \
  # Ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
  && chmod 777 /var/run/mysqld \
  && chmod 775 /var/log \
  # Disable Debian MySQL config since it overwrites config from volume
  && mv /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.disabled \
  && mv /etc/mysql/conf.d/mysqldump.cnf /etc/mysql/conf.d/mysqldump.cnf.disabled \
  && mv /etc/mysql/conf.d/mysql.cnf /etc/mysql/conf.d/mysql.cnf.disabled \
  # Create placeholder for custom my.cnf
  && touch /etc/mysql/conf.d/my.cnf \
  # Set docker settings, these settings always win
  && printf '[client]\nsocket=/var/lib/mysql/mysql.sock\n\n[server]\nsocket=/var/lib/mysql/mysql.sock\ndatadir=/var/lib/mysql\nsecure-file-priv=/var/lib/mysql-files\nuser=mysql\nskip-host-cache\nskip-name-resolve\n' > /etc/mysql/mysql.conf.d/docker.cnf \
  \
  && mkdir /docker-entrypoint-initdb.d

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
ENTRYPOINT ["/entrypoint.sh"]
HEALTHCHECK CMD /healthcheck.sh
EXPOSE 3306 33060
CMD ["mysqld"]
