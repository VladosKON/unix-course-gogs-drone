# Описание Dockerfile для Gogs
Данный файл брался c оффициального git репозитория проекта Gogs
Часть образа binarybuilder базируется на golang:alpine3.11
```
FROM golang:alpine3.11 AS binarybuilder
```
Установка зависимостей и нужных приложений
```
RUN apk --no-cache --no-progress add --virtual \
  build-deps \
  build-base \
  git \
  linux-pam-dev
```
Рабочий каталог внутри контейнера
```
WORKDIR /gogs.io/gogs
```
Добавление всего git-репозитория в контейнер
```
COPY . .
```
Build приложения в контейнере
```
RUN make build TAGS="cert pam"
```
Образ базируется на alpine:3.11
```
FROM alpine:3.11
```
Добавление git-репозитория в контейнер в папку
```
ADD https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64 /usr/sbin/gosu
```
Создание запускаемого приложения, копирование списка репозиториев из http://dl-2.alpinelinux.org/alpine/edge/community/ в контейнер, установка зависимостей
```
RUN chmod +x /usr/sbin/gosu \
  && echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories \
  && apk --no-cache --no-progress add \
  bash \
  ca-certificates \
  curl \
  git \
  linux-pam \
  openssh \
  s6 \
  shadow \
  socat \
  tzdata \
  rsync
```
Задание переменной окружения GOGS_CUSTOM
```
ENV GOGS_CUSTOM /data/gogs
```
Перенос файла nsswitch.conf в контейнер
```
COPY docker/nsswitch.conf /etc/nsswitch.conf
```
Рабочий каталог внутри контейнера 
```
WORKDIR /app/gogs
```
Копирование папки docker в контейнер
```
COPY docker ./docker
```
Копирование файлов из binarybuilder в папку в контейнере
```
COPY --from=binarybuilder /gogs.io/gogs/gogs .
```
Запуск исполняемого файла finalize.sh
```
RUN ./docker/finalize.sh
```
Указание хранилищ для баз данных и резервного копирования
```
VOLUME ["/data", "/backup"]
```
Открытие портов
```
EXPOSE 22 3000
```
Указание входной точки
```
ENTRYPOINT ["/app/gogs/docker/start.sh"]
```
Задание первоначальной команды для исполняемого контейнера
```
CMD ["/bin/s6-svscan", "/app/gogs/docker/s6/"]
```