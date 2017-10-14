(find /scripts/* -type f -print0; find /bin/* -type f -print0) | sort | xargs -0 sha256deep -e -z | tee files.hash | gpg -bat > files.hash.asc
gpg --verify files.hash.asc
(find /scripts/* -type f -print0; find /bin/* -type f -print0) | sort | xargs -0 sha256deep -e -z -s -X files.hash –w
