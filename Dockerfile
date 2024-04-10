# Rubyのバージョンを指定
ARG RUBY_VERSION=3.3.0
FROM ruby:$RUBY_VERSION-slim

WORKDIR /gratiwave

# 環境変数の設定
ENV RAILS_ENV="production" \
    BUNDLE_PATH="/usr/local/bundle" \
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo \
    PATH="/gratiwave/bin:${PATH}"

# 依存関係のインストール。Node.jsとYarnの安定版をインストールします。
RUN apt-get update -qq && \
    apt-get install -y ca-certificates curl gnupg build-essential libpq-dev libssl-dev && \
    curl -fsSL https://deb.nodesource.com/setup_21.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# GemfileとGemfile.lockをコピーし、Bundlerと依存関係をインストール
COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.5.6 && \
    bundle install --without development test --retry 3 --jobs 4

# Yarnの依存関係をインストール
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# アプリケーションのソースコードをコピー
COPY . .

# アセットプリコンパイル。cssbundling-railsとjsbundling-railsのビルドコマンドを使用
RUN  bin/rails assets:precompile

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
