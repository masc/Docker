FROM 1masc/sumo-docker

ENV SUMO_HOME /opt/sumo
ENV PATH /usr/local/bin:$PATH

# Install dependencies (system packages)
RUN sudo apt-get install doxygen graphviz libhdf5-dev pandoc tk-dev python-tk

# install colmto related dependencies
RUN pip3 install --user --prefix= pylint radon codecov doxypy nose
RUN pip3 install -r https://raw.githubusercontent.com/masc/colmto/master/requirements.txt --user --prefix=

CMD ["--help"]

