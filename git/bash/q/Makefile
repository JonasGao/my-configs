ifeq ($(TARGET),)
	TARGET=${HOME}/.local/bin
  $(warning TARGET is not set, will using '${TARGET}')
endif
install:
	find . -type f -name 'q*' -exec install -v "{}" "${TARGET}" \;
