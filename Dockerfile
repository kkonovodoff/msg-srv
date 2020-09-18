FROM rust:1.45.2

WORKDIR /usr/src/server
EXPOSE 3333
COPY . .

RUN cargo install --path .

CMD ["server"]