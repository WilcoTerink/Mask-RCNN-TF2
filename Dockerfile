# Use the base image with Jupyter and TensorFlow (GPU)
# FROM tensorflow/tensorflow:latest-gpu
# FROM tensorflow/tensorflow
FROM nvidia/cuda:11.2.2-cudnn8-runtime-ubuntu20.04
# FROM ubuntu:20.04
# FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install system dependencies, including GDAL
RUN apt-get update && apt-get install -y \
    wget bzip2 ca-certificates libssl-dev libffi-dev libgl1 openssh-server bash sudo \
    gdal-bin libgdal-dev && \
    rm -rf /var/lib/apt/lists/*

### For AMD64:
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# Add Conda to PATH so it can be used in subsequent commands
ENV PATH="/opt/conda/bin:$PATH"

# Create a new Conda environment named 'myenv' and install Python 3.8
RUN conda create -n myenv python=3.7 -y

# Copy the requirements.txt to the container
COPY requirements.txt /app/requirements.txt


# Install GDAL inside the Conda environment
RUN /bin/bash -c "source /opt/conda/etc/profile.d/conda.sh && conda activate myenv && conda install -c conda-forge gdal==3.2.2 -y && pip install -r /app/requirements.txt"

# Install ipykernel and register the environment with Jupyter
RUN /bin/bash -c "source /opt/conda/etc/profile.d/conda.sh && conda activate myenv && python -m ipykernel install --user --name=myenv --display-name 'Python (myenv)'"

# Set up SSH server and start it
RUN mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd

# Allow root login over SSH (be cautious with this in production environments)
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Expose necessary ports for SSH (22) and Jupyter (8888)
EXPOSE 22 8888 6006

# Ensure the 'myenv' environment is activated when a shell is opened
RUN echo "source /opt/conda/etc/profile.d/conda.sh && conda activate myenv" >> ~/.bashrc

WORKDIR /tutorials

## Start SSH and Jupyter using bash shell
CMD /bin/bash -c "service ssh start && source /opt/conda/etc/profile.d/conda.sh && conda activate myenv && jupyter notebook --ip=0.0.0.0 --no-browser --allow-root --NotebookApp.token=''"