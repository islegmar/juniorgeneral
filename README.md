# juniorgeneral

Process the images that are found in the web site https://juniorgeneral.org/

All the scripts can be executed with the option -h to get a detailed help

## Generates an army : find split, split and glue together

Let's suppose we have images obtained from the site [https://juniorgeneral.org/]. 

![](https://juniorgeneral.org/uploaded/%20%20101813/4hQUHf3.png)

And from there we have "cut" a block formed by a front + back, both with a small basis (marked with X)

So the have the form

    |-------|
    |       |
    | Front |
    |       |
    |XXXXXXX|
    |-------|
    |XXXXXXX|
    |       |
    | Back  |
    |       |
    |-------|

But we want something like

    |-------|
    |XXXXXXX|
    |       |
    | Back  |
    |       |
    |-------|
    |       |
    | Front |
    |       |
    |XXXXXXX|
    |-------|

So we can a bigger add basis (small basis XXXX is removed in the graphics)

    |-------|
    | Basis |
    |-------|
    |       |
    | Back  |
    |       |
    |-------|
    |       |
    | Front |
    |       |
    |-------|
    | Basis |
    |-------|

and glue like


       /\
      /  \
    _/    \_

and if we hve some of them we can make an army with several "rows":

       /\       /\       /\
      /  \     /  \     /  \
    _/    \___/    \___/    \_

In order to do that we must perform three steps:
* Know where do we have to "cut" the initial image
* Split that image in a "font" and a "back"
* Put all together

### Get the split position

 
    ./getSplit.sh -f file

Manually you have to see the images produces to know the split value

### Split in front and back
 
    ./splitBackFront.sh -f file -k split

That generates the files font.png and back.png

### Build the army

    ./genArmy.sh

That generates army.png with the front and back and some terrain as basis

## Get the individual pieces : split.sh

The above means you have split the image shown above in "blocks", cutting and removing the blanks.

This process can be done automatically using `split.sh`

Againg help is your friend but basically what id does is to convert the original images in a serie of images, each of them containing a rectangle with an image with no blanks in the border. This process is executed several times, dividing in rows and cols so at the end usuarlly what you get are all the indivudual figures

## How to process "in batch"

* images/original  : the original images, no changes (downloaded wit curl)
* images/changed01 : [Manual] Changes (quick) made with GIMP to remove texts that will make complicate when splitting
* images/changed02 : [10-allSplits.sh] Take the images in 'changed01' and split them in components 
                     [Manual] Go the folder and remove what is not needed
* config/...       : [20-allGetSplit.sh] Take the images from 'changed02' and split them  in "possible" 
                       back and front and keep them in config/.../.... Also generates the file 
                       config/images.csv with the image name and empty place for the split (manual)
* config/...       : [Manual] Review the images in config/... and anotate the split value for every image in config/images.csv
                     [Manual] We can remove if we want the images in config/....; they are not needed and the info is in
                       config/images.csv
* images/changed03 : [30-allSplitBackFront.sh] Take the images from 'changed02' and the info in 'config/images.csv' and split
                       every image in its back and front.


As a result we have a FINAL FOLDER (images03) with the back/front for every image and now we can generate 
an army with those pieces:

./genArmy.sh \
  -F 'images/changed03/www.juniorgeneral.org/mediaval/Anglosaxons/*front.png' \
  -B 'images/changed03/www.juniorgeneral.org/mediaval/Anglosaxons/*back.png'
