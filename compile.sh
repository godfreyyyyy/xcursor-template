#!/usr/bin/env /bin/bash

. vars.sh

# Find all .SVG images in source directory
IMGS=()
for FILE_NAME in $(find $SRC_DIR -maxdepth 1 -type f)
do
  if [ ${FILE_NAME/*./} == "svg" ]
  then
    FILE_NAME=${FILE_NAME/.*/}
    FILE_NAME=${FILE_NAME/*$SRC_DIR\//}
    IMGS+=("${FILE_NAME/.*/}")
  fi
done

# Find all directories in source directory.
# Script will assume that these directories
# are directories for animated cursors.
ANIMATED=()
for DIRECTORY_NAME in $(find $SRC_DIR -maxdepth 1 -type d)
do
  DIRECTORY_NAME=${DIRECTORY_NAME/*$SRC_DIR\//}
  if [ "$DIRECTORY_NAME" != "$SRC_DIR" ]
  then
    ANIMATED+=($DIRECTORY_NAME)
  fi
done

if [ ${#IMGS[@]} -eq 0 && ${#ANIMATED[@]} -eq 0 ]
then
  echo "### No source .SVG images were found in \"$src_dir\" directory."
  echo "### Exitting..."
  exit -1
fi

if [ ${#RESOLUTIONS[@]} -eq 0 ]
then
  echo "### No resolutions were provided in \"vars.sh\" file."
  echo "### Exitting..."
  exit -2
fi

echo "Cursor for these files will be generated:"
for IMG in ${IMGS[*]}
do
  echo "  * $IMG"
done
echo "for resolutions:"
for RES in ${RESOLUTIONS[*]}
do
  echo "  * ${RES}x${RES}"
done

has_command() {
  "$1" -v $1 > /dev/null 2>&1
}

create_dir() {
  echo "Creating \"$1\" directory..."
  mkdir -p "$1"
  echo "Creating \"$1\" directory... DONE"
}

# Check if inkscape is installed
echo "Checking if inkscape is installed..."
if [ ! "$(which inkscape 2> /dev/null)" ]
then
  echo "inkscape must be installed to generate cursors"
  echo "Enter this command to install:"
  if has_command zypper; then
    echo "        sudo zypper in inkscape"
  elif has_command apt; then
    echo "        sudo apt install inkscape"
  elif has_command dnf; then
    echo "        sudo dnf install -y inkscape"
  elif has_command pacman; then
    echo "        sudo pacman -S inkscape"
  else
    echo "### Could not detect package manager!"
    echo "### Reference your distro's packages."
  fi
  exit -1
fi
echo "Checking if inkscape is installed... DONE"

# Check if bc is installed
echo "Checking if bc is installed..."
if [ ! "$(which bc 2> /dev/null)" ]
then
  echo "bc must be installed to generate cursors"
  echo "Enter this command to install:"
  if has_command zypper; then
    echo "        sudo zypper in bc"
  elif has_command apt; then
    echo "        sudo apt install bc"
  elif has_command dnf; then
    echo "        sudo dnf install -y bc"
  elif has_command pacman; then
    echo "        sudo pacman -S bc"
  else
    echo "### Could not detect package manager!"
    echo "### Reference your distro's packages."
  fi
fi
echo "Checking if bc is installed... DONE"

# Check if xcursorgen is installed
echo "Checking if xcursorgen is installed..."
if [ ! "$(which xcursorgen 2> /dev/null)" ]
then
  echo "xorg-xcursorgen must be installed to generate cursors"
  echo "Enter this command to install:"
  if has_command zypper; then
    echo "        sudo zypper in xorg-xcursorgen"
  elif has_command apt; then
    echo "        sudo apt install xorg-xcursorgen"
  elif has_command dnf; then
    echo "        sudo dnf install -y xorg-xcursorgen"
  elif has_command pacman; then
    echo "        sudo pacman -S xorg-xcursorgen"
  else
    echo "### Could not detect package manager!"
    echo "### Reference your distro's packages."
  fi
fi
echo "Checking if xcursorgen is installed... DONE"

# Create directory for images
if [ ! -d $IMGS_DIR ]
then
  create_dir $IMGS_DIR
fi

# Create directory for build
if [ ! -d $BUILDS_DIR ]
then
  create_dir $BUILDS_DIR
fi

# Create directory for cursors configs
if [ ! -d $CURSORS_DIR ]
then
  create_dir $CURSORS_DIR
fi

get_hotspot() {
  CURSOR_NAME=$1
  RES=$2

  # Check if hotspot file exists
  HOTSPOT_FILE="$HOTSPOTS_DIR/$CURSOR_NAME.hotspot"
  if [ -f $HOTSPOT_FILE ]
  then
    # Read hotspot file
    HOTSPOT_DATA=$(cat "$HOTSPOT_FILE")

    # Get hotspot percents
    HOTSPOT_X_PERCENT=${HOTSPOT_DATA/ */}
    HOTSPOT_Y_PERCENT=${HOTSPOT_DATA/* /}

    # Get hotspot coordinates
    HOTSPOT_X=$(echo "${RES}/100*${HOTSPOT_X_PERCENT}" | bc -l)
    HOTSPOT_X=${HOTSPOT_X/.*/}
    HOTSPOT_Y=$(echo "${RES}/100*${HOTSPOT_Y_PERCENT}" | bc -l)
    HOTSPOT_Y=${HOTSPOT_Y/.*/}
  else
    # Set hotspot to (0;0)
    HOTSPOT_X=0
    HOTSPOT_Y=0
  fi

  echo "$HOTSPOT_X $HOTSPOT_Y" 2>&1
}

generate_cursor() {
  RES=$1
  IMG=$2

  echo "Generating cursor for image $IMG.svg..."

  HOTSPOT_FILE="$HOTSPOTS_DIR/${IMG}.hotspot"
  OUTPUT_IMAGE_PATH="$IMGS_DIR/${RES}x${RES}/$IMG.png"
  SRC_SVG_PATH="$SRC_DIR/$IMG.svg"
  SRC="$IMGS_DIR/${RES}x${RES}/$IMG.png"
  CURSOR_FILE="$CURSOR_DIR/$IMG.cursor"
  BUILD_FILE="$BUILD_DIR/$IMG"

  # Generate images
  echo "Generating $OUTPUT_IMAGE_PATH ..."
  inkscape -o $OUTPUT_IMAGE_PATH -w $RES -h $RES $SRC_SVG_PATH
  echo "Generating $OUTPUT_IMAGE_PATH ... DONE"

  # Get hotspot
  HOTSPOT=$(get_hotspot $IMG $RES)
  HOTSPOT_X=${HOTSPOT/ */}
  HOTSPOT_Y=${HOTSPOT/* /}

  # Generate config
  echo "Generating cursor config \"$CURSOR_FILE\"..."
  echo "$RESOLUTION $HOTSPOT_X $HOTSPOT_Y $SRC" > $CURSOR_FILE
  echo "Generating cursor config \"$CURSOR_FILE\"... DONE"

  # Generate cursor
  echo "Generating cursor \"$BUILD_FILE\"..."
  xcursorgen $CURSOR_FILE $BUILD_FILE
  echo "Generating cursor \"$BUILD_FILE\"... DONE"

  echo "Generating cursor for image $IMG.svg... DONE"

  SYMLINKS_FILE="$SYMLINKS_DIR/$IMG.links"
  # Check if symlinks file is present
  if [ -f $SYMLINKS_FILE ]
  then
    # Generate symlinks
    echo "Generating symlinks for $IMG..."
    while read -r LINK_LINE; do
      cd $BUILD_DIR
      if [ ! -f "$LINK_LINE" ]
      then
        echo "Generating symlink \"$BUILD_DIR/$LINK_LINE\" to \"$IMG\"..."
        ln -sr "$IMG" "$LINK_LINE"
        echo "Generating symlink \"$BUILD_DIR/$LINK_LINE\" to \"$IMG\"..."\
             "DONE"
      fi
      cd ../../..
    done < $SYMLINKS_FILE
    echo "Generating symlinks for $IMG... DONE"
  fi
}

generate_animated_cursor() {
  RES=$1
  DIR=$2

  HOTSPOT_FILE="$HOTSPOTS_DIR/$DIR.hotspot"
  IMGS_PATH="$IMGS_DIR/${RES}x${RES}/$DIR"
  SRC_SVGS_PATH="$SRC_DIR/$DIR"
  CURSOR_FILE="$CURSOR_DIR/$DIR.cursor"
  BUILD_FILE="$BUILD_DIR/$DIR"

  if [ ! -d $IMGS_PATH ]
  then
    create_dir $IMGS_PATH
  fi

  # Get all images .SVG images in cursor's directory
  ANIMATION_FILES=()
  for FILE_NAME in $(find $SRC_SVGS_PATH -maxdepth 1 -type f)
  do
    if [ ${FILE_NAME/*./} == "svg" ]
    then
      FILE_NAME=${FILE_NAME/.*/}
      FILE_NAME=${FILE_NAME/*$SRC_SVGS_PATH\//}
      ANIMATION_FILES+=($FILE_NAME)
    fi
  done

  # Check if there's at least one animation file
  if [ ${#ANIMATION_FILES[@]} -eq 0 ]
  then
    echo "### Animation files for cursor \"$DIR\" are missing"
    return
  fi

  # Sort files
  IFS=$'\n'
  ANIMATION_FILES=($(sort -V <<< "${ANIMATION_FILES[*]}"))
  unset IFS

  # Get frametimes
  ANIMTIMES=()
  if [ -f "$ANIMTIMES_DIR/$DIR.frametime" ]
  then
    while read -r ANIMTIME; do
      ANIMTIMES+=($ANIMTIME)
    done < "$ANIMTIMES_DIR/$DIR.frametime"

    if [ ${#ANIMTIMES[@]} -lt ${#ANIMATION_FILES[@]} ]
    then
      # Number of frame times is less than number of frames.
      # Add default frametimes.
      ANIMTIMES+=($DEFAULT_FRAMETIME)
    elif [ ${#ANIMTIMES[@]} -gt ${#ANIMATION_FILES[@]} ]
    then
      # Number of frame times is greater than number of frames.
      # Print warning and remove frametimes.
      echo "### Number of frametimes (${#ANIMTIMES[@]})" \
        "is greater than number of frames (${#ANIMATION_FILES[@]})"
      echo "### Consider removing extra frames"

      __BUF=()
      for (( i=0; i < ${#ANIMATION_FILES[@]}; i++ ))
      do
        __BUF+=(${ANIMTIMES[$i]})
      done
      unset ANIMTIMES
      ANIMTIMES=${__BUF[*]}
      unset __BUF
    fi
  else
    for _ in ${ANIMATION_FILES[*]}
    do
      ANIMTIMES+=($DEFAULT_FRAMETIME)
    done
  fi

  # Get hotspot
  HOTSPOT=$(get_hotspot $DIR $RES)
  HOTSPOT_X=${HOTSPOT/ */}
  HOTSPOT_Y=${HOTSPOT/* /}

  # Generate images and cursor config
  CURSOR_CONFIG_DATA=()
  echo "Generating cursor from images in \"$DIR\" directory..."
  for (( i=0; i < ${#ANIMATION_FILES[@]}; i++ ))
  do
    ANIM_FILE=${ANIMATION_FILES[$i]}
    FRAMETIME=${ANIMTIMES[$i]}

    echo "[$ANIM_FILE/${#ANIMATION_FILES[@]}] $DIR cursor..."

    # Rasterize the image
    inkscape -o $IMGS_PATH/$ANIM_FILE.png -w $RES -h $RES \
      $SRC_SVGS_PATH/$ANIM_FILE.svg

    # Add frame into a cursor config data
    CURSOR_CONFIG_DATA+=("$RES $HOTSPOT_X $HOTSPOT_Y $IMGS_PATH/$ANIM_FILE.png $FRAMETIME")
  done

  # Add cursor config data into a file
  __BUF=""
  for (( i=0; i < ${#CURSOR_CONFIG_DATA[@]}; i++))
  do
    if [ $i -eq 0 ]
    then
      __BUF+="${CURSOR_CONFIG_DATA[$i]}"
    else
      __BUF+="\n${CURSOR_CONFIG_DATA[$i]}"
    fi
  done
  echo -e "$__BUF" > $CURSOR_FILE
  unset __BUF

  # Generate cursor
  echo "Generating cursor \"$BUILD_FILE\"..."
  xcursorgen $CURSOR_FILE $BUILD_FILE
  echo "Generating cursor \"$BUILD_FILE\"... DONE"

  echo "Generating cursor from images in \"$DIR\" directory... DONE"

  SYMLINKS_FILE="$SYMLINKS_DIR/$DIR.links"
  # Check if symlinks file is present
  if [ -f $SYMLINKS_FILE ]
  then
    # Generate symlinks
    echo "Generating symlinks for $DIR..."
    while read -r LINK_LINE; do
      cd $BUILD_DIR
      if [ ! -f "$LINK_LINE" ]
      then
        echo "Generating symlink \"$BUILD_DIR/$LINK_LINE\" to \"$DIR\"..."
        ln -sr "$DIR" "$LINK_LINE"
        echo "Generating symlink \"$BUILD_DIR/$LINK_LINE\" to \"$DIR\"..."\
             "DONE"
      fi
      cd ../../..
    done < $SYMLINKS_FILE
    echo "Generating symlinks for $DIR... DONE"
  fi
}

# Generate cursors
for RESOLUTION in ${RESOLUTIONS[*]}
do
  echo "Generating cursor theme for resolution ${RESOLUTION}x${RESOLUTION}..."

  THEME_DIR="$BUILDS_DIR/${PATH_THEME_NAME}_${RESOLUTION}x${RESOLUTION}"
  BUILD_DIR="$THEME_DIR/cursors"
  CURSOR_DIR="$CURSORS_DIR/${RESOLUTION}x${RESOLUTION}"

  # Create source images directory
  if [ ! -d "$IMGS_DIR/${RESOLUTION}x${RESOLUTION}" ]
  then
    create_dir "$IMGS_DIR/${RESOLUTION}x${RESOLUTION}"
  fi

  # Create theme directory
  if [ ! -d $THEME_DIR ]
  then
    create_dir $THEME_DIR
  fi

  # Create build directory for specific resolution
  if [ ! -d $BUILD_DIR ]
  then
    create_dir $BUILD_DIR
  fi

  # Create cursors config directory for specific resolution
  if [ ! -d $CURSOR_DIR ]
  then
    create_dir $CURSOR_DIR
  fi

  # Create index.theme
  echo "Generating $THEME_DIR/index.theme..."
  INDEX_THEME="[Icon Theme]\n"
  INDEX_THEME+="Name=${THEME_NAME} ${RESOLUTION}x${RESOLUTION}\n"
  INDEX_THEME+="Comment=${THEME_COMMENT}\n"
  echo -e "$INDEX_THEME" > "$THEME_DIR/index.theme"
  echo "Generating $THEME_DIR/index.theme... DONE"

  # Generate static cursors
  for IMG in ${IMGS[*]}
  do
    generate_cursor $RESOLUTION $IMG
  done

  # Generate animated cursors
  for ANIM in ${ANIMATED[*]}
  do
    generate_animated_cursor $RESOLUTION $ANIM
  done

  echo "Generating cursor theme for resolution" \
    "${RESOLUTION}x${RESOLUTION}... DONE"
done
