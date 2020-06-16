FROM ruby:2.7.1-slim
ENV RUBYOPT -EUTF-8
ADD . /app
WORKDIR /app
RUN apt-get update -y && \
    apt-get install -y \
      libffi-dev \
      build-essential \
      libpq-dev && \
    bundle install
RUN ln -s /app/bs2ld /usr/bin
CMD ["bs2ld"]
