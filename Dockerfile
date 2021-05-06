FROM alpine as ioncube_loader
RUN apk add git \
	&& git -c http.sslVerify=false clone https://git.dev.glo.gb/cloudhostingpublic/ioncube_loader \
	&& tar zxf ioncube_loader/ioncube_loaders_lin_x86-64.tar.gz

FROM alpine as php_debs
RUN apk add git \
	&& git -c http.sslVerify=false clone https://git.dev.glo.gb/cloudhostingpublic/legacy-php-build

FROM 1and1internet/debian-8:latest
MAINTAINER brian.wilkinson@1and1.co.uk
ARG DEBIAN_FRONTEND=noninteractive
COPY files /
ARG PHPVER=7.0

COPY --from=ioncube_loader /ioncube/ioncube_loader_lin_${PHPVER}.so /usr/lib/php/${PHPVER}/extensions
COPY --from=php_debs /legacy-php-build/debs/${PHPVER}/*.deb /tmp/

RUN \
	apt-get update && \
	echo "Utilities" && \
	apt-get install -y \
		mysql-client sqlite sqlite3 git vim traceroute telnet nano dnsutils \
		curl iputils-ping openssh-client openssh-sftp-server wget redis-tools && \
	echo "Dependencies" && \
		apt-get install -y \
			libmysqlclient-dev zlib1g-dev libsqlite3-dev gnupg build-essential  \
			apt-transport-https ca-certificates lsb-release imagemagick graphicsmagick \
			libc-client2007e libcurl3 libicu52 libjpeg62-turbo libmcrypt4 libtidy-0.99-0 libxslt1.1 \
			libiconv-hook1 libldap-2.4-2 libmhash2 libodbc1 \
			libpq5 libsnmp30 libxmlrpc-epi0 librecode0 snmp-mibs-downloader && \
  	echo "PHP" && \
		dpkg -i /tmp/php${PHPVER}*.deb && \
		rm -f /tmp/php${PHPVER}*.deb && \
		update-alternatives --install /usr/bin/php php /usr/bin/php${PHPVER} 1 && \
  	echo "COMPOSER" && \
		mkdir /tmp/composer/ && \
	    cd /tmp/composer && \
	    curl -sS https://getcomposer.org/installer | php && \
	    mv composer.phar /usr/local/bin/composer && \
	    chmod a+x /usr/local/bin/composer && \
	    cd / && \
	    rm -rf /tmp/composer && \
  apt-get autoremove -y && apt-get autoclean -y && \
  mkdir -m 0777 /var/www && \
  chmod 0755 -R /hooks /init && \
  chmod 0777 /etc/passwd /etc/group && \
  rm -f /etc/ssh/ssh_host_* && \
  chmod -R 0777 /etc/supervisor/conf.d

ENV COMPOSER_HOME=/var/www \
    HOME=/var/www

WORKDIR /var/www

# Install and configure the cron service
ENV EDITOR=/usr/bin/vim \
	CRON_LOG_FILE=/var/spool/cron/cron.log \
	CRON_LOCK_FILE=/var/spool/cron/cron.lock \
	CRON_ARGS=""
RUN \
  apt-get update && apt-get install -y -o Dpkg::Options::="--force-confold" logrotate man && \
  cd /src/cron-3.0pl1 && \
  make install && \
  mkdir -p /var/spool/cron/crontabs && \
  chmod -R 777 /var/spool/cron && \
  cp debian/crontab.main /etc/crontab && \
  cd - && \
  rm -rf /src && \
  find /etc/cron.* -type f | egrep -v 'logrotate|placeholder' | xargs -i rm -f {} && \
  chmod 666 /etc/logrotate.conf && \
  chmod -R 777 /var/lib/logrotate && \
  rm -rf /var/lib/apt/lists/*
