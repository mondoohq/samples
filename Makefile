# Install prettier gloablly via
# yarn global add prettier --prefix /usr/local
.PHONY: fmt
fmt:
	prettier --write .

.PHONY: test/fmt
test/fmt:
	prettier --check .

# Copywrite Check Tool: https://github.com/hashicorp/copywrite
license: license/headers/check

license/headers/check:
	copywrite headers --plan

license/headers/apply:
	copywrite headers
