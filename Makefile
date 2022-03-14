# Install prettier gloablly via
# yarn global add prettier --prefix /usr/local
.PHONY: fmt
fmt:
	prettier --write .

.PHONY: test/fmt
test/fmt:
	prettier --check .
