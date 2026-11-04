FROM alpine:latest
ENV TZ=Asia/Tehran

RUN apk add --no-cache curl tar

# دانلود و نصب هسته تانل (Chisel)
RUN curl -s https://api.github.com/repos/jpillora/chisel/releases/latest \
    | grep browser_download_url | grep linux_amd64.gz \
    | cut -d '"' -f 4 | xargs curl -L -o chisel.gz \
    && gzip -d chisel.gz \
    && mv chisel /usr/local/bin/chisel \
    && chmod +x /usr/local/bin/chisel

# تنظیم پورت و رمز عبور تانل
ENV PORT=8080
ENV AUTH="admin:MySecretPassword123" 

# اجرای سرور با قابلیت SOCKS5
CMD chisel server --port $PORT --auth $AUTH --socks5
