# log-tests.mk
# This file is part of the FreeBASIC test suite
#
# make file for building non-fbcunit tests
#

# ------------------------------------------------------------------------

include common.mk

ifeq ($(HOST),dos)
SHELL = /bin/sh
else
SHELL := $(SHELL)
endif

FIND := find
XARGS := xargs
GREP := grep
SED := sed
ECHO := echo
CAT := cat
PRINTF := printf

ifndef FBC
FBC := fbc$(EXEEXT)
endif

# verify the FB_LANG option
# - must be set to a valid -lang option
ifeq ($(FB_LANG),)
$(error FB_LANG option must be specified)
endif

ifneq ($(FB_LANG),fb)
ifneq ($(FB_LANG),fblite)
ifneq ($(FB_LANG),qb)
ifneq ($(FB_LANG),deprecated)
$(error Unsupported language option -lang $(FB_LANG))
endif
endif
endif
endif

DIRLIST_INC := dirlist.mk
include $(DIRLIST_INC)

ifeq ($(FB_LANG),fb)
DIRLIST := $(DIRLIST_FB)
endif

ifeq ($(FB_LANG),qb)
DIRLIST := $(DIRLIST_QB)
endif

ifeq ($(FB_LANG),deprecated)
DIRLIST := $(DIRLIST_DEPRECATED)
endif

ifeq ($(DIRLIST),)
$(error No directories specified in $(DIRLIST_INC))
endif

ifndef ENABLE_CHECK_BUGS
ENABLE_CHECK_BUGS :=
endif

ifndef ENABLE_CONSOLE_OUTPUT
ENABLE_CONSOLE_OUTPUT :=
endif

.SUFFIXES:
.SUFFIXES: .bmk .bas

# ------------------------------------------------------------------------

LOG_TESTS_INC := log-tests-$(FB_LANG).inc
FAILED_LOG_TESTS_INC := failed-log-tests-$(FB_LANG).inc
FAILED_LOG := failed-$(FB_LANG).log

SRCLIST_COMPILE_ONLY_OK :=
SRCLIST_COMPILE_ONLY_FAIL :=
SRCLIST_COMPILE_AND_RUN_OK :=
SRCLIST_COMPILE_AND_RUN_FAIL :=
SRCLIST_MULTI_MODULE_OK :=
SRCLIST_MULTI_MODULE_FAIL :=

ifeq ($(FAILED_ONLY),1)

include $(FAILED_LOG_TESTS_INC)

SRCLIST_COMPILE_ONLY_OK := $(sort $(SRCLIST_COMPILE_ONLY_OK))
SRCLIST_COMPILE_ONLY_FAIL := $(sort $(SRCLIST_COMPILE_ONLY_FAIL))
SRCLIST_COMPILE_AND_RUN_OK := $(sort $(SRCLIST_COMPILE_AND_RUN_OK))
SRCLIST_COMPILE_AND_RUN_FAIL := $(sort $(SRCLIST_COMPILE_AND_RUN_FAIL))
SRCLIST_MULTI_MODULE_OK := $(sort $(SRCLIST_MULTI_MODULE_OK))
SRCLIST_MULTI_MODULE_FAIL := $(sort $(SRCLIST_MULTI_MODULE_FAIL))

else
ifeq ($(MAKECMDGOALS),mostlyclean)
-include $(LOG_TESTS_INC)
else
include $(LOG_TESTS_INC)
endif
endif

# COMPILE_ONLY_OK
SRCLIST_COMPILE_ONLY_OK := $(filter %.bas,$(patsubst %.bmk,%.bas,$(SRCLIST_COMPILE_ONLY_OK)))
OBJLIST_COMPILE_ONLY_OK := $(addsuffix .o,$(basename $(SRCLIST_COMPILE_ONLY_OK)))
LOGLIST_COMPILE_ONLY_OK := $(addsuffix .log,$(basename $(SRCLIST_COMPILE_ONLY_OK)))

# COMPILE_ONLY_FAIL
SRCLIST_COMPILE_ONLY_FAIL := $(filter %.bas,$(patsubst %.bmk,%.bas,$(SRCLIST_COMPILE_ONLY_FAIL)))
OBJLIST_COMPILE_ONLY_FAIL := $(addsuffix .o,$(basename $(SRCLIST_COMPILE_ONLY_FAIL)))
LOGLIST_COMPILE_ONLY_FAIL := $(addsuffix .log,$(basename $(SRCLIST_COMPILE_ONLY_FAIL)))

# COMPILE_AND_RUN_OK
SRCLIST_COMPILE_AND_RUN_OK := $(filter %.bas,$(patsubst %.bmk,%.bas,$(SRCLIST_COMPILE_AND_RUN_OK)))
OBJLIST_COMPILE_AND_RUN_OK := $(addsuffix .o,$(basename $(SRCLIST_COMPILE_AND_RUN_OK)))
APPLIST_COMPILE_AND_RUN_OK := $(addsuffix $(TARGET_EXEEXT),$(basename $(SRCLIST_COMPILE_AND_RUN_OK)))
LOGLIST_COMPILE_AND_RUN_OK := $(addsuffix .log,$(basename $(SRCLIST_COMPILE_AND_RUN_OK)))

# COMPILE_AND_RUN_FAIL
SRCLIST_COMPILE_AND_RUN_FAIL := $(filter %.bas,$(patsubst %.bmk,%.bas,$(SRCLIST_COMPILE_AND_RUN_FAIL)))
OBJLIST_COMPILE_AND_RUN_FAIL := $(addsuffix .o,$(basename $(SRCLIST_COMPILE_AND_RUN_FAIL)))
APPLIST_COMPILE_AND_RUN_FAIL := $(addsuffix $(TARGET_EXEEXT),$(basename $(SRCLIST_COMPILE_AND_RUN_FAIL)))
LOGLIST_COMPILE_AND_RUN_FAIL := $(addsuffix .log,$(basename $(SRCLIST_COMPILE_AND_RUN_FAIL)))

# MULI_MODULE_OK
SRCLIST_MULTI_MODULE_OK := $(filter %.bmk,$(SRCLIST_MULTI_MODULE_OK))
LOGLIST_MULTI_MODULE_OK := $(patsubst %.bmk,%.log,$(SRCLIST_MULTI_MODULE_OK))

# MULTI_MODULE_FAIL
SRCLIST_MULTI_MODULE_FAIL := $(filter %.bmk,$(SRCLIST_MULTI_MODULE_FAIL))
LOGLIST_MULTI_MODULE_FAIL := $(patsubst %.bmk,%.log,$(SRCLIST_MULTI_MODULE_FAIL))

# BUILDLIST
LOGLIST_ALL := $(strip \
$(LOGLIST_COMPILE_ONLY_OK) \
$(LOGLIST_COMPILE_ONLY_FAIL) \
$(LOGLIST_COMPILE_AND_RUN_OK) \
$(LOGLIST_COMPILE_AND_RUN_FAIL) \
$(LOGLIST_MULTI_MODULE_OK) \
$(LOGLIST_MULTI_MODULE_FAIL) \
)


# set ABORT_CMD := false to abort on failed tests, true to continue anyway
ABORT_CMD := true

FBC_CFLAGS := -w 3 
ifdef DEBUG
	FBC_CFLAGS += -g
endif
ifdef EXTRAERR
	FBC_CFLAGS += -exx
endif

ifneq ($(FB_LANG),)
FBC_CFLAGS += -lang $(FB_LANG)
endif

ifeq ($(ENABLE_CHECK_BUGS),1)
	FBC_CFLAGS += -d ENABLE_CHECK_BUGS=$(ENABLE_CHECK_BUGS)
endif
ifeq ($(ENABLE_CONSOLE_OUTPUT),1)
	FBC_CFLAGS += -d ENABLE_CONSOLE_OUTPUT=$(ENABLE_CONSOLE_OUTPUT)
endif

# ------------------------------------------------------------------------

all : $(LOGLIST_ALL)

# ------------------------------------------------------------------------
ifneq ($(LOGLIST_COMPILE_ONLY_OK),)
$(LOGLIST_COMPILE_ONLY_OK) : %.log : %.bas
	@$(ECHO) "$< : TEST_MODE=COMPILE_ONLY_OK"
	@$(ECHO) "$< : TEST_MODE=COMPILE_ONLY_OK" > $@
	@if $(FBC) $(FBC_CFLAGS) -c $< \
	; then \
		$(ECHO) "$< : RESULT=PASSED" && \
		true \
	; else \
		$(ECHO) "$< : RESULT=FAILED" && \
		$(ECHO) "SRCLIST_COMPILE_ONLY_OK += $<" >> $(FAILED_LOG_TESTS_INC) && \
		$(ABORT_CMD) \
	; fi >> $@ 2>&1
endif

# ------------------------------------------------------------------------
ifneq ($(LOGLIST_COMPILE_ONLY_FAIL),)
$(LOGLIST_COMPILE_ONLY_FAIL) : %.log : %.bas
	@$(ECHO) "$< : TEST_MODE=COMPILE_ONLY_FAIL"
	@$(ECHO) "$< : TEST_MODE=COMPILE_ONLY_FAIL" > $@
	@if $(FBC) $(FBC_CFLAGS) -c $< \
	; then \
		$(ECHO) "$< : RESULT=FAILED" && \
		$(RM) -f $(patsubst %.bas,%.o,$<) && \
		$(ECHO) "SRCLIST_COMPILE_ONLY_FAIL += $<" >> $(FAILED_LOG_TESTS_INC) && \
		$(ABORT_CMD) \
	; else \
		$(ECHO) "$< : RESULT=PASSED" && \
		true \
	; fi >> $@ 2>&1
endif

# ------------------------------------------------------------------------
ifneq ($(LOGLIST_COMPILE_AND_RUN_OK),)
$(LOGLIST_COMPILE_AND_RUN_OK) : %.log : %.bas
	@$(ECHO) "$< : TEST_MODE=COMPILE_AND_RUN_OK"
	@$(ECHO) "$< : TEST_MODE=COMPILE_AND_RUN_OK" > $@
	@if cd . && $(MAKE) -f bmk-make.mk FILE=$< TEST_MODE=COMPILE_AND_RUN_OK LOGFILE=$@ \
	; then \
		$(ECHO) "$< : RESULT=PASSED" && \
		true \
	; else \
		$(ECHO) "$< : RESULT=FAILED" && \
		$(ECHO) "SRCLIST_COMPILE_AND_RUN_OK += $<" >> $(FAILED_LOG_TESTS_INC) && \
		$(ABORT_CMD) \
	; fi >> $@ 2>&1
endif

# ------------------------------------------------------------------------
ifneq ($(LOGLIST_COMPILE_AND_RUN_FAIL),)
$(LOGLIST_COMPILE_AND_RUN_FAIL) : %.log : %.bas
	@$(ECHO) "$< : TEST_MODE=COMPILE_AND_RUN_FAIL"
	@$(ECHO) "$< : TEST_MODE=COMPILE_AND_RUN_FAIL" > $@
	@if cd . && $(MAKE) -f bmk-make.mk FILE=$< TEST_MODE=COMPILE_AND_RUN_FAIL LOGFILE=$@ \
	; then \
		$(ECHO) "$< : RESULT=PASSED" && \
		true \
	; else \
		$(ECHO) "$< : RESULT=FAILED" && \
		$(ECHO) "SRCLIST_COMPILE_AND_RUN_FAIL += $<" >> $(FAILED_LOG_TESTS_INC) && \
		$(ABORT_CMD) \
	; fi >> $@ 2>&1
endif

# ------------------------------------------------------------------------
ifneq ($(LOGLIST_MULTI_MODULE_OK),)
$(LOGLIST_MULTI_MODULE_OK)  : %.log : %.bmk
	@$(ECHO) "$< : TEST_MODE=MULTI_MODULE_OK"
	@$(ECHO) "$< : TEST_MODE=MULTI_MODULE_OK" > $@
	@if cd . && $(MAKE) -f bmk-make.mk BMK=$< TEST_MODE=MULTI_MODULE_OK LOGFILE=$@ \
	; then \
		$(ECHO) "$< : RESULT=PASSED" && \
		true \
	; else \
		$(ECHO) "$< : RESULT=FAILED" && \
		$(ECHO) "SRCLIST_MULTI_MODULE_OK += $<" >> $(FAILED_LOG_TESTS_INC) && \
		$(ABORT_CMD) \
	; fi >> $@ 2>&1
endif

# ------------------------------------------------------------------------
ifneq ($(LOGLIST_MULTI_MODULE_FAIL),)
$(LOGLIST_MULTI_MODULE_FAIL)  : %.log : %.bmk
	@$(ECHO) "$< : TEST_MODE=MULTI_MODULE_FAIL"
	@$(ECHO) "$< : TEST_MODE=MULTI_MODULE_FAIL" > $@
	@if cd . && $(MAKE) -f bmk-make.mk BMK=$< TEST_MODE=MULTI_MODULE_FAIL LOGFILE=$@ \
	; then \
		$(ECHO) "$< : RESULT=PASSED" && \
		true \
	; else \
		$(ECHO) "$< : RESULT=FAILED" && \
		$(ECHO) "SRCLIST_MULTI_MODULE_FAIL += $<" >> $(FAILED_LOG_TESTS_INC) && \
		$(ABORT_CMD) \
	; fi >> $@ 2>&1
endif

# ------------------------------------------------------------------------
# Auto-generate the FAILED_LOG_TESTS_INC - needed by this makefile
# from all dirs listed in DIRLIST from DIRLIST_INC
#
$(FAILED_LOG_TESTS_INC) :
	@$(PRINTF) "Generating $(FAILED_LOG_TESTS_INC) : "
	@$(ECHO) "# This file automatically generated - DO NOT EDIT" > $(FAILED_LOG_TESTS_INC)
	@$(ECHO) "#" >> $(FAILED_LOG_TESTS_INC)

	@$(PRINTF) "."
	@$(FIND) $(DIRLIST) -type f -name '*.log' \
| $(XARGS) $(GREP) -l -i -E '^.*[[:space:]]*:[[:space:]]*RESULT=FAILED' \
| $(SED) -e 's/\(^.*\)[[:space:]]\:[[:space:]]TESTMODE=\(.*\)/SRCLIST_\2 \+\= \1/g' \
>> $(FAILED_LOG_TESTS_INC)
	@$(ECHO) "#" >> $(FAILED_LOG_TESTS_INC)

	@$(ECHO) " Done"

# ------------------------------------------------------------------------
# Auto-generate the LOG_TESTS_INC - needed by this makefile
# from all dirs listed in DIRLIST from DIRLIST_INC
#
$(LOG_TESTS_INC) :
	@$(PRINTF) "Generating $(LOG_TESTS_INC) : "
	@$(ECHO) "# This file automatically generated - DO NOT EDIT" > $(LOG_TESTS_INC)
	@$(ECHO) "#" >> $(LOG_TESTS_INC)

	@$(PRINTF) "."
	@$(FIND) $(DIRLIST) -type f -name '*.bas' -or -name '*.bmk' \
| $(XARGS) $(GREP) -l -i -E '[[:space:]]*.[[:space:]]*TEST_MODE[[:space:]]*\:[[:space:]]*COMPILE_ONLY_OK' \
| $(SED) -e 's/\(^.*\)/\SRCLIST_COMPILE_ONLY_OK \+\= \.\/\1/g' \
>> $(LOG_TESTS_INC)
	@$(ECHO) "#" >> $(LOG_TESTS_INC)

	@$(PRINTF) "."
	@$(FIND) $(DIRLIST) -type f -name '*.bas' -or -name '*.bmk' \
| $(XARGS) $(GREP) -l -i -E '[[:space:]]*.[[:space:]]*TEST_MODE[[:space:]]*\:[[:space:]]*COMPILE_ONLY_FAIL' \
| $(SED) -e 's/\(^.*\)/\SRCLIST_COMPILE_ONLY_FAIL \+\= \.\/\1/g' \
>> $(LOG_TESTS_INC)
	@$(ECHO) "#" >> $(LOG_TESTS_INC)

	@$(PRINTF) "."
	@$(FIND) $(DIRLIST) -type f -name '*.bas' -or -name '*.bmk' \
| $(XARGS) $(GREP) -l -i -E '[[:space:]]*.[[:space:]]*TEST_MODE[[:space:]]*\:[[:space:]]*COMPILE_AND_RUN_OK' \
| $(SED) -e 's/\(^.*\)/\SRCLIST_COMPILE_AND_RUN_OK \+\= \.\/\1/g' \
>> $(LOG_TESTS_INC)
	@$(ECHO) "#" >> $(LOG_TESTS_INC)

	@$(PRINTF) "."
	@$(FIND) $(DIRLIST) -type f -name '*.bas' -or -name '*.bmk' \
| $(XARGS) $(GREP) -l -i -E '[[:space:]]*.[[:space:]]*TEST_MODE[[:space:]]*\:[[:space:]]*COMPILE_AND_RUN_FAIL' \
| $(SED) -e 's/\(^.*\)/\SRCLIST_COMPILE_AND_RUN_FAIL \+\= \.\/\1/g' \
>> $(LOG_TESTS_INC)
	@$(ECHO) "#" >> $(LOG_TESTS_INC)

	@$(PRINTF) "."
	@$(FIND) $(DIRLIST) -type f -name '*.bmk' \
| $(XARGS) $(GREP) -l -i -E '[[:space:]]*.[[:space:]]*TEST_MODE[[:space:]]*\:[[:space:]]*MULTI_MODULE_OK' \
| $(SED) -e 's/\(^.*\)/\SRCLIST_MULTI_MODULE_OK \+\= \.\/\1/g' \
>> $(LOG_TESTS_INC)
	@$(ECHO) "#" >> $(LOG_TESTS_INC)

	@$(PRINTF) "."
	@$(FIND) $(DIRLIST) -type f -name '*.bmk' \
| $(XARGS) $(GREP) -l -i -E '[[:space:]]*.[[:space:]]*TEST_MODE[[:space:]]*\:[[:space:]]*MULTI_MODULE_FAIL' \
| $(SED) -e 's/\(^.*\)/\SRCLIST_MULTI_MODULE_FAIL \+\= \.\/\1/g' \
>> $(LOG_TESTS_INC)
	@$(ECHO) "#" >> $(LOG_TESTS_INC)

	@$(ECHO) " Done"

# ------------------------------------------------------------------------
# results
#

results : $(LOGLIST_ALL)

	@$(PRINTF) "\n\nFAILED LOG - for log-tests -lang $(FB_LANG)\n" > $(FAILED_LOG)

ifeq ($(LOGLIST_ALL),)
	@$(PRINTF) "None Found\n\n" >> $(FAILED_LOG)
else
	@if  \
$(GREP) -i -E '^.*[[:space:]]*:[[:space:]]*RESULT=FAILED' $(LOGLIST_ALL) \
	; then \
		$(PRINTF) " \n" && \
		true \
	; else \
		$(PRINTF) "None Found\n\n" && \
		true \
	; fi  >> $(FAILED_LOG)
endif
	@$(CAT) $(FAILED_LOG)

# ------------------------------------------------------------------------
# clean-up
#
.PHONY: clean
clean : clean_tests clean_include clean_failed_include

.PHONY: mostlyclean
mostlyclean : clean_tests

.PHONY: clean_tests
clean_tests :
	@$(ECHO) Cleaning log-tests for -lang $(FB_LANG) ...
ifneq ($(OBJLIST_COMPILE_ONLY_OK),)
	@$(RM) $(OBJLIST_COMPILE_ONLY_OK) 
endif
ifneq ($(LOGLIST_COMPILE_ONLY_OK),)
	@$(RM) $(LOGLIST_COMPILE_ONLY_OK)
endif
ifneq ($(OBJLIST_COMPILE_ONLY_FAIL),)
	@$(RM) $(OBJLIST_COMPILE_ONLY_FAIL) 
endif
ifneq ($(LOGLIST_COMPILE_ONLY_FAIL),)
	@$(RM) $(LOGLIST_COMPILE_ONLY_FAIL)
endif
ifneq ($(APPLIST_COMPILE_AND_RUN_OK),)
	@$(RM) $(APPLIST_COMPILE_AND_RUN_OK) 
endif
ifneq ($(OBJLIST_COMPILE_AND_RUN_OK),)
	@$(RM) $(OBJLIST_COMPILE_AND_RUN_OK) 
endif
ifneq ($(LOGLIST_COMPILE_AND_RUN_OK),)
	@$(RM) $(LOGLIST_COMPILE_AND_RUN_OK)
endif
ifneq ($(OBJLIST_COMPILE_AND_RUN_FAIL),)
	@$(RM) $(OBJLIST_COMPILE_AND_RUN_FAIL) 
endif
ifneq ($(APPLIST_COMPILE_AND_RUN_FAIL),)
	@$(RM) $(APPLIST_COMPILE_AND_RUN_FAIL) 
endif
ifneq ($(LOGLIST_COMPILE_AND_RUN_FAIL),)
	@$(RM) $(LOGLIST_COMPILE_AND_RUN_FAIL)
endif
ifneq ($(SRCLIST_MULTI_MODULE_OK),)
	@for s in $(SRCLIST_MULTI_MODULE_OK) ; do $(MAKE) -f bmk-make.mk clean BMK=$$s TEST_MODE=MULTI_MODULE_OK ; done
endif
ifneq ($(LOGLIST_MULTI_MODULE_OK),)
	@$(RM) $(LOGLIST_MULTI_MODULE_OK) 
endif
ifneq ($(SRCLIST_MULTI_MODULE_FAIL),)
	@for s in $(SRCLIST_MULTI_MODULE_FAIL) ; do $(MAKE) -f bmk-make.mk clean BMK=$$s TEST_MODE=MULTI_MODULE_FAIL ; done
endif
ifneq ($(LOGLIST_MULTI_MODULE_FAIL),)
	@$(RM) $(LOGLIST_MULTI_MODULE_FAIL) 
endif

.PHONY: clean_include
clean_include :
	$(RM) $(LOG_TESTS_INC)
	@$(RM) $(FAILED_LOG) 

.PHONY: clean_failed_include
clean_failed_include :
	$(RM) $(FAILED_LOG_TESTS_INC)
