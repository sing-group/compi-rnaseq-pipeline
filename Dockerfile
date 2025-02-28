FROM pegi3s/docker:20.04
LABEL maintainer="hlfernandez"

# INSTALL DEPENDENCIES
RUN apt update -y && \
    apt install python3-pip -y && \
    pip install pandas

# INSTALL COMPI
ADD image-files/compi.tar.gz /

# ADD PIPELINE
ADD pipeline.xml pipeline.xml
ADD runner.xml runner.xml

ADD resources/init-working-dir/init_working_dir.sh /usr/bin
RUN chmod u+x /usr/bin/init_working_dir.sh
ADD resources/init-working-dir /resources/init-working-dir

ADD scripts /scripts
RUN chmod u+x /scripts/*
ADD tasks /tasks
RUN chmod u+x /tasks/*

ENTRYPOINT ["/compi", "run",  "-p", "/pipeline.xml"]
