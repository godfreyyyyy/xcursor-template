#!/usr/bin/env /bin/bash

. vars.sh

imgs=()
for file_name in $(ls $src_dir)
do
  if [ ${file_name/*./} == "svg" ]
  then
    imgs+=("${file_name/.*/}")
  fi
done

if [ ${#imgs[@]} -eq 0 ]
then
  echo "### No source .SVG images were found in \"$src_dir\" directory."
  echo "### Exitting..."
  exit -1
fi

if [ ${#resolutions[@]} -eq 0 ]
then
  echo "### No resolutions were provided in \"vars.sh\" file."
  echo "### Exitting..."
  exit -2
fi

echo "Cursor for these files will be generated:"
for img in ${imgs[*]}
do
  echo "  * $img"
done
echo "for resolutions:"
for res in ${resolutions[*]}
do
  echo "  * ${res}x${res}"
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
if [ ! -d $imgs_dir ]
then
  create_dir $imgs_dir
fi

# Create directory for build
if [ ! -d $builds_dir ]
then
  create_dir $builds_dir
fi

# Create directory for cursors configs
if [ ! -d $cursors_dir ]
then
  create_dir $cursors_dir
fi

# Generate cursors
for resolution in ${resolutions[*]}
do
  echo "Generating cursor theme for resolution ${resolution}x${resolution}..."

  hotspot="${hotspots[$res_i]} ${hotspots[$res_i]}"

  theme_dir="$builds_dir/${path_theme_name}_${resolution}x${resolution}"
  build_dir="$theme_dir/cursors"
  cursor_dir="$cursors_dir/${resolution}x${resolution}"

  # Create source images directory
  if [ ! -d "$imgs_dir/${resolution}x${resolution}" ]
  then
    create_dir "$imgs_dir/${resolution}x${resolution}"
  fi

  # Create theme directory
  if [ ! -d $theme_dir ]
  then
    create_dir $theme_dir
  fi

  # Create build directory for specific resolution
  if [ ! -d $build_dir ]
  then
    create_dir $build_dir
  fi

  # Create cursors config directory for specific resolution
  if [ ! -d $cursor_dir ]
  then
    create_dir $cursor_dir
  fi

  # Create index.theme
  echo "Generating $theme_dir/index.theme..."
  index_theme="[Icon Theme]\n"
  index_theme+="Name=${theme_name} ${resolution}x${resolution}\n"
  index_theme+="Comment=${theme_comment}\n"
  echo -e "$index_theme" > "$theme_dir/index.theme"
  echo "Generating $theme_dir/index.theme... DONE"

  for img in ${imgs[*]}
  do
    echo "Generating cursor for image $img.svg..."

    hotspot_file="$hotspots_dir/${img}.hotspot"
    output_image_path="$imgs_dir/${resolution}x${resolution}/$img.png"
    src_svg_path="$src_dir/$img.svg"
    src="$imgs_dir/${resolution}x${resolution}/$img.png"
    cursor_file="$cursor_dir/$img.cursor"
    build_file="$build_dir/$img"

    # Generate images
    echo "Generating $output_image_path ..."
    inkscape -o $output_image_path -w $resolution -h $resolution $src_svg_path
    echo "Generating $output_image_path ... DONE"

    # Check if hotspot file exists
    if [ -f $hotspot_file ]
    then
      # Read hotspot file
      hotspot_data=$(cat $hotspot_file)

      # Get hotspot percents
      hotspot_x_percent=${hotspot_data/ */}
      hotspot_y_percent=${hotspot_data/* /}

      # Get hotspot coordinates
      hotspot_x=$(echo "${resolution}/100*${hotspot_x_percent}" | bc -l)
      hotspot_x=${hotspot_x/.*/}
      hotspot_y=$(echo "${resolution}/100*${hotspot_y_percent}" | bc -l)
      hotspot_y=${hotspot_y/.*/}
    else
      hotspot_x=0
      hotspot_y=0
    fi

    # Generate config
    echo "Generating cursor config \"$cursor_file\"..."
    echo "$resolution $hotspot_x $hotspot_y $src" > $cursor_file
    echo "Generating cursor config \"$cursor_file\"... DONE"

    # Generate cursor
    echo "Generating cursor \"$build_file\"..."
    xcursorgen $cursor_file $build_file
    echo "Generating cursor \"$build_file\"... DONE"

    echo "Generating cursor for image $img.svg... DONE"

    symlinks_file="$symlinks_dir/$img.links"

    # Check if symlinks file is present
    if [ -f $symlinks_file ]
    then
      # Generate symlinks
      echo "Generating symlinks for $img..."
      while read -r link_line; do
        cd $build_dir
        echo "Generating symlink \"$build_dir/$link_line\" to \"$img\"..."
        ln -sr "$img" "$link_line"
        echo "Generating symlink \"$build_dir/$link_line\" to \"$img\"... DONE"
        cd ../../..
      done < $symlinks_file
      echo "Generating symlinks for $img... DONE"
    fi
  done

  echo "Generating cursor theme for resolution ${resolution}x${resolution}... DONE"
done
