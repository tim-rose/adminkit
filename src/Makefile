#
# Makefile --Build rules for "adminkit", administration tools..
#
#
language = sh nroff

MAN1_SRC = db-export.1 mkchroot.1
SH_SRC = agent.sh bloatfish.sh db-export.sh errno.sh ftp-delete.sh \
    ftp-upload.sh gen-password.sh mkchroot.sh nr-deploy.sh \
    procwatch.sh pstiche.sh shar.sh
SED_SRC = tsv-to-csv.sed www-to-tsv.sed

include devkit.mk 

install:	install-all
uninstall:	uninstall-all
