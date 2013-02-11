#
# Makefile --Build rules for "adminkit", administration tools..
#
#
PACKAGE	= adminkit
VERSION	= 0.1
RELEASE	= 0
ARCH	= all
SRC_LANG	= sh nroff

MAN1_SRC = db-export.1 mkchroot.1
SH_SRC = agent.sh bloatfish.sh db-export.sh ftp-delete.sh \
    ftp-upload.sh gen-password.sh mkchroot.sh nr-deploy.sh \
    php-sessiondirs.sh procwatch.sh pstiche.sh sslogin.sh
SED_SRC = tsv-to-csv.sed www-to-tsv.sed

include devkit.mk package.mk

installdirs:	$(man1dir) $(bindir)
install:	$(MAN1_SRC:%.1=$(man1dir)/%.1)
install:	$(SH_SRC:%.sh=$(bindir)/%)
install:	$(SED_SRC:%.sed=$(bindir)/%)
install:	$(C_MAIN:$(archdir)/%=$(bindir)/%)
