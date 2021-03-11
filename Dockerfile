FROM mstrazds/nginx-php56

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y

RUN apt-get install --no-install-recommends -y locales software-properties-common && \
	add-apt-repository ppa:ondrej/php && apt-get --no-install-recommends -y update

RUN apt-get install --no-install-recommends -y \
	php5.6-cli \
	php5.6-fpm \
	php5.6-mysql \
	php5.6-pgsql \
	php5.6-sqlite \
	php5.6-curl \
	php5.6-gd \
	php5.6-mcrypt \
	php5.6-intl \
	php5.6-imap \
	php5.6-tidy \
	php5.6-memcache
RUN apt-get install --no-install-recommends -y \
	nginx \
	memcached \
	mysql-server mysql-client \
	supervisor

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apt-get -y autoremove && apt-get clean && apt-get autoclean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/5.6/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/5.6/cli/php.ini

RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/www

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/5.6/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/5.6/fpm/php.ini
 
ADD nginx-site   /etc/nginx/sites-available/default

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stdout /var/log/nginx/error.log

RUN /etc/init.d/mysql start

RUN /usr/sbin/mysqld & \
	sleep 10s &&\
	echo "GRANT ALL ON *.* TO admin@'%' IDENTIFIED BY 'changeme' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

RUN service php5.6-fpm start

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD phinx.php /etc/phinx.php
ADD migrate.sh /usr/local/bin/migrate.sh
ADD run.sh /usr/local/bin/run.sh

EXPOSE 80
EXPOSE 3306

CMD ["/usr/local/bin/run.sh"]