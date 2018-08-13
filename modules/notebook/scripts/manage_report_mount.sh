# remount volumes in the proper folderstructure
REPORTDIR=/home/$NB_USER/report
EMPTYDIR=/tmp/.empty
VOLDIR=/mnt/.volumes

CONF=/tmp/mount_report.conf

if [ -f $CONF ]; then

  umount $VOLDIR
  echo Showing $VOLDIR >&2

  while IFS=':' read -r task dir1 dir2 <&3 ; do
    if [ $task = '-' ] ; then
      udir=$REPORTDIR/$dir1
      if [ -d $udir ] ; then
        umount $udir
        echo Umounted $udir >&2
        rmdir $udir
        echo Removed $udir >&2
      fi
    elif [ $task = '+' ] ; then
      sdir=$VOLDIR/$dir1
      tdir=$REPORTDIR/$dir2
      if [ ! -d $sdir ] ; then
        echo "Source $sdir does not exist" >&2
        continue
      fi
      if [ -d $tdir ] ; then
        echo Exists $tdir >&2
        umount $tdir
        echo Umounted $tdir >&2
      else
        mkdir -p $tdir
        echo Created $tdir >&2
      fi
      mount -o bind $sdir $tdir
      echo Mounted $tdir >&2
    fi
  done 3< $CONF

  # hide volumes from the user
  mount -o bind $EMPTYDIR $VOLDIR
  echo Hid $VOLDIR >&2
fi
