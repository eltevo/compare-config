for module in data_courses data_garbage data_git data_homes  data_reports  data_share base nginx ldap proxy gitea hydra report-nginx hub impersonator #notebook 
do
        bash kooplex.sh build $module
done

bash kooplex.sh start nginx 
bash kooplex.sh start ldap 
sleep 10
bash kooplex.sh init ldap 
bash kooplex.sh start proxy 
bash kooplex.sh start hydra
sleep 10
bash kooplex.sh init hydra
bash kooplex.sh install-nginx hydra
# Now Bonfire consent code need to be installed
# Visit $OUTERHOST/consent/install
# Settings in Bonfire consent code
# login as admin
# in settings/security change login method to username only

bash kooplex.sh start gitea 
bash kooplex.sh build seafile
bash kooplex.sh start seafile

# Wait until seafile container started
sleep 40
bash kooplex.sh admin seafile


# REGISTER TO HYDRA
for module in hydra gitea seafile hub 
do
        bash kooplex.sh install-hydra $module
done

# Restart seafile container

bash kooplex.sh start report-nginx

bash kooplex.sh start hub
sleep 10
bash kooplex.sh init hub

# REGISTER TO NGINX
for module in proxy gitea seafile report-nginx hub
do
        bash kooplex.sh install-nginx $module
done

bash kooplex.sh build impersonator 
bash kooplex.sh start impersonator 

# We need at least one notebook image
bash kooplex.sh build notebook basic

# Things that need some improvement from the kooplx-hub code side
docker restart ${PREFIX}-hub 
docker exec -it ${PREFIX}-hub bash -c "cd kooplexhub/kooplexhub/; python3 manage.py updatemodel"

docker restart ${PREFIX}-seafile
docker restart ${PREFIX}-hydra 
docker restart ${PREFIX}-nginx


# To enable seafile 
# login to $OUTERHOST/admin
# set FS server
# $OUTERHOST/seafile

# Stopping and removing everything
for module in gitea seafile hydra report-nginx impersonator nginx ldap proxy hub #notebook 
do
        bash  kooplex.sh stop $module
done

for module in gitea seafile hydra report-nginx impersonator nginx ldap proxy hub #notebook 
do
        bash  kooplex.sh remove $module
done

for module in gitea seafile hydra report-nginx impersonator nginx ldap proxy hub notebook data_courses data_garbage data_git data_homes  data_reports  data_share 
do
        bash  kooplex.sh purge $module
done

for module in gitea seafile hydra report-nginx impersonator nginx ldap proxy hub notebook data_courses data_garbage data_git data_homes  data_reports  data_share
do
        bash kooplex.sh clean $module
done


# Apply patches manually for services (check Readme.md in module directories)
# * seafile
# * gitea
# 
# SETUP services in hub admin
# * Add VC repositories
# * Add
# 
# * Add notebook images:
#   * build them in kooplex-config
#   * enter to the hub container and manage.py updatemodel


