MAN1_SRC = core.1
#
# Makefile --Build rules for adminkit's libexec directory.
#
#
SRC_LANG	= sh nroff

SH_SRC = lesspipe.sh
SHL_SRC = cgi.shl config.shl core.shl daemon.shl db.shl debian.shl \
    getopt.shl log.shl number.shl string.shl tty.shl unit.shl

include devkit.mk

installdirs:	$(libexecdir)
install:	$(SH_SRC:%.sh=$(libexecdir)/%)
install:	$(SHL_SRC:%=$(libexecdir)/%)
install:	$(MAN1_SRC:%.1=$(man1dir)/%.1)
