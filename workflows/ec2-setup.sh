# use ami-011b3ccf1bd6db744
sudo apt-get update && apt-get upgrade -y
sudo apt-get install -y r-base r-recommended r-base-dev python-pip libssl-dev libcurl4-openssl-dev dpkg-dev zlib1g-dev libffi-dev
sudo Rscript -e 'install.packages(c("devtools", "assertr", "getopt", "optparse"))'
sudo Rscript -e 'options(repos=c("https://sage-bionetworks.github.io/ran", "http://cran.fhcrc.org"));
install.packages("PythonEmbedInR")'
### delete after new synapser is released (late Jan 2019)
git clone https://github.com/Sage-Bionetworks/synapser.git
cd synapser/
export PYTHON_CLIENT_GITHUB_USERNAME=Sage-Bionetworks
export PYTHON_CLIENT_GITHUB_BRANCH=master
git checkout develop
R CMD build . --no-build-vignettes
sudo R CMD INSTALL synapser_0.0.0.tar.gz
cd ..
rm -rf synapser/
###
#sudo Rscript -e 'options(repos=c("https://sage-bionetworks.github.io/ran", "http://cran.fhcrc.org"));
#install.packages("synapser")'
sudo Rscript -e 'devtools::install_github("Sage-Bionetworks/neurolincsscoring", dependencies=FALSE)'
