export DAPP_SOLC_VERSION=0.6.6
all    :; dapp build
clean  :; dapp clean
test   :; dapp test -vv
debug  :; hevm interactive
size:all; bin/bc-split
