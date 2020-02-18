#!/bin/bash


MODULE_NAME=notebook
RF=$BUILDDIR/${MODULE_NAME}

case $VERB in
  "build")
    echo "Building image $PREFIX-${MODULE_NAME} $EXTRA"


     mkdir -p $RF
     
#     for imagedir in ./image-*
     for i in $EXTRA
     do
        imagedir="./image-"$i
        mkdir -p $RF/$imagedir
        full_imgname=${PREFIX}-${MODULE_NAME}-$imagedir

	[ -e $imagedir/conda-requirements.txt ] &&  cp -p $imagedir/conda-requirements.txt $RF/$imagedir/conda-requirements.txt
        sed -e "s/##PREFIX##/${PREFIX}/" scripts/start-notebook.sh-template > $RF/$imagedir/start-notebook.sh
        sed -e "s/##OUTERHOSTNAME##/${OUTERHOSTNAME}/"\
	    -e "s/##REWRITEPROTO##/${REWRITEPROTO}/" scripts/rstudio-login.html-template > $RF/$imagedir/rstudio-login.html
        sed -e "s/##OUTERHOST##/${OUTERHOST}/"\
	    -e "s/##REWRITEPROTO##/${REWRITEPROTO}/" scripts/preview-bokeh.sh-template > $RF/$imagedir/preview-bokeh.sh
        sed -e "s/##OUTERHOST##/${OUTERHOST}/"\
	    -e "s/##REWRITEPROTO##/${REWRITEPROTO}/" scripts/preview-nb-api.sh-template > $RF/$imagedir/preview-nb-api.sh

	mkdir -p ${RF}/$imagedir/init
	sed -e "s,##FUNCTIONAL_VOLUME_MOUNT_POINT##,$FUNCTIONAL_VOLUME_MOUNT_POINT," scripts/11_init_bashrcs-template > $RF/$imagedir/init/11_init_bashrcs
        sed -e "s,##FUNCTIONAL_VOLUME_MOUNT_POINT##,$FUNCTIONAL_VOLUME_MOUNT_POINT," scripts/12_conda_envs-template > $RF/$imagedir/init/12_conda_envs
        cp scripts/{kooplex-logo.png,jupyter_notebook_config.py,jupyter_report_config.py,manage_mount.sh,jupyter-notebook-kooplex} ${RF}/$imagedir/
	cp scripts/{0?-*.sh,9?-*.sh} ${RF}/$imagedir/init
        cp scripts/{entrypoint-rstudio.sh,rstudio-user-settings,rstudio-nginx.conf}  ${RF}/$imagedir/
        cp DockerFile-pieces/* ${RF}/$imagedir


	# copy necessary files from other module builds
	for nec_file in `ls $BUILDDIR/*/$NOTEBOOK_DOCKER_EXTRA/*`
	do
		cp $nec_file ${RF}/$imagedir/
	done

#####
  printf "$(ldap_ldapconfig)\n\n" > ${RF}/$imagedir/ldap.conf
  printf "$(ldap_nsswitchconfig)\n\n" > ${RF}/$imagedir/nsswitch.conf
  printf "$(ldap_nslcdconfig)\n\n" > ${RF}/$imagedir/nslcd.conf
  chown root ${RF}/$imagedir/nslcd.conf
  chmod 0600 ${RF}/$imagedir/nslcd.conf

######NOTE: jupyter_report_config.py not in the image

        docfile=${imagedir}/Dockerfile
        imgname=${imagedir#*image-}


        echo "FROM ${MODULE_NAME}-${imgname}-base" > ${RF}/$docfile-final

        if [ ${IMAGE_REPOSITORY_URL} ]; then
	     echo "Using base image ${MODULE_NAME}-${imgname}-base form pulled source"
             docker $DOCKERARGS pull $IMAGE_REPOSITORY_URL"/"${MODULE_NAME}-$imgname-base
	     echo "Image PULLED from repository"
             docker tag $IMAGE_REPOSITORY_URL"/"${MODULE_NAME}-$imgname-base ${PREFIX}-${MODULE_NAME}-$imgname-base
	     echo "Image TAGGED from repository"
        else
             sed -e "s/##PREFIX##/${PREFIX}/" $imagedir/Dockerfile-template > $RF/$imagedir/Dockerfile
             docker $DOCKERARGS build -f ${RF}/$docfile -t ${PREFIX}-${MODULE_NAME}-${imgname}-base ${RF}/$imagedir
             docker tag  ${PREFIX}-${MODULE_NAME}-$imgname-base "localhost:5000/"${MODULE_NAME}-$imgname-base
             docker push "localhost:5000/"${MODULE_NAME}-$imgname-base
        fi

        echo "FROM ${PREFIX}-${MODULE_NAME}-${imgname}-base" > ${RF}/$docfile-final

     	echo "Building image from $docfile"
	for docker_piece in `ls ${RF}/${imagedir}/*-Docker-piece`
	do
		cat $docker_piece >> ${RF}/$docfile-final
	done

#        cat ${RF}/${imagedir}/9-Endpiece.docker >> ${RF}/$docfile
        docker $DOCKERARGS build --no-cache -f ${RF}/$docfile-final -t ${PREFIX}-${MODULE_NAME}-${imgname} ${RF}/$imagedir

       
     done
  ;;
    
  "install")

      echo "Installing containers of ${PREFIX}-${MODULE_NAME}"

      sed -e "s/##PREFIX##/$PREFIX/" \
	  -e "s/##OUTERHOST##/${OUTERHOST}/" etc/nginx-${MODULE_NAME}-conf-template | curl -u ${NGINX_API_USER}:${NGINX_API_PW}\
	        ${NGINX_IP}:5000/api/new/${MODULE_NAME} -H "Content-Type: text/plain" -X POST --data-binary @-
    
  ;;
  "start")
    # TODO: we have a single notebook server now, perhaps there will
    # one per user later or more if we scale out
    # echo "Starting notebook $PROJECT-notebook [$NOTEBOOKIP]"
    # docker $DOCKERARGS start $PROJECT-notebook
  ;;
  "init")
    
  ;;
  "stop")
    echo "Stopping ${MODULE_NAME} $PROJECT-${MODULE_NAME} [$NOTEBOOKIP]"
#    docker $DOCKERARGS stop $PROJECT-notebook
  ;;
  "uninstall")
      echo "Uninstalling containers of ${PREFIX}-${MODULE_NAME}"
      curl -u ${NGINX_API_USER}:${NGINX_API_PW} ${NGINX_IP}:5000/api/remove/${MODULE_NAME}

  ;;
  "remove")
    echo "Removing ${MODULE_NAME} $PROJECT-${MODULE_NAME} [$NOTEBOOKIP]"
#    docker $DOCKERARGS rm $PROJECT-notebook
  ;;
  "purge")
    echo "Purging ${MODULE_NAME} $PROJECT-${MODULE_NAME} [$NOTEBOOKIP]"
    rm -R $SRV/${MODULE_NAME}
  ;;
  "clean")
    echo "Cleaning base image $PREFIX-${MODULE_NAME}"
#    docker $DOCKERARGS rmi $PREFIX-notebook
#FIXME: hard coded
#    docker $DOCKERARGS images |grep kooplex-notebook| awk '{print $1}' | xargs -n  1 docker $DOCKERARGS rmi
  ;;
esac
