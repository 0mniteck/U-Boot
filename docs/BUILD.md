## Build Instructions/Usage:

### Build:

```
buildscript.sh
  -a ALT # Alternate List (yes/No)
  -c CLEAN # Clean Directories (Yes/no)
  -d DEV # Developer Build [Skip some steps] (yes/No)
  -e EPOCH # SOURCE_DATE_EPOCH [^ for reproducibility] (source_date_epoch/"today"/"^")
  -m MOUNT # Mount External [U2F Backed Luks] ("mmcblk1p1")
  -t TAG # Tag Release refs/tags/("tagname")
  -w CROSS # Cross Compile (yes/No)
  -z TARGET # Target Selection ("target1,target2,all")
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
./buildscript.sh -e ""
```
