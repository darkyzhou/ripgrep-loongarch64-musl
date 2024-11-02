FROM loongarch64/debian

ARG RIPGREP_TAG="14.1.1"
ARG RUSTUP_VERSION="1.27.1"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y build-essential binutils git curl ca-certificates --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

ENV RUSTUP_VER=${RUSTUP_VERSION} \
    RUST_ARCH="loongarch64-unknown-linux-gnu" \
    CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

RUN curl "https://static.rust-lang.org/rustup/archive/${RUSTUP_VER}/${RUST_ARCH}/rustup-init" -o rustup-init && \
    chmod +x rustup-init && \
    ./rustup-init -y --default-toolchain stable --profile minimal --no-modify-path && \
    rm rustup-init && \
    ~/.cargo/bin/rustup target add loongarch64-unknown-linux-musl

ENV PATH=/root/.cargo/bin:$PREFIX/bin:$PATH \
    RUSTUP_HOME=/root/.rustup \
    CARGO_BUILD_TARGET=loongarch64-unknown-linux-musl \
    # build statically linked binary with musl
    RUSTFLAGS="-C target-feature=+crt-static -C default-linker-libraries=yes -C link-self-contained=yes -C debuginfo=none -C strip=symbols" \
    # ripgrep uses jemalloc when building with musl, and LoongArch64 uses 16K page size by default
    JEMALLOC_SYS_WITH_LG_PAGE=16

ADD prec2-version.patch /root/

RUN git clone --depth=1 --branch=${RIPGREP_TAG} https://github.com/BurntSushi/ripgrep /build && \
    cd /build && \
    git apply /root/prec2-version.patch && \
    cargo build -r --target loongarch64-unknown-linux-musl --features 'pcre2'
