# Utilizamos una imagen oficial de Ubuntu
FROM ubuntu:latest

# Damos información sobre la imagen que estamos creando
LABEL \
    version="1.0" \
    description="Ubuntu + Apache2 + virtual host + ProFTPD" \
    maintainer="ndomenech <ndomenech@birt.eus>"


RUN apt-get update && \
    apt-get install -y nano apache2 proftpd proftpd-mod-crypto ssh git openssl

RUN mkdir -p /var/www/html/sitioprimero /var/www/html/sitiosegundo /srv/ftp/proyecto

COPY /Entrega/ftp/indexprimero.html /Entrega/ftp/indexsegundo.html /Entrega/apache/sitioprimero.conf /Entrega/apache/sitiosegundo.conf /Entrega/ssh/sitioprimero.key /Entrega/ssh/sitioprimero.cer /

RUN mv /indexprimero.html /var/www/html/sitioprimero/indexprimero.html && \
    mv /indexsegundo.html /var/www/html/sitiosegundo/indexsegundo.html && \
    mv /sitioprimero.conf /etc/apache2/sites-available/sitioprimero.conf && \
    mv /sitiosegundo.conf /etc/apache2/sites-available/sitiosegundo.conf && \
    mv /sitioprimero.key /etc/ssl/private/sitioprimero.key && \
    mv /sitioprimero.cer /etc/ssl/certs/sitioprimero.cer

RUN useradd -m -d /var/www/html/sitioprimero -s /usr/sbin/nologin ndomenech1 && echo "ndomenech1:1234" | chpasswd && \ 
useradd -m -d /var/www/html/sitiosegundo -s /usr/bin/bash ndomenech2 && echo "ndomenech2:1234" | chpasswd && \ 
chown -R ndomenech1:ndomenech1 /var/www/html/sitioprimero && chmod -R 755 /var/www/html/sitioprimero && \ 
chown -R ndomenech2:ndomenech2 /var/www/html/sitiosegundo && chmod 755 /var/www/html/sitiosegundo && \ 
useradd -m -d /srv/ftp/proyecto -s /bin/bash ndomenech && echo "ndomenech:1234" | chpasswd && \
        chown -R ndomenech:ndomenech /srv/ftp/proyecto && \
        chmod -R 777 /srv/ftp/proyecto

RUN a2enmod ssl && \
    a2ensite sitioprimero.conf && \
    a2ensite sitiosegundo.conf && \
    a2enmod ssl && \
    service ssh start



RUN echo "/usr/sbin/nologin" >> /etc/shells

RUN echo "Include /etc/proftpd/conf.d/" >> /etc/proftpd/proftpd.conf && \
    echo "DefaultRoot ~" >> /etc/proftpd/proftpd.conf && \
    echo "PassivePorts 50000 50030" >> /etc/proftpd/proftpd.conf && \
    echo "MasqueradeAddress 192.168.0.17" >> /etc/proftpd/proftpd.conf && \
    echo "Include /etc/proftpd/tls.conf" >> /etc/proftpd/proftpd.conf && \
    echo "<Anonymous ~ftp>" >> /etc/proftpd/proftpd.conf && \
    echo "  User ftp" >> /etc/proftpd/proftpd.conf && \
    echo "  Group ftp" >> /etc/proftpd/proftpd.conf && \
    echo "  UserAlias anonymous ftp" >> /etc/proftpd/proftpd.conf && \
    echo "  MaxClients 10" >> /etc/proftpd/proftpd.conf && \
    echo "  RequireValidShell off" >> /etc/proftpd/proftpd.conf && \
    echo "  <Limit LOGIN>" >> /etc/proftpd/proftpd.conf && \
    echo "    AllowAll" >> /etc/proftpd/proftpd.conf && \
    echo "  </Limit>" >> /etc/proftpd/proftpd.conf && \
    echo "</Anonymous>" >> /etc/proftpd/proftpd.conf && \
    echo "<Directory /srv/ftp/proyecto>" >> /etc/proftpd/proftpd.conf && \
    echo "  <Limit READ>" >> /etc/proftpd/proftpd.conf && \
    echo "    AllowUser ftp" >> /etc/proftpd/proftpd.conf && \
    echo "    AllowUser ndomenech" >> /etc/proftpd/proftpd.conf && \
    echo "  </Limit>" >> /etc/proftpd/proftpd.conf && \
    echo "</Directory>" >> /etc/proftpd/proftpd.conf && \
    echo "<Limit LOGIN>" >> /etc/proftpd/proftpd.conf && \
    echo "DenyUser ndomenech2" >> /etc/proftpd/proftpd.conf && \
    echo "</Limit>" >> /etc/proftpd/proftpd.conf
    

    RUN echo "<IfModule mod_tls.c>" >> /etc/proftpd/tls.conf && \
    echo "TLSEngine on" >> /etc/proftpd/tls.conf && \
    echo "TLSLog /var/log/proftpd/tls.log" >> /etc/proftpd/tls.conf && \
    echo "TLSProtocol SSLv23" >> /etc/proftpd/tls.conf && \
    echo "TLSRSACertificateFile                   /etc/ssl/certs/sitioprimero.cer" >> /etc/proftpd/tls.conf && \
    echo "TLSRSACertificateKeyFile                /etc/ssl/private/sitioprimero.key" >> /etc/proftpd/tls.conf && \
    echo "</IfModule>" >> /etc/proftpd/tls.conf
RUN echo "LoadModule mod_tls.c" >> /etc/proftpd/modules.conf

RUN echo "AllowUsers ndomenech2" >> /etc/ssh/sshd_config && \
    echo "Port 1022" >> /etc/ssh/sshd_config && \
    echo "Port 22" >> /etc/ssh/sshd_config


COPY /Entrega/ssh/id_rsa /srv/ftp/id_rsa

RUN eval $(ssh-agent -s) && \
chmod 700 /srv/ftp/id_rsa && \
ssh-add /srv/ftp/id_rsa && \
ssh-keyscan -H github.com >> /etc/ssh/ssh_known_hosts && \
git clone git@github.com:deaw-birt/UD3-ftp_anonimo.git /srv/ftp/proyecto

RUN chmod 600 /etc/ssl/private/sitioprimero.key && \
    chmod 644 /etc/ssl/certs/sitioprimero.cer

# Exponemos los puertos para HTTP, HTTPS y FTP
EXPOSE 80
EXPOSE 443
EXPOSE 21
EXPOSE 1022
EXPOSE 50000-50030

# Comando por defecto al iniciar el contenedor
CMD ["apache2ctl", "-D", "FOREGROUND"]
