FROM amazonlinux:latest

RUN yum -y --security update

RUN yum -y install \
  aws-cli \
  ImageMagick \
  util-linux

COPY /convert-worker.sh /app
 
WORKDIR /app

RUN chmod +x ./app/convert-worker.sh

ENTRYPOINT ["/app/convert-worker.sh"]