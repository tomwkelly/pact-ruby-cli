FROM alpine:3.14

LABEL maintainer="Beth Skurrie <beth@bethesque.com>"

ENV NOKOGIRI_USE_SYSTEM_LIBRARIES=1
ENV BUNDLE_SILENCE_ROOT_WARNING=1

ADD docker/gemrc /root/.gemrc
ADD docker/pact /usr/local/bin/pact

# Update from rubygems 2.7.6 to 3.0.3 for security reasons
# Verify with gem -v
# TODO: Remove this when it is no longer needed
# For some reason this line changes the image size from 60 to 80 MB?!?

RUN apk update \
  && apk add "ruby=2.7.5-r0" \
             "ruby-bigdecimal=2.7.5-r0" \
             "ruby-bundler=2.2.20-r0" \
             "ruby-io-console=2.7.5-r0" \
             "ca-certificates=20191127-r5" \
             "libressl=3.3.3-r0" \
             "less=581-r1" \
             "git=2.32.0-r0" \
  && apk add --virtual "build-dependencies" \
             build-base=0.5-r2 \
             ruby-dev=2.7.5-r0 \
             libressl-dev=3.3.3-r0 \
             ruby-rdoc=2.7.5-r0 \
  \
  && bundler -v \
  && bundle config build.nokogiri --use-system-libraries \
  && bundle config git.allow_insecure true \
  && gem update --system \
  && gem install json -v "~>2.3" \
  && gem cleanup \
  && apk del build-dependencies \
  && rm -rf /usr/lib/ruby/gems/*/cache/* \
            /var/cache/apk/* \
            /tmp/* \
            /var/tmp/*

ENV HOME /pact
ENV DOCKER true
ENV BUNDLE_GEMFILE=$HOME/Gemfile
WORKDIR $HOME

ADD pact-cli.gemspec .
ADD Gemfile .
ADD Gemfile.lock .
ADD lib/pact/cli/version.rb ./lib/pact/cli/version.rb
RUN bundle config set without 'test development' \
    bundle config set deployment 'true' \
      && bundle install \
      && find /usr/lib/ruby/gems/2.7.0/gems -name Gemfile.lock -maxdepth 2 -delete
ADD docker/entrypoint.sh $HOME/entrypoint.sh
ADD bin ./bin
ADD lib ./lib
ADD example/pacts ./example/pacts

ENTRYPOINT ["/pact/entrypoint.sh"]
