# Описание Dockerfile для Kanboard
Данный файл брался c оффициального git репозитория проекта kanboard
В первой строке файла содержится аргумент, который указывает на требующуюся архитектуру процессора
```
ARG BASE_IMAGE_ARCH="amd64"
```
Образ базируется на  amd64/alpine:3.12
```
FROM ${BASE_IMAGE_ARCH}/alpine:3.12
```
Указание хранилищ для плагинов,баз данных,секретные ключи
```
VOLUME /var/www/app/data
VOLUME /var/www/app/plugins
VOLUME /etc/nginx/ssl
```
Открытие портов
```
EXPOSE 80 443
```
Установка зависимостей
```
RUN apk --no-cache --update add \
    openssl unzip nginx bash ca-certificates s6 curl ssmtp mailx php7 php7-phar php7-curl \
    php7-fpm php7-json php7-zlib php7-xml php7-dom php7-ctype php7-opcache php7-zip php7-iconv \
    php7-pdo php7-pdo_mysql php7-pdo_sqlite php7-pdo_pgsql php7-mbstring php7-session php7-bcmath \
    php7-gd php7-mcrypt php7-openssl php7-sockets php7-posix php7-ldap php7-simplexml && \
    rm -rf /var/www/localhost && \
    rm -f /etc/php7/php-fpm.d/www.conf
```
Добавление всего git-репозитория в контейнер, а также отдельно папки docker/
```
ADD . /var/www/app
ADD docker/ /
```
Удаление конфигурационного файла и папки docker /var/www/app/docker
```
RUN rm /var/www/app/config.php
RUN rm -rf /var/www/app/docker && echo $VERSION > /version.txt
```
Указание входной точки
```
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```