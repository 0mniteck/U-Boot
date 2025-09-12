## Build Instructions/Usage:

### Build:

```
buildscript.sh
 -a {Cross-Compile: yes/No}
 -c {Clean: Yes/no}
 -d {Date: source_date_epoch}
 -r {Release-tag: tagname}
 -t {Test-mode: yes/No}
```

#### To compile current release run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git && \
cd U-Boot && \
./buildscript.sh -r "tagname"
```

#### To cross-compile current release run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git && \
cd U-Boot && \
./buildscript.sh -r "tagname" -a yes
```

#### To compile for reproducibility run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git -b "refs/tags/tagname" && \
cd U-Boot && \
./buildscript.sh -d "$(cat Results/release.sha512sum | grep Epoch | cut -d ' ' -f5)"
```

### Requirements:

* [ ] Debian based OS

* [ ] Any microSD in the /dev/mmcblk1 slot
