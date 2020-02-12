FROM singgroup/dewe:1.0
LABEL maintainer="hlfernandez"

# INSTALL COMPI
ADD image-files/compi.tar.gz /

# PLACE HERE YOUR DEPENDENCIES (SOFTWARE NEEDED BY YOUR PIPELINE)

RUN unzip -j /opt/DEWE/plugins_bin/rnaseq-app-aibench/rnaseq-app-core-1.0.1.jar scripts/ballgown/ballgown-differential-expression.R -d /opt

# ADD PIPELINE
ADD pipeline.xml pipeline.xml
ENTRYPOINT ["/compi", "run",  "-p", "/pipeline.xml"]
