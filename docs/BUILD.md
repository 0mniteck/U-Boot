## Build Instructions/Usage:

### Build:

```
buildscript.sh

 -a {Alternate List: yes/No}
 -c {Clean: Yes/no}
 -d (Developer Build: yes/No)
 -e {Date: source_date_epoch}
 -m (Mount: mmcblk1p1)
 -t {release-Tag: tagname}
 -w {Cross Compile: yes/No}
```

#### To compile current release run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git && \
cd U-Boot && \
./buildscript.sh -t "tagname"
```

#### To cross-compile current release run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git && \
cd U-Boot && \
./buildscript.sh -t "tagname" -w yes
```

#### To compile for reproducibility run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git -b "refs/tags/tagname" && \
cd U-Boot && \
./buildscript.sh
```

### Requirements:

* [ ] Debian based OS

* [ ] Any microSD in the /dev/mmcblk1 slot
