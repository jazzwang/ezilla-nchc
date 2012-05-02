all: iso

iso: clean
	mkdir -p cd-src cd-dst
	if [ ! -f /usr/bin/genisoimage ]; then apt-get -y install genisoimage; fi
	if [ ! -f /usr/bin/isohybrid ]; then apt-get -y install syslinux; fi
	if [ ! -f  ubuntu-10.04.4-alternate-amd64.iso ]; then wget http://free.nchc.org.tw/ubuntu-cd/10.04.4/ubuntu-10.04.4-alternate-amd64.iso; fi
	mount -o loop ubuntu-10.04.4-alternate-amd64.iso cd-src/
	rsync -av cd-src/ cd-dst/
	umount cd-src
	mkdir -p cd-dst/ezilla
	cp src/isolinux.cfg cd-dst/isolinux/isolinux.cfg
	cp src/ezilla.png cd-dst/isolinux
	cp src/opennebula_2.2-1_amd64.deb cd-dst/ezilla/opennebula_2.2-1_amd64.deb
	cp src/ezilla.seed cd-dst/ezilla/ezilla.seed
	cp -r src/patch . 
	cp -r src/config .
	tar zcvf patch.tar.gz patch/ config/
	mv patch.tar.gz cd-dst/ezilla/patch.tar.gz
	rm -rf patch
	rm -rf config
	cp src/ezilla-init cd-dst/ezilla/ezilla-init
	genisoimage -r -V "ezilla" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o "ezilla-Lucid.iso" cd-dst
	#isohybrid ezilla-oneiric.iso

clean:
	rm -rf cd-src cd-dst

dist-clean:
	rm -rf ubuntu-10.04.4-alternate-amd64.iso
