#! /bin/bash
# usage: ./move-image.sh img_file new_name outdir

echo ""
echo "MOVING IMAGE VIA WORK MOUNT"

echo "(1/4) Checking inputs..."
# get/check image file
if [ -z "$1" ]; then
    echo "      No image file provided...exiting"
    exit 1
elif ! [ -e "$1" ]; then
    echo "      Provided image file ($1) does not exist...exiting"
    ls -lh /output/
    exit 1
fi
image_file="$1"
sudo chown $(whoami) $image_file
echo "      Image file exists ($image_file)"

# get/check name
if [ -z "$2" ]; then
    echo "      No container name provided...exiting"
    exit 1
fi
new_name="$2"
echo "      New name provided ($new_name)"

# get/check outdir (can be env variable)
if [ -z "$outdir" ] && [ -z "$3" ]; then
    echo "      No outdir provided via input or env...exiting"
    exit 1
elif [ -z "$outdir" ]; then
    outdir="$3"
fi
if ! [ -d "$outdir" ];then
    echo "      Outdir ($outdir) does not exist or is not a directory...exiting"
    exit 1
fi
echo "      Valid outdir ($outdir)"

# copy, rename, set permissions on img; remove old img file
echo "(2/4) Copying image file to work mount..."
cp $image_file $outdir/$new_name
echo "(3/4) Setting permissions..."
chmod 664 $outdir/$new_name
echo "(4/4) Removing original image file..."
sudo rm $image_file
