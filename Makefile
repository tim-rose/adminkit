#
# Makefile --Build rules for "adminkit", administration tools..
#
#
PACKAGE	= adminkit
VERSION	= 0.0
RELEASE	= 2
ARCH	= all
SRC_LANG	= sh nroff

MAN1_SRC = db-export.1 mkchroot.1
SH_SRC = agent.sh bloatfish.sh db-export.sh ftp-delete.sh \
    ftp-upload.sh gen-password.sh mkchroot.sh nr-deploy.sh \
    php-sessiondirs.sh procwatch.sh pstiche.sh sslogin.sh

include devkit.mk package.mk

installdirs:	$(man1dir) $(bindir) $(libexecdir)
install:	$(MAN1_SRC:%.1=$(man1dir)/%.1)
install:	$(SH_SRC:%.sh=$(bindir)/%)
install:	$(SHL_SRC:%=$(libexecdir)/%)
install:	$(C_MAIN:$(archdir)/%=$(bindir)/%)
