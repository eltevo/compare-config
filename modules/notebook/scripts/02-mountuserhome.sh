# remount volumes in the proper folderstructure
mkdir -p /home/${NB_USER}
mount -o bind /mnt/.volumes/home/${NB_USER} /home/${NB_USER}
echo "Home mounted for ${NB_USER}"
mkdir -p /tmp/.empty

for target in share workdir report ; do
    echo -n -e "Placeholder for ${target}\t"
    TARGETDIR=/home/${NB_USER}/${target}
    mount -t tmpfs tmpfs -o size=1K ${TARGETDIR}
    chown ${NB_USER} ${TARGETDIR}
    chmod 500 ${TARGETDIR}
    touch ${TARGETDIR}/_DONT_WRITE_HERE_
    echo "ok"
done

#####FIXME: remove the rest
####CONF=/tmp/mount.conf
####
####if [ -f $CONF ]; then
####
####  NS=$(grep share $CONF -c)
####  TARGETDIR=/home/$NB_USER/share
####
####  if [ $NS -eq 1 ]; then
####    SOURCEDIR=$(grep share $CONF | cut -f2 -d:)
####    mount -o bind $SOURCEDIR $TARGETDIR 
####  elif [ $NS -gt 1 ]; then
####    mount -t tmpfs tmpfs -o size=1K $TARGETDIR
####    for s in $(grep share $CONF | cut -f2 -d:); do
####       t=$TARGETDIR/$(basename $s)
####       mkdir $t
####       mount -o bind $s $t 
####    done
####  fi
####
####
####  NS=$(grep workdir $CONF -c)
####  TARGETDIR=/home/$NB_USER/workdir
####
####  if [ $NS -eq 1 ]; then
####    SOURCEDIR=$(grep workdir $CONF | cut -f2 -d:)
####    mount -o bind $SOURCEDIR $TARGETDIR
####  elif [ $NS -gt 1 ]; then
####    mount -t tmpfs tmpfs -o size=1K $TARGETDIR
####    for s in $(grep workdir $CONF | cut -f2 -d:); do
####       t=$TARGETDIR/$(basename $s)
####       mkdir $t
####       mount -o bind $s $t
####    done
####  fi
####
####  TARGETDIR=/home/$NB_USER/report
####  mount -t tmpfs tmpfs -o size=1K $TARGETDIR
####  chown $NB_USER $TARGETDIR
####  chmod 500 $TARGETDIR
####  touch $TARGETDIR/_DONT_WRITE_HERE_
####
####fi

# hide volumes from the user
mount -o bind /tmp/.empty /mnt/.volumes
echo "Mount folder is hidden"
