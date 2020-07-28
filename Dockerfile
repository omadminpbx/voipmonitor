FROM httpd:latest
LABEL maintainer fbarbier@orizonmobile.com
ENV DEBIAN_FRONTEND noninteractive
RUN apt update
RUN apt-get -y install mtr ethtool rrdtool librsvg2-bin gsfonts openssh-server nano sudo curl git wget htop iftop lsof cron
RUN sed -ie 's/#Port 22/Port 14501/g' /etc/ssh/sshd_config
RUN sed -ie 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
RUN sed -ie 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
RUN sed -ie 's/#X11/X11/g' /etc/ssh/sshd_config
RUN /etc/init.d/ssh start
RUN /etc/init.d/cron start
RUN apt-get -y install default-mysql-server
RUN apt-get -y install php php-gd php-mysql php-cli php-mbstring php-xml php-zip php-gettext
RUN apt-get -y install unzip apache2 libapache2-mod-php
RUN mkdir /opt/voipmonitor
WORKDIR /opt/voipmonitor
RUN wget http://voipmonitor.org/ioncube/x86_64/ioncube_loader_lin_7.3.so -O /usr/lib/php/20180731/ioncube_loader_lin_7.3.so
RUN echo "zend_extension = /usr/lib/php/20180731/ioncube_loader_lin_7.3.so" > /etc/php/7.3/apache2/conf.d/01-ioncube.ini
RUN echo "zend_extension = /usr/lib/php/20180731/ioncube_loader_lin_7.3.so" > /etc/php/7.3/cli/conf.d/01-ioncube.ini
RUN wget --content-disposition http://www.voipmonitor.org/current-stable-sniffer-static-64bit.tar.gz -O /opt/voipmonitor/voipmonitor.tar.gz
RUN tar xzf /opt/voipmonitor/voipmonitor.tar.gz --one-top-level=voipmonitor --strip-components 1
WORKDIR /opt/voipmonitor/voipmonitor
RUN /bin/bash /opt/voipmonitor/voipmonitor/install-script.sh --no-user-input
RUN echo [mysqld] >> /etc/mysql/my.cnf
RUN echo skip-grant-tables >> /etc/mysql/my.cnf
RUN service mysql start
RUN mysql -u root -e "CREATE DATABASE voipmonitor;"
RUN mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'jeTZK2ipdVK';"
RUN service voipmonitor enable
RUN service voipmonitor start
RUN mv /etc/voipmonitor.conf /etc/voipmonitor.conf.bak
RUN cd /var/www/html
RUN wget "http://www.voipmonitor.org/download-gui?version=latest&major=5&phpver=72&festry" -O w.tar.gz
RUN tar xzf w.tar.gz
RUN mv voipmonitor-gui*/* ./
RUN rm -f /var/www/html/index.html
RUN rm -f /var/www/html/w.tar.gz
ADD key.php /var/hmtl/
RUN chown www-data /var/spool/voipmonitor/
RUN chown -R www-data /var/www
RUN echo "* * * * * root php /var/www/html/php/run.php cron" >> /etc/crontab
RUN rm -r /opt/voipmonitor
RUN cronp=$(ps -aux | pgrep cron)
RUN echo Cron process number is $cronp. Now kill it!
RUN kill -9 $cronp
RUN echo Kill done
ADD voipmonitor.conf /etc/voipmonitor.conf
RUN service apache2 restart
ADD key.php /var/hmtl/
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
EXPOSE 8089 2100
WORKDIR /
CMD ["/docker-entrypoint.sh", "start"]
