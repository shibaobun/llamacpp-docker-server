ARG UBUNTU_VERSION=22.04
ARG CONTAINER_PORT=8200

FROM ubuntu:${UBUNTU_VERSION}

RUN apt-get update && \
    apt-get install -y build-essential wget git

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb

RUN apt-get update && \
    apt-get install -y cuda-toolkit nvidia-gds

WORKDIR /

# Clone ggml repository
RUN git clone https://github.com/ggerganov/llama.cpp

# Set working directory
WORKDIR /llama.cpp

# Build ggml and examples
ENV PATH="/usr/local/cuda/bin${PATH:+:${PATH}}"
# RUN find / -name "libcuda.so" && wait 30
RUN ls /usr/local/cuda/lib64
RUN ls /usr/local/cuda/targets/x86_64-linux/lib/stubs
ENV LIBRARY_PATH="/usr/local/cuda/targets/x86_64-linux/lib/stubs:/usr/local/cuda/lib64\${LIBRARY_PATH:+:${LIBRARY_PATH}}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/targets/x86_64-linux/lib/stubs:/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
RUN LLAMA_BUILD_SERVER=1 LLAMA_CUBLAS=1 make

# Now ./server executable created. Pass it into Runtime image
RUN cp server /usr/local/bin/llamacpp-server
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Set the environment variables
ENV CONTAINER_PORT=${CONTAINER_PORT}
ENV SERVER_HOST=0.0.0.0

WORKDIR /usr/local/bin

RUN chmod +x entrypoint.sh

# Set the entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Expose the specified port
EXPOSE ${CONTAINER_PORT}
