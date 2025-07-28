FROM python:3.12.3-slim
WORKDIR /usr/src/app
RUN apt-get update -y
RUN apt-get install pkg-config -y
RUN apt-get install -y python3-dev build-essential
RUN apt-get install -y default-libmysqlclient-dev
COPY requirements.txt .
RUN python -m pip install -r requirements.txt --no-cache-dir
COPY . .
EXPOSE 8000