FROM raspbian:latest
MAINTAINER Marco Felicio maffpt@gmail.com (branch from Bill McGair bill@mcgair.com)

ARG MY_CN
WORKDIR /var/www

# Update and upgrade
# install apache and mods
RUN apt-get install apache2 -y \
    && a2enmod rewrite \
    && a2enmod ssl

# send logs to stdout
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stdout /var/log/apache2/error.log

# get WebCoRE code
RUN git clone https://github.com/ajayjohn/webCoRE \
    && cd webCoRE \
    && git checkout hubitat-patches \
    && cd ../ \
    && ln -s webCoRE/dashboard webcore

# generate certificate
RUN mkdir -p /etc/apache2/ssl \
    && openssl req -new -newkey rsa:2048 -days 9999 -nodes -x509 -subj "/C=US/ST=Oregon/L=Portland/O=Dis/CN=$MY_CN"  -keyout /etc/apache2/ssl/$MY_CN.key  -out /etc/apache2/ssl/$MY_CN.crt

# add apache conf
#COPY webcore-apache.conf /etc/apache2/sites-enabled/000-default.conf
RUN echo "<VirtualHost *:80>"                                      >> /etc/apache2/sites-enabled/000-default.conf \
    && echo "   ServerAdmin webmaster@localhost"                    > /etc/apache2/sites-enabled/000-default.conf \
    && echo "   #The DocumentRoot is changed to the webCoRE installation symlink directory" \
    &&                                                              > /etc/apache2/sites-enabled/000-default.conf \
    && echo "   DocumentRoot /var/www/webcore/"                     > /etc/apache2/sites-enabled/000-default.conf \
    && echo "   #We need to allow all overrides for the dashboard directories" \
    &&                                                              > /etc/apache2/sites-enabled/000-default.conf \
    && echo "   <Directory "/var/www/webcore">"                     > /etc/apache2/sites-enabled/000-default.conf \
    && echo "       AllowOverride All"                              > /etc/apache2/sites-enabled/000-default.conf \
    && echo "   </Directory>"                                       > /etc/apache2/sites-enabled/000-default.conf \
    && echo "   #These are not changed - they are the default log directives - change as you need/want" \
    &&                                                              > /etc/apache2/sites-enabled/000-default.conf \
    && echo "   ErrorLog ${APACHE_LOG_DIR}/error.log"               > /etc/apache2/sites-enabled/000-default.conf \
    && echo "   CustomLog ${APACHE_LOG_DIR}/access.log combined"    > /etc/apache2/sites-enabled/000-default.conf \
    && echo "</VirtualHost>"                                        > /etc/apache2/sites-enabled/000-default.conf \

# Install WebCoRE local
RUN cd ~/ \
    && git clone https://github.com/imnotbob/webCoRE \
    && cd webCoRE \
    && git checkout hubitat-patches \
    && cd dashboard \
    && sudo ln -spwd/var/www/webcore
dt=$(date '+%d/%m/%Y %H:%M:%S');

EXPOSE 443

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
