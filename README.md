This is a simple Bash script to scrape images from ImageNet.

### Usage

The script must be given a list of classes for which you require images to be downloaded. Here each class must be specified by its WordNet ID: for example, 'n01440764' is the WordNet ID for the class 'tench', and 'n01443537' is the WordNet ID for the class 'goldfish'.

These classes may be specified as command-line arguments:
```bash
$ ./scraper.sh 'n01440764' 'n01443537'
```
but as the number of classes grows, this may become very cumbersome. In such a case, you can list all the WordNet IDs in a file, separated by newlines, and use the `-f` option to specify this file to the script:
```bash
$ ./scraper.sh -f 'wnids.txt'
```
By default, 10 images are downloaded per class specified. You can change this using the `-n` option:
```bash
$ ./scraper.sh -n '50' -f 'wnids.txt'
```
The downloaded images are stored in directories (inside the current directory) corresponding to each class. For example, for 'tench' and 'goldfish', the directory structure will look like this after running the script:
```
n01440764/
	1345140957_2c46ddc413.jpg
	2475423937_7d2c7abb01.jpg
	...
n01443537/
	2189406982_531dff94aa.jpg
	2547084984_d60cde1e13.jpg
	...
```
A snapshot of this script while running is shown below:

![snapshot](snapshot.png)

The output is a progress bar (courtesy of GNU Parallel, see the [requirements section](#requirements) below). This progress bar indicates that downloading has completed for 4% of the classes; for 44 of them, downloading is in progress/has completed and for the remaining 956, downloading is yet to start. '990s' is the ETA, i.e. a loose estimate of how much more time the script will take.

### Timing

The script parallelizes class-wise downloads to save on time. On a 4-core CPU with a fairly good Internet connection, given 1000 classes and 8 images to download per class, it took about 26 minutes.

### Requirements

This script relies on two GNU utilities: one is [Wget](https://www.gnu.org/software/wget/), and the second is [Parallel](https://www.gnu.org/software/parallel/):

> O. Tange (2011): GNU Parallel - The Command-Line Power Tool, ;login: The USENIX Magazine, February 2011:42-47.

Both of these must be present on your system. On my Ubuntu 20.04 LTS system, Wget was already installed, and I installed Parallel using
```
$ sudo apt install parallel
```
As you may have probably guessed, Wget does the actual downloading, while Parallel is responsible for parallelizing the class-wise downloads.

### Note

There is one point that you should note regarding the number of images downloaded per class. It turns out that the script is not guaranteed to download exactly as many images per class as specified - even with the default value of 10, the script is not guaranteed to download exactly 10 images per class.

Typically, the number of images per class will vary: for example, on running this script with 1000 classes and `-n '8'`, i.e. 8 images specified per class, the distribution of images downloaded per class turned out to be
```
    286 7
    274 6
    179 5
    154 8
     71 4
     23 3
      8 2
      4 1
      1 0
```
which essentially means that 286 classes have 7 images per class, 274 classes have 6 images per class and so on, until 1 class for which no images have been downloaded - only 154 classes have exactly 8 images per class.

(You can run the following snippet of Bash code
```bash
for d in n*; do
	find "$d" -type 'f' -name '*.jpg' | wc -l
done | sort | uniq -c | sort -nr
```
in order to produce the above distribution.)

This has to do with the fact that many images in ImageNet are no longer available, so when you specify a certain number of images for download, a few among them turn out to be missing at runtime. (See [this section](#details) for more details.)

Due to this issue, the average number of images downloaded per class will typically be less than the number you have specified. So, it is better to specify a higher number of images than what you actually want: for example, if you actually want 6 images per class, you should probably specify `-n '8'`. (Indeed, the average number of images in the above case turned out to be 6.1.) The number of images per class will still show some variability - i.e. you will not get exactly 6 images per class, but a number very close to 6 in most cases - nevertheless that should not be an issue for most applications.

### WordNet IDs

If you are interested in the 1000 classes used in the ImageNet challenges from 2012-2017, you can use the file `wnids_1000.txt` provided, which contains the WordNet IDs of these classes along with a short label describing each class.

You can use this file to lookup individual IDs corresponding to the classes you are interested in, or to download images for all of the 1000 classes. In the latter case, note that you must not pass this file directly to the script (don't do `-f 'wnids_1000.txt'`), or it will fail - instead, you should do something like this:
```bash
$ ./scraper.sh -f <(cut -d ',' -f '2' < wnids_1000.txt)
```
which will (temporarily) remove the labels in the file and retain only the WordNet IDs.

### Details

Why do you need a script to scrape images from ImageNet? As of August 2021, if you need to access the "full" ImageNet, you need to [submit a request](https://image-net.org/download.php). Otherwise, if you need the subset of ImageNet comprising 1000 classes that was used in the ImageNet challenges from 2012-2017, that dataset is available on [Kaggle](https://www.kaggle.com/c/imagenet-object-localization-challenge/overview/description): however, it is over 150 GB in size.

As of August 2021, the link
```
https://www.image-net.org/api/imagenet.synset.geturls?wnid=<wnid>
```
yields a list of image URLs corresponding to the class whose WordNet ID `<wnid>` you have specified. (Note that this way of accessing ImageNet doesn't seem to be officially endorsed, so it may change in future.) This script queries this link and follows the URLs listed to download images.

These links are old - they were collected in 2011 - so it turns out that many of them are broken. A large bulk of URLs are from Flickr, and they are often more reliable than the others,<sup>[1](#footnote1)</sup> so this script uses only the Flickr URLs. But even the Flickr URLs have problems, and sometimes result in 404 and other errors, leading to the issue discussed [previously](#note).

As a last note, please keep in mind that ImageNet is facing several [privacy issues](https://image-net.org/update-mar-11-2021.php), so any data scraped from it must be used responsibly.

### References

<a name='footnote1'>1.</a> Frolovs, Martin. Downloading the ImageNet. Link: <https://towardsdatascience.com/how-to-scrape-the-imagenet-f309e02de1f4>
