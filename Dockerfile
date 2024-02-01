FROM dart:latest AS build
WORKDIR /app
COPY . .
# RUN  dart pub get
# RUN dart compile exe bin/main.dart -o bin/main
# FROM debian:buster-slim
# COPY --from=build /app/bin/main /app/bin/main
# COPY --from=build /app/config /app/config
# COPY --from=build /runtime/etc /etc
# COPY --from=build /runtime/lib /lib
# # COPY --from=build /runtime/lib64 /lib64
# COPY --from=build /runtime/usr /usr
EXPOSE 8888
CMD dart run bin/main.dart
