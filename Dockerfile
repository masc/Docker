FROM socialcars/docker:sumo

ENV SUMO_HOME /opt/sumo
ENV PATH /usr/local/bin:$HOME/.local/bin/:$PATH

# Install dependencies (system packages)
RUN sudo apt-get install doxygen graphviz libhdf5-dev pandoc tk-dev python-tk

# install colmto related dependencies
WORKDIR /home/circleci
RUN pip3 install --user pylint radon codecov doxypy nose
RUN pip3 install -r https://raw.githubusercontent.com/socialcars/colmto/master/requirements.txt --user

# install TeX

RUN go get -u github.com/tcnksm/ghr

RUN mkdir -p /tmp/tex && curl -L http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | tar xz --strip 1 -C /tmp/tex;

RUN echo "selected_scheme scheme-small\\nTEXDIR /usr/local/texlive/\\nTEXMFLOCAL /usr/local/texlive/texmf-local\\nTEXMFSYSCONFIG /usr/local/texlive/texmf-config\\nTEXMFSYSVAR /usr/local/texlive/texmf-var\\nTEXMFHOME /home/circleci/texmf\nTEXMFCONFIG /home/circleci/.texlive/texmf-config\\nTEXMFVAR /home/circleci/.texlive/texmf-var\\nbinary_x86_64-linux 1\\ninstopt_adjustpath 1\\ninstopt_adjustrepo 1\\ninstopt_letter 1\\ninstopt_portable 0\\ninstopt_write18_restricted 1\\ntlpdbopt_autobackup 1\\ntlpdbopt_backupdir tlpkg/backups\\ntlpdbopt_create_formats 1\\ntlpdbopt_desktop_integration 0\\ntlpdbopt_file_assocs 1\\ntlpdbopt_generate_updmap 0\\ntlpdbopt_install_docfiles 0\\ntlpdbopt_install_srcfiles 0\\ntlpdbopt_post_code 1\\ntlpdbopt_sys_bin /tmp\\ntlpdbopt_sys_info /tmp\\ntlpdbopt_sys_man /tmp\\ntlpdbopt_w32_multi_user 1\\n" > /tmp/texinstall.profile; sudo /tmp/tex/install-tl -profile /tmp/texinstall.profile;
RUN echo "\$pdf_mode  = 1;\\n\$bibtex_use = 2;\\n\$pdflatex  = 'pdflatex -halt-on-error -file-line-error -shell-escape -interaction=nonstopmode -synctex=1 %O %S';\\n\$clean_ext = 'synctex.gz synctex.gz(busy) run.xml xmpi acn acr alg glsdefs vrb bbl ist glg glo gls ist lol log 1 dpth auxlock %R-figure*.* %R-blx.bib snm nav dvi xmpi tdo';\\n\\nadd_cus_dep('glo', 'gls', 0, 'makeglossaries');\\nadd_cus_dep('acn', 'acr', 0, 'makeglossaries');\\nadd_cus_dep('mp', '1', 0, 'mpost');\\n\\nsub makeglossaries {\\nreturn system('makeglossaries', \$_[0]);\\n}\\n\\nsub mpost {\\nmy (\$name, \$path) = fileparse( \$_[0] );\\nmy \$return = system('mpost', \$_[0]);\\nif ( (\$path ne '') && (\$path ne '.\\\\\\\\') && (\$path ne './') ) {\\nforeach ( '\$name.1', '\$name.log' ) { move \$_, \$path; }\\n}\\nreturn \$return;\\n}\\n" > /home/circleci/.latexmkrc

# --- machine configuration section --------------
ENV TEXMFHOME /home/circleci/texmf
ENV PATH /usr/local/texlive/bin/x86_64-linux:/home/circleci/go/bin:$PATH
RUN sudo /usr/local/texlive/bin/x86_64-linux/tlmgr install latexmk
RUN sudo /usr/local/texlive/bin/x86_64-linux/tlmgr update --self --all --reinstall-forcibly-removed

RUN ls /usr/local/texlive/bin/x86_64-linux/