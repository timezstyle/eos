cleos = docker exec -it eosio /opt/eosio/bin/cleos --url http://127.0.0.1:7777 --wallet-url http://127.0.0.1:5555
CONTRACT_FOLDER ?= $(CURDIR)/contracts
DEV_PRIVATE_KEY ?= 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

WALLET_PUBLIC_KEY ?= PW5JFaYzpMQcXPztJpioTFpN2mzJ5x1VD2ZPHgWEnZsC7otHQV79P
WALLET_PRIVATE_KEY ?= EOS6FzfHToz5bErL3bgQBSD9GmYpA8riiXwjSrgSNss1VhbG2DJXX

clean:
	docker rm -f eosio

eos:
	mkdir -p $(CURDIR)/contracts
	docker run --rm --name eosio \
		--publish 7777:7777 \
		--publish 127.0.0.1:5555:5555 \
		--volume $(CONTRACT_FOLDER):$(CONTRACT_FOLDER) \
		--detach \
		eosio/eos:v1.4.2 \
		/bin/bash -c \
		"keosd --http-server-address=0.0.0.0:5555 & exec nodeos -e -p eosio --plugin eosio::producer_plugin --plugin eosio::chain_api_plugin --plugin eosio::history_plugin --plugin eosio::history_api_plugin --plugin eosio::http_plugin -d /mnt/dev/data --config-dir /mnt/dev/config --http-server-address=0.0.0.0:7777 --access-control-allow-origin=* --contracts-console --http-validate-host=false --filter-on='*'"

list:
	@$(cleos) wallet list

create:
	@$(cleos) wallet create --to-console
	# set WALLET_PUBLIC_KEY
	@$(cleos) wallet open

unlock:	
	@$(cleos) wallet unlock --password $(WALLET_PUBLIC_KEY)
	@$(cleos) wallet create_key
	# set WALLET_PRIVATE_KEY

import:
	$(cleos) wallet import --private-key $(DEV_PRIVATE_KEY)

account:
	$(cleos) create account eosio bob $(WALLET_PRIVATE_KEY) 
	$(cleos) create account eosio alice $(WALLET_PRIVATE_KEY) 
	$(cleos) create account eosio hello $(WALLET_PRIVATE_KEY) -p eosio@active
	$(cleos) create account eosio addressbook $(WALLET_PRIVATE_KEY) -p eosio@active

define build
	cd $(CONTRACT_FOLDER)/$(1); eosio-cpp -o $(1).wasm $(1).cpp --abigen; cd -
	cd $(CONTRACT_FOLDER)/$(1); $(cleos) set contract $(1) $(CONTRACT_FOLDER)/$(1) -p $(1)@active; cd -
endef

hello:
	$(call build,hello)
	$(cleos) push action hello hi '["bob"]' -p bob@active
	$(cleos) push action hello hi '["alice"]' -p bob@active

addressbook:
	$(call build,addressbook)
	$(cleos) push action addressbook upsert '["alice", "alice", "liddell", "123 drink me way", "wonderland", "amsterdam"]' -p alice@active
	$(cleos) push action addressbook upsert '["bob", "bob", "is a loser", "doesnt exist", "somewhere", "someplace"]' -p bob@active
	$(cleos) get table addressbook addressbook people --lower alice --limit 1
	$(cleos) push action addressbook erase '["alice"]' -p alice@active

	$(cleos) push action addressbook upsert '["alice", "alice", "liddell", "123 drink me way", "wonderland", "amsterdam"]' -p alice@active
	$(cleos) get actions alice
