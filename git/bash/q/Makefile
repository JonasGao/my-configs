ifeq ($(TARGET),)
  $(error TARGET is not set)
endif
install:
	find -type f -name 'q*' -exec install -v "{}" "${TARGET}" \;
