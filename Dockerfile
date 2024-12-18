FROM pegi3s/docker:20.04
LABEL maintainer="hlfernandez"

# INSTALL COMPI
ADD image-files/compi.tar.gz /

# ADD PIPELINE
ADD pipeline.xml pipeline.xml
ADD runner.xml runner.xml

ADD scripts /scripts
RUN chmod u+x /scripts/*
ADD tasks /tasks
RUN chmod u+x /tasks/*

ENTRYPOINT ["/compi", "run",  "-p", "/pipeline.xml"]
