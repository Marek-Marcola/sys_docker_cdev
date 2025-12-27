#!/bin/bash

VERSION_BIN="202512760061"

SN="${0##*/}"
ID="[$SN]"

PREFIX="is"
SUFFIX=""
REGP=""
DEBUG=0
BUILDKIT=0

DFILE=""
EFILE=""
INST=""
TYPE=""
FREG=""
FROM=""
REPO=""
VER=""
TAG=""
DATE=""
GZIP=1
SDIR="/dep/i"

WIDTH=80
KEEP=5
KEEPR=20

INSTALL=0
VERSION=0
PULL=0
BUILD=0
BUILDF=0
PUSH=0
SAVE=0
LOAD=0
SLIST=0
ARCH=0
LIST=0
HIST=0
CHAIN=0
FILES=0
INSPECT=0
PRUNE=0
PRUNE_TYPE=""
RUN=0
EXEC=0
DEL=0
DELR=0
HELP=0
QUIET=0

declare -a ARGS1
ARGS2=""
NA1=0
NA2=0

s=0

ls | grep -q Dockerfile
[[ $? -eq 0 ]] && REPO="$(basename $(pwd))"

while [ $# -gt 0 ]; do
  case $1 in
    --inst*|-inst*)
      INSTALL=1
      shift
      ;;
    --vers*|-vers*)
      VERSION=1
      shift
      ;;
    -P)
      PULL=1
      shift
      ;;
    -bpd)
      BUILDF=1
      BUILD=1
      CHAIN=1
      PUSH=1
      LIST=2
      DEL=$KEEP
      shift
      ;;
    -lpa)
      LOAD=1
      PUSH=1
      ARCH=1
      shift
      ;;
    -b)
      BUILDF=1
      BUILD=1
      CHAIN=1
      shift
      ;;
    -bf)
      BUILDF=1
      shift
      ;;
    -p)
      PUSH=1
      shift
      ;;
    -l)
      LIST=1
      shift
      ;;
    -lr)
      LIST=2
      shift
      ;;
    -H*)
      [[ "$1" != "-H" ]] && HIST=${1:2} || HIST=$WIDTH
      shift
      ;;
    -i)
      INSPECT=1
      shift
      ;;
    -ip)
      PRUNE=1
      PRUNE_TYPE="$2"
      shift; shift
      ;;
    -ic)
      CHAIN=1
      shift
      ;;
    -if)
      FILES=1
      QUIET=1
      shift
      ;;
    -is)
      SAVE=1
      SDIR="$2"
      shift; shift
      ;;
    -z)
      GZIP=1
      shift
      ;;
    -il)
      LOAD=1
      SDIR="$2"
      shift; shift
      ;;
    -ls)
      SLIST=1
      shift
      ;;
    -A)
      ARCH=1
      shift
      ;;
    -r)
      RUN=1
      shift
      ;;
    -rr)
      RUN=2
      shift
      ;;
    -rs)
      RUN=1
      ARGS2="bash -l"
      shift
      ;;
    -k)
      RUN=3
      shift
      ;;
    -e)
      EXEC=1
      shift
      ;;
    -dr*)
      [[ "$1" != "-dr" ]] && DELR=${1:3} || DELR=$KEEPR
      shift
      ;;
    -d*)
      [[ "$1" != "-d" ]] && DEL=${1:2} || DEL=$KEEP
      shift
      ;;
    -R)
      REPO="$2"
      shift; shift
      ;;
    -V)
      VER="$2"
      shift; shift
      ;;
    -T)
      TAGS="$TAGS $2"
      shift; shift
      ;;
    -t)
      DATE=$(echo -n $2|sed 's/^\(........\)\(....\)\(.*\)/\1 \2/')
      DATE=$(date -d "$DATE" +%s)
      shift; shift
      ;;
    -FR)
      FREG="$2"
      shift; shift
      ;;
    -F)
      FROM="$2"
      shift; shift
      ;;
    -D)
      DEBUG=1
      shift
      ;;
    -bk)
      BUILDKIT=1
      shift
      ;;
    -DF)
      DFILE=$2
      shift; shift
      ;;
    -I*)
      [[ "$1" != "-I" ]] && INST="${1:2}" || INST="-i"
      shift
      ;;
    -bt)
      TYPE="$2"
      shift; shift
      ;;
    -S*)
      [[ "$1" != "-S" ]] && SUFFIX="${1:2}" || SUFFIX=""
      shift
      ;;
    -na1)
      NA1=1
      shift
      ;;
    -na2)
      NA2=1
      shift
      ;;
    -h|-help|--help)
      HELP=1
      shift
      ;;
    -q)
      QUIET=1
      shift
      ;;
    --)
      shift
      ARGS2=$*
      break
      ;;
    *)
      ARGS1+=("$1")
      shift
      ;;
  esac
done

#
# stage: HELP
#
if [ $HELP -eq 1 ]; then
  echo "$SN -install                                                # install"
  echo "$SN -version                                                # version"
  echo "$SN -P  [-R repo] [-F from] [-FR reg]                       # pull, repo, from_image, from_reg"
  echo "$SN -b  [-R repo] [-V ver] [-T tags] [-t date]              # build, repo, version, tags, tag YYYYMMDDhhmm"
  echo "            [-FR reg] [-F from] [-D] [-bk]                      # from_reg, from_image, debug, BuildKit"
  echo "            [-DF dockerfile] [-I[inst]]                         # dockerfile, instance (default: inst=i)"
  echo "            [-bt type] [-S-suffix]                              # build type, suffix"
  echo "$SN -bf [-R repo]                                           # build from list, repo"
  echo "$SN -p  [-R repo] [-V ver] [-T tags] [-t date]              # push, repo, version, tags, tag YYYYMMDDhhmm"
  echo "$SN -r  [-R repo] [-V ver|tag] [args1] [-- args2]           # docker run prefix/repo:tag"
  echo "$SN -rr [-R repo] [-V ver|tag] [args1] [-- args2]           # docker run reg/prefix/repo:tag"
  echo "$SN -k  [-R repo] [-V ver|tag] [args1] [-- args2]           # k8s run reg/prefix/repo:tag"
  echo "$SN -e  [-R repo] [-V ver|tag] [args1]                      # docker exec in reg/prefix/repo:tag cdev-repo-xxxxx"
  echo "$SN -l  [-R repo]                                           # list prefix/repo"
  echo "$SN -lr [-R repo]                                           # list regs/prefix/repo"
  echo "$SN -dr[k] [-R repo]                                        # image delete regs/prefix/repo (default: k[eep]=$KEEPR)"
  echo "$SN -d[k]  [-R repo]                                        # image delete prefix/repo (default: k[eep]=$KEEP)"
  echo "$SN -H[w]  [-R repo]                                        # image history (default: w[idth]=$WIDTH)"
  echo "$SN -i                                                      # image inspect"
  echo "$SN -ic                                                     # image chain"
  echo "$SN -if                                                     # image files"
  echo "$SN -is dir  [-R repo] [-V ver] [-t date] [-S-suffix] [-z]  # image save, repo, version, YYYYMMDDhhmm, suffix, gzip"
  echo "$SN -il dir  [-p] [-A]                                      # image load (all from dir), push, archive"
  echo "$SN -il file [-R repo -V ver -t date [-S-suffix]] [-p] [-A] # image load, repo, version, YYYYMMDDhhmm, suffix, push, archive"
  echo "$SN -ip d|is|a                                              # image prune: dangling, is/*, all unused"
  echo "$SN -ls                                                     # spooler list"
  echo "$SN                                                         # info"
  echo ""
  echo "opts:"
  echo "  -q   quiet"
  echo "  -na1 clear args1"
  echo "  -na2 clear args2"
  echo "  -Sd  sdir ($SDIR)"
  echo ""
  echo "alias:"
  echo "  -rs  = -r -- bash -l"
  echo "  -bpd = -b -p -lr -bf -ic -d"
  echo "  -lpa = -il /dep/i -p -A"
  echo ""
  echo "env files: /usr/local/etc/cdev.env \$HOME/.cdev.env .cdev.env \$CDEVENV"
  echo "save name: is-repo-ver-date[-suffix].tar[.gz]"
  echo ""
  echo "note:"
  echo "  c -I-i"
  echo "  c -I-debian12 -S-debian12"
  echo "  c -bt debug -S-debug"
  exit 0
fi

#
# stage: CONFIG
#
for f in /usr/local/etc/cdev.env $HOME/.cdev.env .cdev.env $CDEVENV; do
  if [ -e $f ]; then
    [[ "$EFILE" != "" ]] && EFILE="$EFILE $f" || EFILE="$f"
    . ${f}
  fi
done

if [ "$RUN_OPT_CUSTOM1" != "" ]; then
  RUN_OPT_CUSTOM1=$(echo $RUN_OPT_CUSTOM1|xargs)
fi
if [ "$RUN_OPT_CUSTOM2" != "" ]; then
  RUN_OPT_CUSTOM2=$(echo $RUN_OPT_CUSTOM2|xargs)
fi

[[ "$NA1" = "1"  ]] && RUN_OPT_CUSTOM1=""
[[ "$NA2" = "1"  ]] && RUN_OPT_CUSTOM2=""
[[ "$DATE" = ""  ]] && DATE="$(date '+%s')"
[[ "$VER" != ""  ]] && TAGS="$VER.$(date -d @$DATE '+%Y%m%d%H%M') $TAGS"
[[ "$TAG" != ""  ]] && TAGS="$TAGS $TAG"
[[ "$FREG" != "" ]] && FROM="$FREG/$FROM"

TAGS=$(echo $TAGS|tr "," " ")

for t in $TAGS; do
  T="$T ${t}${SUFFIX}"
done

TAGS=$(echo $T)

if [ $DEBUG != 0 -o $BUILDKIT != 0 ]; then
  export DOCKER_BUILDKIT=1
  BUILD_OPT_DEBUG="--progress plain"
fi

if [ "$DFILE" != "" ]; then
  :
elif [ -f Dockerfile-${REPO}-${VER}${INST} ]; then
  DFILE=Dockerfile-${REPO}-${VER}${INST}
elif [ -f Dockerfile-${REPO}${INST} ]; then
  DFILE=Dockerfile-${REPO}${INST}
elif [ -f Dockerfile-${VER}${INST} ]; then
  DFILE=Dockerfile-${VER}${INST}
elif [ -f Dockerfile${INST} ]; then
  DFILE=Dockerfile${INST}
fi

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  [[ "$VERSION_ENV" != "" ]] && echo "cdev.env $VERSION_ENV"
  if [ $(type -t docker) ]; then
    set -ex
    docker --version
    { set +ex; } 2>/dev/null
  fi
  if [ $(type -t podman) ]; then
    set -ex
    podman --version
    { set +ex; } 2>/dev/null
  fi
  if [ $(type -t containerd) ]; then
    set -ex
    containerd --version
    { set +ex; } 2>/dev/null
  fi
  exit 0
fi

#
# stage: INSTALL
#
if [ $INSTALL -eq 1 ]; then
  if [ -f cdev.env ]; then
    for d in /usr/local/etc /pub/pkb/kb/data/999210-cdev/999210-000020_cdev_script /pub/pkb/pb/playbooks/999210-cdev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai cdev.env $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  if [ -f cdev.sh ]; then
    for d in /usr/local/bin /pub/pkb/kb/data/999210-cdev/999210-000020_cdev_script /pub/pkb/pb/playbooks/999210-cdev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai cdev.sh $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  exit 0
fi

#
# stage: INFO
#
if [ $QUIET -eq 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INFO"

  [[ -n $INFO ]] && echo "info   = ${INFO}"
  echo "cwd    = $(pwd -P)"
  echo "efile  = ${EFILE:-[none]}"
  echo "dfile  = ${DFILE:-[none]}"
  echo "inst   = ${INST:-[none]}"
  echo "from   = ${FROM:-[none]}"
  echo "prefix = ${PREFIX:-[none]}"
  echo "suffix = ${SUFFIX:-[none]}"
  echo "type   = ${TYPE:-[none]}"
  echo "repo   = ${REPO:-[none]}"
  echo "ver    = ${VER:-[none]}"
  echo "tags   = ${VER:-[none]}${SUFFIX} $TAGS"
  echo "regs   = ${REGISTRY_HOST:-[none]}"
  echo "regp   = ${REGP:-[none]}"

  if [ "$REGISTRY_HOST" = "" -o "$REPO" = "" ]; then
    regi="[none]"
  else
    regi=$(echo $REGISTRY_HOST|awk '{print $1}')
    [[ "$REGP" != "" ]] && regi=${regi}/${REGP}/${REPO} || regi=${regi}/${REPO}
    [[ "$VER" = "" ]] && regi=${regi}:latest || regi=${regi}:${VER}${SUFFIX}
  fi
  echo "regi   = $regi"
  echo "save   = ${PREFIX}-${REPO}-${VER}-$(date -d @$DATE '+%Y%m%d%H%M')${SUFFIX}.tar"

  echo "k8s    = ${KUBECONFIG:-[none]}"

  if [ "${ARGS1[*]}" != "" -o "$RUN_OPT_CUSTOM1" != "" ]; then
    echo "args1  = $RUN_OPT_CUSTOM1 ${ARGS1[*]}"
  else
    echo "args1  = [none]"
  fi
  if [ "$ARGS2" != "" -o "$RUN_OPT_CUSTOM2" != "" ]; then
    echo "args2  = $RUN_OPT_CUSTOM2 $ARGS2"
  else
    echo "args2  = [none]"
  fi

  if [ "$DOCS" != "" ]; then
    echo -n "docs   = "
    echo "$DOCS" | sed 's/\!\!/\n/g' | sed '2,$ s/^/         /'
  fi
fi

#
# stage: LOAD
#
if [ $LOAD -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: LOAD"

  if [ ! -f "$SDIR" -a ! -d "$SDIR" ]; then
    echo "$ID: error: access: $SDIR"
    exit 1
  fi

  if [ -d "$SDIR" ]; then
    if [ $PUSH -ne 0 ]; then
      P="-p -lr"
    fi
    if [ $ARCH -ne 0 ]; then
      A="-A"
    fi

    set -ex
    cd $SDIR
    tree --noreport -F -h -C -L 1 $SDIR
    { set +ex; } 2>/dev/null
    echo

    ls is-*.tar.gz 2>/dev/null | sort | \
    while read I; do
      set -ex
      gunzip $I 2>&1 | sed 's/^/  /'
      { set +ex; } 2>/dev/null
    done

    ls is-*.tar 2>/dev/null | sort | \
    while read I; do
      R=$(echo $I|sed -E -n 's/^is-([a-zA-Z-].*)-([0-9a-zA-Z.].*)-([0-9]{12}).*/\1/p')
      V=$(echo $I|sed -E -n 's/^is-([a-zA-Z-].*)-([0-9a-zA-Z.].*)-([0-9]{12}).*/\2/p')
      t=$(echo $I|sed -E -n 's/^is-([a-zA-Z-].*)-([0-9a-zA-Z.].*)-([0-9]{12}).*/\3/p')
      S=$(echo $I|sed -E -n 's/^(.*)-([0-9]{12})-(.*).tar/\3/p')
      S=${S:+-S-}$S
      set -ex
      cdev.sh -q -il $SDIR/$I -R $R -V $V -t $t $S -ic $P $A 2>&1 | sed 's/^/  /'
      { set +ex; } 2>/dev/null
      echo
    done

    exit 0
  fi

  if [ -f "$SDIR" ]; then
    set -ex
    docker load -i $SDIR
    { set +ex; } 2>/dev/null

    if [ "$REPO" != "" ]; then
      echo
      D="$(date -d @$DATE '+%Y%m%d%H%M')"
      for t in ${VER}${SUFFIX} $TAGS; do
        TSRC=$PREFIX/$REPO:$VER.${D}${SUFFIX}
        TDST=$PREFIX/$REPO:$t
        if [ "$TSRC" != "$TDST" ]; then
          set -ex
          docker image tag $TSRC $TDST
          { set +ex; } 2>/dev/null
        fi
      done
    fi
    if [ $ARCH -ne 0 ]; then
      if [ -d archive ]; then
        echo
        set -ex
        mv -fv $SDIR archive/
        { set +ex; } 2>/dev/null
      fi
    fi
  fi
fi

#
# stage: SPOOLER-LIST
#
if [ $SLIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: SPOOLER-LIST"

  if [ ! -d $SDIR ]; then
    echo "$ID: error: no spooler dir: $SDIR"
    exit 1
  fi

  set -ex
  cd $SDIR
  tree --noreport -F -h -C -L 1 $SDIR
  { set +ex; } 2>/dev/null
fi

#
# stage: PULL
#
if [ $PULL -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PULL"

  set -ex
  docker image pull $FROM
  { set +ex; } 2>/dev/null
fi

#
# stage: BUILD
#
if [ $BUILD -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BUILD"

  if [ "$REPO" = "" -o "$VER" = "" -o "$DFILE" = ""  ]; then
    echo "$ID: error: require dfile,repo,ver"
    exit 1
  fi

  D="$(date -d @$DATE '+%Y-%m-%d_%H:%M:%S')"
  HR="$(getent hosts repo | awk '{print $1}')"
  [[ "$HR" != "" ]] && BUILD_OPT_ADD_HOST="--add-host=repo:$HR"
  [[ "$FROM" != "" ]] && BUILD_OPT_ADD_ARG="--build-arg FROM="$FROM""

  if [ "$FREG" != "" ]; then
    set -ex
    docker image pull -q $FROM
    { set +ex; } 2>/dev/null
  fi

  set -ex
  time docker image build \
    --build-arg DATE="$D" \
    --build-arg TYPE="$TYPE" \
    --build-arg REPO="$REPO" \
    --build-arg VER="$VER" \
    --tag $PREFIX/$REPO:${VER}${SUFFIX} \
    --file $DFILE \
    --force-rm \
    $BUILD_OPT_ADD_HOST \
    $BUILD_OPT_ADD_ARG \
    $BUILD_OPT_CUSTOM \
    $BUILD_OPT_DEBUG \
    .
  { set +ex; } 2>/dev/null

  echo
  for t in $TAGS; do
    set -ex
    docker image tag $PREFIX/$REPO:${VER}${SUFFIX} $PREFIX/$REPO:$t
    { set +ex; } 2>/dev/null
  done
fi

#
# stage: PUSH
#
if [ $PUSH -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PUSH"

  if [ "$REPO" = "" -o "$VER" = "" -o "$REGISTRY_HOST" = ""  ]; then
    echo "$ID: error: require repo,ver,reg"
    exit 1
  fi

  for r in $REGISTRY_HOST; do
    REG=$(echo $r|sed -e 's#^http://##' -e 's#^https://##')
    [[ "$REGP" != "" ]] && REG=${REG}/${REGP}
    for t in ${VER}${SUFFIX} $TAGS; do
      set -ex
      docker image tag  $PREFIX/$REPO:${VER}${SUFFIX} $REG/$REPO:$t
      docker image push $REG/$REPO:$t -q
      docker image rm   $REG/$REPO:$t
      { set +ex; } 2>/dev/null
    done
  done
fi

#
# stage: SAVE
#
if [ $SAVE -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: SAVE"

  if [ "$REPO" = "" -o "$VER" = "" ]; then
    echo "$ID: error: require repo,ver"
    exit 1
  fi
  if [ ! -d "$SDIR" ]; then
    echo "$ID: error: access: $SDIR"
    exit 1
  fi

  T=$(date -d @$DATE '+%Y%m%d%H%M')

  set -ex
  docker save -o $SDIR/$PREFIX-$REPO-$VER-${T}${SUFFIX}.tar $PREFIX/$REPO:$VER.${T}${SUFFIX}
  { set +ex; } 2>/dev/null

  if [ $GZIP -ne 0 ]; then
    set -ex
    gzip $SDIR/$PREFIX-$REPO-$VER-${T}${SUFFIX}.tar
    chmod a+r $SDIR/$PREFIX-$REPO-$VER-${T}${SUFFIX}.tar.gz
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: LIST
#
if [ $LIST -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: LIST"

  set -ex
  docker image list $PREFIX/$REPO
  { set +ex; } 2>/dev/null
fi

#
# stage: LIST-REG
#
if [ $LIST -eq 2 ]; then
  echo -e "\n$ID: stage: LIST-REG"

  if [ "$REGISTRY_HOST" = ""  ]; then
    echo "$ID: error: require reg"
    exit 1
  fi

  for r in $REGISTRY_HOST; do
    if [ "$REPO" != "" ]; then
      [[ "$REGP" != "" ]] && FREPO=$REGP/$REPO || FREPO=$REPO
      echo | xargs -L1 -t curl --netrc-file $REGISTRY_AUTH -s -k -L $r/v2/$FREPO/tags/list | jq
    else
      echo | xargs -L1 -t curl --netrc-file $REGISTRY_AUTH -s -k -L $r/v2/_catalog | jq
    fi
  done
fi

#
# stage: DELETE-REG
#
if [ $DELR -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: DELETE-REG (keep=$DELR)"

  if [ "$REPO" = "" -o "$REGISTRY_HOST" = ""  ]; then
    echo "$ID: error: require repo,reg"
    exit 1
  fi

  for r in $REGISTRY_HOST; do
    [[ "$REGP" != "" ]] && FREPO=${REGP}/${REPO} || FREPO=${REPO}
    TAGS=$(curl --netrc-file ${REGISTRY_AUTH} -s -k -L ${r}/v2/$FREPO/tags/list|jq|grep -E '\.[0-9]{12}'|
      xargs -L1 |sed 's/,$//' |awk -F. '{print $NF,$0}'|sort -nr|cut -f2- -d' '|sed "1,${DELR}d")
    for TAG in $TAGS; do
      DCD=$(curl --netrc-file ${REGISTRY_AUTH} -s -I -k -H "Accept:application/vnd.docker.distribution.manifest.v2+json" ${r}/v2/$FREPO/manifests/$TAG|
        grep -i docker-content-digest|awk '{print $2}' | tr -d "\t\r\n")
      if [ "$DCD" != "" ]; then
        echo "# $TAG"
        echo | xargs -L1 -t curl --netrc-file ${REGISTRY_AUTH} -k -H "Accept:application/vnd.docker.distribution.manifest.v2+json" -X DELETE ${r}/v2/$FREPO/manifests/$DCD
      fi
    done
  done
fi

#
# stage: DELETE
#
if [ $DEL -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: DELETE (keep=$DEL)"

  if [ "$REPO" = "" ]; then
    echo "$ID: error: require repo"
    exit 1
  fi

  I=$(docker image ls --format "{{.ID}}" $PREFIX/$REPO | uniq | head -${DEL} | tail -1)
  docker image ls -q --filter before=$I $PREFIX/$REPO | tac | xargs -L1 -tr docker image rm -f
  #true
fi

#
# stage: HISTORY
#
if [ $HIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: HISTORY"

  if [ "$REPO" = "" -o "$VER" = ""  ]; then
    echo "$ID: error: require repo,ver"
    exit 1
  fi

  set -ex
  docker image history --format "table {{printf \"%.19s\" .ID}}\t{{.CreatedSince}}\t{{printf \"%.${HIST}s\" .CreatedBy}}\t{{.Size}}" --no-trunc $PREFIX/$REPO:$VER
  { set +ex; } 2>/dev/null
fi

#
# stage: INSPECT
#
if [ $INSPECT -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSPECT"

  if [ "$REPO" = "" -o "$VER" = ""  ]; then
    echo "$ID: error: require repo,ver"
    exit 1
  fi

  set -ex
  docker image inspect $PREFIX/$REPO:$VER
  { set +ex; } 2>/dev/null
fi

#
# stage: PRUNE
#
if [ $PRUNE -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PRUNE (TYPE=$PRUNE_TYPE)"

  if [ "$PRUNE_TYPE" = "d" ]; then
    set -ex
    docker image prune -f
    { set +ex; } 2>/dev/null
  elif [ "$PRUNE_TYPE" = "is" ]; then
    set -ex
    docker image prune --all --filter label=info.from
    { set +ex; } 2>/dev/null
  elif [ "$PRUNE_TYPE" = "a" ]; then
    set -ex
    docker image prune --all
    { set +ex; } 2>/dev/null
  else
    echo "$ID: error: unknown prune type"
    exit 1
  fi
fi

#
# stage: BUILDF
#
if [ $BUILDF -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BUILD-FROM-LIST"

  if [ "$REPO" != "" ]; then
    echo "$PREFIX/$REPO:$VER"
    F=$(cdev.sh -R $REPO|grep ^from|awk '{print $3}')
    R=$(echo $F|awk -F: '{print $1}')
    echo " - $F"

    while [[ $R =~ ^${PREFIX}/ ]]; do
      F=$(cdev.sh -R ${R:3}|grep from|awk '{print $3}')
      R=$(echo $F|awk -F: '{print $1}')
      echo " - $F"
    done
  fi
fi

#
# stage: CHAIN
#
if [ $CHAIN -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: CHAIN"

  if [ "$REPO" = "" -o "$VER" = ""  ]; then
    echo "$ID: error: require repo,ver"
    exit 1
  fi

  docker image history --format "table {{printf \"%.1000s\" .CreatedBy}}" --no-trunc $PREFIX/$REPO:$VER$SUFFIX | \
    grep ENV | \
    grep INFO_DATE | \
    awk -FENV '{print $2}' | \
    xargs -L1 | \
    sed 's/INFO_//g' | \
    sed 's/DATE=//g' | \
    column -t
  true
fi

#
# stage: FILES
#
if [ $FILES -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: FILES"

  if [ "$REPO" = "" -o "$VER" = ""  ]; then
    echo "$ID: error: require repo,ver"
    exit 1
  fi

  p=cdev-tmp-$(shuf -zer -n5 {a..z} {0..9}|col -b)
  docker create --name $p $PREFIX/$REPO:$VER > /dev/null && docker export $p | tar tv
  docker rm $p > /dev/null
fi

#
# stage: RUN
#
if [ $RUN -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: RUN"

  if [ "$REPO" = "" ]; then
    echo "$ID: error: require repo"
    exit 1
  fi

  [[ "$VER" = "" ]] && T=latest || T=$VER$SUFFIX
  NAME=cdev-$REPO-$(shuf -zer -n5 {a..z} {0..9}|col -b)

  set -ex
  docker run --rm -ti --name $NAME $RUN_OPT_CUSTOM1 ${ARGS1[*]} $PREFIX/$REPO:$T $RUN_OPT_CUSTOM2 ${ARGS2[*]}
  { set +ex; } 2>/dev/null
fi

#
# stage: RUN-REG
#
if [ $RUN -eq 2 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: RUN-REG"

  if [ "$REPO" = "" -o "$REGISTRY_HOST" = ""  ]; then
    echo "$ID: error: require repo,reg"
    exit 1
  fi

  [[ "$VER" = "" ]] && T=latest || T=$VER
  NAME=cdev-$REPO-$(shuf -zer -n5 {a..z} {0..9}|col -b)
  REG=$(echo $REGISTRY_HOST|awk '{print $1}'|sed -e 's#^http://##' -e 's#^https://##')
  [[ "$REGP" != "" ]] && REG=${REG}/${REGP}

  set -ex
  docker run --rm -ti --name $NAME $RUN_OPT_CUSTOM1 ${ARGS1[*]} $REG/$REPO:$T $RUN_OPT_CUSTOM2 ${ARGS2[*]}
  { set +ex; } 2>/dev/null
fi

#
# stage: RUN-K8S
#
if [ $RUN -eq 3 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: RUN-K8S"

  if [ "$REPO" = "" -o "$REGISTRY_HOST" = ""  ]; then
    echo "$ID: error: require repo,reg"
    exit 1
  fi

  [[ "$VER" = "" ]] && T=latest || T=$VER
  [[ "${ARGS2[*]}" = "" ]] && C="" || C="--command -- ${ARGS2[*]}"
  NAME=cdev-$REPO-$(shuf -zer -n5 {a..z} {0..9}|col -b)
  REG=$(echo $REGISTRY_HOST|awk '{print $1}'|sed -e 's#^http://##' -e 's#^https://##')
  [[ "$REGP" != "" ]] && REG=${REG}/${REGP}

  set -ex
  kubectl run $NAME --rm -ti --image=$REG/$REPO:$T --image-pull-policy=Always --restart=Never ${ARGS1[*]} $C
  { set +ex; } 2>/dev/null
fi

#
# stage: EXEC
#
if [ $EXEC -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: EXEC"

  if [ "$REPO" = "" ]; then
    echo "$ID: error: require repo"
    exit 1
  fi

  [[ "$VER" = "" ]] && T=latest || T=$VER
  [[ "${ARGS2[*]}" = "" ]] && C="bash" || C="${ARGS2[*]}"
  NAME=$(docker container list --format "{{.Image}} {{.Names}} {{.ID}}"|grep "$PREFIX/$REPO:$T cdev-$REPO"|cut -f2 -d" ")

  if [ "$NAME" != "" ]; then
    set -ex
    docker container exec -ti $NAME $C
    { set +ex; } 2>/dev/null
  else
    echo "$ID: error: unable to find running container: image=$PREFIX/$REPO:$T name=cdev-$REPO-xxxxx"
  fi
fi
