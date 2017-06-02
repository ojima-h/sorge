FROM ruby:2.4

RUN useradd -ms /bin/bash sorge

USER sorge
RUN mkdir -p /home/sorge/app
WORKDIR /home/sorge/app

CMD ["bundle", "exec", "rake"]
