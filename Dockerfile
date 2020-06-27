FROM alpine:latest
RUN apk update && apk add curl bash coreutils

# Get kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# Run Cleanup
COPY cleanup-istio-webhook.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/cleanup-istio-webhook.sh
CMD ["cleanup-istio-webhook.sh"]
